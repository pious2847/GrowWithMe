import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/model/model_service.dart';

/// Optional measurements after a health check: the offline AI gives a second
/// opinion from whatever numbers the caregiver has — the BP written in her
/// ANC card, a home thermometer reading. Every field is skippable.
///
/// SAFETY: this can only ADD caution. The danger-sign result she already saw
/// stays the instruction to follow; if the AI thinks risk is higher, we say
/// so — if it thinks risk is lower, we tell her to follow the advice anyway.
class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key, required this.rulesRiskLevel});

  /// The triage engine's verdict for this check ('ok' | 'moderate').
  final String rulesRiskLevel;

  @override
  ConsumerState<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  RiskAssessment? _result;
  String? _error;

  static const _hints = {
    'age': 'Your age in years',
    'systolic_bp': 'Top number — copy from your ANC card if recent',
    'diastolic_bp': 'Bottom number — from the same reading',
    'blood_sugar': 'Only if a nurse tested you (mmol/L)',
    'body_temp': 'Use a thermometer if you have one (°F)',
    'heart_rate': 'Beats per minute, if you can count them',
  };

  ModelService get _model => ref.read(modelServiceProvider);
  List<String> get _features => (_model.meta['features'] as List).cast<String>();
  List<String> get _labels =>
      (_model.meta['featureLabels'] as List).cast<String>();

  @override
  void initState() {
    super.initState();
    for (final f in _features) {
      _controllers[f] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _assess() {
    final ranges = _model.meta['validRanges'] as Map<String, dynamic>;
    final values = <String, double?>{};
    for (var i = 0; i < _features.length; i++) {
      final f = _features[i];
      final raw = _controllers[f]!.text.trim();
      if (raw.isEmpty) {
        values[f] = null;
        continue;
      }
      final v = double.tryParse(raw);
      final range = (ranges[f] as List).map((e) => (e as num).toDouble()).toList();
      if (v == null || v < range[0] || v > range[1]) {
        setState(() {
          _result = null;
          _error = '${_labels[i]} looks wrong — expected a number between '
              '${range[0].toStringAsFixed(0)} and ${range[1].toStringAsFixed(0)}.';
        });
        return;
      }
      values[f] = v;
    }

    final result = _model.assess(values);
    setState(() {
      _error = result == null
          ? 'Not enough measurements for a safe estimate. Enter at least your '
              'age and both blood pressure numbers, plus one more.'
          : null;
      _result = result;
    });
    if (result != null) {
      _shadowLog(values, result);
      final autoVoice = ref.read(autoVoiceProvider).value ?? false;
      final raised = result.label != 'low risk';
      if (raised || autoVoice) {
        ref.read(ttsProvider).speak(raised
            ? 'The numbers suggest extra caution. Please visit a clinic to be '
                'checked, even if you feel well.'
            : 'The numbers look okay. Still follow the advice from your check.');
      }
    }
  }

  /// Shadow-mode data flywheel: de-identified vitals + prediction + the rules
  /// verdict go to the backend so the model can later be fine-tuned on local
  /// cases (covered by her data-processing consent). Best-effort only.
  Future<void> _shadowLog(Map<String, double?> values, RiskAssessment result) async {
    try {
      await ref.read(apiClientProvider).dio.post('/models/maternal-risk/log', data: {
        'source': 'caregiver',
        'modelVersion': _model.version,
        'values': values,
        'usedInputs': result.usedInputs,
        'prediction': {'label': result.label, 'probs': result.probs},
        'rulesRiskLevel': widget.rulesRiskLevel,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add measurements (optional)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'If you know any of these numbers, the offline helper can give a '
            'second opinion. Skip anything you do not know.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _features.length; i++) ...[
            TextField(
              controller: _controllers[_features[i]],
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _labels[i],
                helperText: _hints[_features[i]],
                helperMaxLines: 2,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _assess,
            icon: const Icon(Icons.monitor_heart),
            label: const Text('Check my numbers'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.error, height: 1.4)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _SecondOpinionCard(
                result: _result!, rulesRiskLevel: widget.rulesRiskLevel),
          ],
        ],
      ),
    );
  }
}

class _SecondOpinionCard extends StatelessWidget {
  const _SecondOpinionCard({required this.result, required this.rulesRiskLevel});

  final RiskAssessment result;
  final String rulesRiskLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raised = result.label != 'low risk';
    final color = raised ? Colors.orange.shade800 : Colors.green.shade700;
    // Never-downgrade: an AI "low" must not soften a moderate rules verdict.
    final message = raised
        ? 'Your numbers suggest extra caution. Please visit a clinic to be '
            'checked, even if you feel well.'
        : rulesRiskLevel == 'moderate'
            ? 'Your numbers look okay — but your check found symptoms, so '
                'still follow the advice you were given: visit the clinic.'
            : 'Your numbers look okay. Keep your normal clinic visits.';
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(raised ? Icons.report_problem : Icons.check_circle,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      raised ? 'Extra caution advised' : 'Numbers look okay',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 8),
            Text(
              'Based on ${result.usedInputs} of ${result.totalInputs} '
              'measurements. ⚠ This helper can be wrong — it never replaces '
              'your health check result or a nurse.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

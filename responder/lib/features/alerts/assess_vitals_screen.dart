import 'package:flutter/material.dart';

import '../../core/model_service.dart';

/// Offline vitals assessment: the responder measures the patient and gets an
/// AI risk estimate with zero connectivity — the model already lives on the
/// phone. Empty fields are allowed (the model tolerates missing inputs down
/// to the manifest's minimum policy).
class AssessVitalsScreen extends StatefulWidget {
  const AssessVitalsScreen({super.key, this.patientName});

  final String? patientName;

  @override
  State<AssessVitalsScreen> createState() => _AssessVitalsScreenState();
}

class _AssessVitalsScreenState extends State<AssessVitalsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  RiskAssessment? _result;
  String? _error;

  List<String> get _features =>
      (ModelService.I.meta['features'] as List).cast<String>();
  List<String> get _labels =>
      (ModelService.I.meta['featureLabels'] as List).cast<String>();

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
    final ranges = (ModelService.I.meta['validRanges'] as Map<String, dynamic>);
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
          _error =
              '${_labels[i]} looks wrong — expected ${range[0].toStringAsFixed(0)}–${range[1].toStringAsFixed(0)}.';
        });
        return;
      }
      values[f] = v;
    }

    final result = ModelService.I.assess(values);
    setState(() {
      _error = result == null
          ? 'Not enough measurements. Enter at least age and blood pressure, '
              'plus one more (4 total) for a reliable estimate.'
          : null;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assess vitals (offline AI)')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.patientName == null
                ? 'Enter the measurements you took. Leave unknown ones empty.'
                : 'Measurements for ${widget.patientName}. Leave unknown ones empty.',
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
            label: const Text('Assess risk'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(color: theme.colorScheme.error, height: 1.4)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final RiskAssessment result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (result.label) {
      'high risk' => Colors.red.shade700,
      'mid risk' => Colors.orange.shade700,
      _ => Colors.green.shade700,
    };
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
                Icon(Icons.analytics, color: color),
                const SizedBox(width: 8),
                Text(result.label.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: color, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${(result.confidence * 100).round()}%',
                    style: theme.textTheme.titleMedium?.copyWith(color: color)),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < result.classes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                        width: 76,
                        child: Text(result.classes[i],
                            style: theme.textTheme.bodySmall)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: result.probs[i],
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(result.probs[i] * 100).round()}%',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Based on ${result.usedInputs} of ${result.totalInputs} measurements.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '⚠ AI estimate — it can be wrong. Use your clinical judgement '
              'and the danger-sign protocol; this never replaces them.',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

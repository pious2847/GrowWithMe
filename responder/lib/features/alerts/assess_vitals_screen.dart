import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/model_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';

/// Offline vitals assessment: the responder measures the patient and gets an
/// AI risk estimate with zero connectivity — the model already lives on the
/// phone. Empty fields are allowed (the model tolerates missing inputs down
/// to the manifest's minimum policy).
class AssessVitalsScreen extends StatefulWidget {
  const AssessVitalsScreen({super.key, this.patientName, this.alertId});

  final String? patientName;
  final String? alertId;

  @override
  State<AssessVitalsScreen> createState() => _AssessVitalsScreenState();
}

class _AssessVitalsScreenState extends State<AssessVitalsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  RiskAssessment? _result;
  String? _error;
  bool _loggedToCase = false;

  List<String> get _features =>
      (ModelService.I.meta['features'] as List).cast<String>();
  List<String> get _labels =>
      (ModelService.I.meta['featureLabels'] as List).cast<String>();
  Map<String, dynamic> get _ranges =>
      (ModelService.I.meta['validRanges'] as Map<String, dynamic>?) ?? {};

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

  void _clear() {
    for (final c in _controllers.values) {
      c.clear();
    }
    setState(() {
      _result = null;
      _error = null;
      _loggedToCase = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _assess() {
    FocusScope.of(context).unfocus();
    final ranges = _ranges;
    final values = <String, double?>{};
    for (var i = 0; i < _features.length; i++) {
      final f = _features[i];
      final raw = _controllers[f]!.text.trim();
      if (raw.isEmpty) {
        values[f] = null;
        continue;
      }
      final v = double.tryParse(raw);
      final range = (ranges[f] as List?)
          ?.map((e) => (e as num).toDouble())
          .toList();
      if (v == null || range == null || v < range[0] || v > range[1]) {
        setState(() {
          _result = null;
          _error = range == null
              ? '${_labels[i]} is not a number.'
              : '${_labels[i]} looks wrong — expected '
                  '${_trim(range[0])}–${_trim(range[1])}.';
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
      _loggedToCase = false;
    });
    if (result != null) _shadowLog(values, result);
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Shadow-mode data flywheel: de-identified vitals + prediction go to the
  /// backend so the model can later be fine-tuned on local cases. Best-effort
  /// only — offline or failed sends are silently dropped.
  Future<void> _shadowLog(
      Map<String, double?> values, RiskAssessment result) async {
    try {
      await Api.I.dio.post('/models/maternal-risk/log', data: {
        'source': 'responder',
        'modelVersion': ModelService.I.version,
        'values': values,
        'usedInputs': result.usedInputs,
        'prediction': {'label': result.label, 'probs': result.probs},
        if (widget.alertId != null) 'alertId': widget.alertId,
      });
      if (mounted && widget.alertId != null) {
        setState(() => _loggedToCase = true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Assess vitals'),
        actions: [
          TextButton(
            onPressed: _result == null ? null : _clear,
            child: const Text('Clear'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border: Border.all(color: AppColors.forestDeep),
                boxShadow: AppShadows.raised,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Pill(
                        label: 'OFFLINE AI',
                        icon: Icons.offline_bolt_rounded,
                        foreground: AppColors.limeInk,
                        background: AppColors.lime,
                        dense: true,
                      ),
                      const Spacer(),
                      Text(
                        'v${ModelService.I.version ?? '—'} · on this phone',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.patientName == null
                        ? 'Measure, then decide.'
                        : 'Measurements for\n${widget.patientName}.',
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 25,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter what you measured and leave the rest empty. The '
                    'model works with partial data, fully offline.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.cream.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(
              title: 'Measurements',
              subtitle: 'Tap a field and enter the reading',
            ),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _features.length; i++)
                        SizedBox(
                          width: width,
                          child: _MeasurementField(
                            controller: _controllers[_features[i]]!,
                            label: _labels[i],
                            range: (_ranges[_features[i]] as List?)
                                ?.map((e) => _trim((e as num).toDouble()))
                                .join('–'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_outlined,
                    size: 15, color: AppColors.muted),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Measurements are de-identified. Only numbers and the '
                    'estimate may be sent to improve the model — never names '
                    'or phone numbers.',
                    style: t.bodySmall?.copyWith(
                      color: AppColors.faint,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              NoticeBanner(
                icon: Icons.error_outline_rounded,
                message: _error!,
                color: const Color(0xFF9A1B08),
                background: AppColors.coralSoft,
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 18),
              _ResultCard(
                result: _result!,
                loggedToCase: _loggedToCase,
                hasCase: widget.alertId != null,
              ),
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: LimeButton(
              label: _result == null ? 'Assess risk' : 'Re-assess risk',
              icon: Icons.monitor_heart_rounded,
              onPressed: _assess,
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.range,
  });

  final TextEditingController controller;
  final String label;
  final String? range;

  @override
  Widget build(BuildContext context) {
    // "Systolic BP (mmHg)" as a floating label truncates in a two-column
    // grid; the measurement name sits in the label, the unit becomes a hint.
    var short = label.split('(').first.trim();
    if (short.toLowerCase().startsWith('body temperature')) {
      short = 'Body temp';
    }
    final unit = RegExp(r'\(([^)]*)\)').firstMatch(label)?.group(1);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
      decoration: InputDecoration(
        labelText: short,
        hintText: unit,
        labelStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        helperText: range == null
            ? null
            : 'Normal $range${unit == null ? '' : ' $unit'}',
        helperStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 9.5,
          color: AppColors.faint,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.loggedToCase,
    required this.hasCase,
  });

  final RiskAssessment result;
  final bool loggedToCase;
  final bool hasCase;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = switch (result.label) {
      'high risk' => AppColors.coral,
      'mid risk' => AppColors.amber,
      _ => AppColors.teal,
    };
    final background = switch (result.label) {
      'high risk' => AppColors.coralSoft,
      'mid risk' => AppColors.amberSoft,
      _ => AppColors.tealSoft,
    };
    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: color),
                    const SizedBox(width: 5),
                    Text(
                      'AI ESTIMATE',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (hasCase)
                Pill(
                  label: loggedToCase ? 'LOGGED TO CASE' : 'SAVED LOCALLY',
                  foreground:
                      loggedToCase ? AppColors.teal : AppColors.muted,
                  background:
                      loggedToCase ? AppColors.tealSoft : AppColors.creamDeep,
                  dense: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            result.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(result.confidence * 100).round()}% confidence · based on '
            '${result.usedInputs} of ${result.totalInputs} measurements',
            style: t.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < result.classes.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      result.classes[i].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: result.probs[i]),
                        duration: AppMotion.slow,
                        curve: AppMotion.enter,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 7,
                          backgroundColor: AppColors.creamDeep,
                          valueColor: AlwaysStoppedAnimation(
                            result.classes[i] == result.label
                                ? color
                                : AppColors.lineStrong,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${(result.probs[i] * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 17, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI estimate — it can be wrong. Use your clinical '
                    'judgement and the danger-sign protocol; this never '
                    'replaces them.',
                    style: t.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

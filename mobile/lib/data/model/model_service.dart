import '../api/api_client.dart';
import 'on_device_model.dart';

/// Result of an offline vitals assessment.
class RiskAssessment {
  const RiskAssessment({
    required this.label,
    required this.probs,
    required this.classes,
    required this.usedInputs,
    required this.totalInputs,
  });

  final String label;
  final List<double> probs;
  final List<String> classes;
  final int usedInputs;
  final int totalInputs;

  double get confidence => probs.reduce((a, b) => a > b ? a : b);
}

/// The maternal risk model (Tier 1 of OFFLINE_MODEL_PLAN.md) — thin wrapper
/// over the generic [OnDeviceModel] download/verify/load pipeline. The result
/// can only ever ADD caution on top of the danger-sign rules, never soften.
class ModelService {
  ModelService(ApiClient api) : _model = OnDeviceModel(api, 'maternal-risk');

  final OnDeviceModel _model;

  bool get ready => _model.ready;
  Map<String, dynamic> get meta => _model.meta;
  int? get version => _model.version;
  int? get sizeBytes => _model.sizeBytes;
  Future<void> ensureLatest() => _model.ensureLatest();

  /// Runs the model on partially-filled vitals. [values] keys follow
  /// meta.features (age, systolic_bp, ...); null = not measured.
  /// Returns null when the manifest's minimum-input policy is not met —
  /// evaluation showed too few inputs gives unsafe answers.
  RiskAssessment? assess(Map<String, double?> values) {
    if (!ready) return null;
    final features = (meta['features'] as List).cast<String>();
    final classes = (meta['classes'] as List).cast<String>();
    final mean = (meta['mean'] as List).map((e) => (e as num).toDouble()).toList();
    final std = (meta['std'] as List).map((e) => (e as num).toDouble()).toList();
    final minInputs = (meta['minInputs'] as num?)?.toInt() ?? 4;
    final required = ((meta['requiredFeatures'] as List?) ?? []).cast<String>();

    final present = features.where((f) => values[f] != null).length;
    if (present < minInputs) return null;
    if (required.any((f) => values[f] == null)) return null;

    final input = List<double>.filled(features.length * 2, 0);
    for (var i = 0; i < features.length; i++) {
      final v = values[features[i]];
      if (v != null) {
        input[i] = (v - mean[i]) / std[i];
        input[features.length + i] = 1;
      }
    }

    final probs = _model.run(input, classes.length);
    var best = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[best]) best = i;
    }
    return RiskAssessment(
      label: classes[best],
      probs: probs,
      classes: classes,
      usedInputs: present,
      totalInputs: features.length,
    );
  }
}

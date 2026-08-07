import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../api/api_client.dart';

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

/// Downloads and runs the on-device maternal risk model (Tier 1 of
/// OFFLINE_MODEL_PLAN.md) — same registry and file as the responder app.
///
/// Non-disruptive by design: [ensureLatest] runs in the background and fails
/// silently; the optional measurements feature stays hidden until a verified
/// model file exists on disk. Inference is fully offline, and the result can
/// only ever ADD caution on top of the danger-sign rules — never soften them.
class ModelService {
  ModelService(this._api);

  final ApiClient _api;
  static const _name = 'maternal-risk';

  Map<String, dynamic>? _manifest;
  Interpreter? _interpreter;

  bool get ready => _interpreter != null && _manifest != null;
  Map<String, dynamic> get meta =>
      (_manifest?['meta'] as Map<String, dynamic>?) ?? {};

  Future<File> _modelFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/models/$_name.tflite');
  }

  Future<File> _manifestFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/models/$_name.manifest.json');
  }

  /// Loads a previously downloaded model from disk (offline path), then — if
  /// online — checks the registry and downloads a newer version if published.
  /// Never throws; call fire-and-forget on app start.
  Future<void> ensureLatest() async {
    try {
      await _loadFromDisk();
    } catch (_) {}
    try {
      final res = await _api.dio.get('/models/$_name');
      final remote = res.data['model'] as Map<String, dynamic>;
      final localVersion = (_manifest?['version'] as num?)?.toInt() ?? -1;
      if ((remote['version'] as num).toInt() > localVersion || !ready) {
        await _download(remote);
        await _loadFromDisk();
      }
    } catch (_) {
      // Offline or registry unreachable — keep whatever we have (or nothing).
    }
  }

  Future<void> _download(Map<String, dynamic> manifest) async {
    final bytes = (await Dio().get<List<int>>(
      manifest['url'] as String,
      options: Options(responseType: ResponseType.bytes),
    ))
        .data!;
    final digest = sha256.convert(bytes).toString();
    if (digest != manifest['sha256']) {
      throw StateError('model checksum mismatch');
    }
    final file = await _modelFile();
    await file.parent.create(recursive: true);
    // Write to a temp name then rename — a half-written file is never loaded.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
    await (await _manifestFile()).writeAsString(jsonEncode(manifest));
  }

  Future<void> _loadFromDisk() async {
    final file = await _modelFile();
    final mf = await _manifestFile();
    if (!await file.exists() || !await mf.exists()) return;
    final manifest = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
    // Verify integrity every load — a corrupt file must not produce garbage.
    final digest = sha256.convert(await file.readAsBytes()).toString();
    if (digest != manifest['sha256']) {
      await file.delete();
      return;
    }
    _interpreter?.close();
    _interpreter = Interpreter.fromFile(file);
    _manifest = manifest;
  }

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

    final output = [List<double>.filled(classes.length, 0)];
    _interpreter!.run([input], output);
    final probs = output[0];
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

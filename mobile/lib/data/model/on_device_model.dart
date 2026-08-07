import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../api/api_client.dart';

/// Generic downloadable on-device TFLite model (see OFFLINE_MODEL_PLAN.md):
/// registry manifest poll → background download → sha256 verify → atomic swap
/// → offline inference. One instance per registry name.
///
/// Non-disruptive by design: [ensureLatest] fails silently; features guard on
/// [ready] and simply stay hidden until a verified model exists on disk.
class OnDeviceModel {
  OnDeviceModel(this._api, this.name);

  final ApiClient _api;
  final String name;

  Map<String, dynamic>? _manifest;
  Interpreter? _interpreter;

  bool get ready => _interpreter != null && _manifest != null;
  Map<String, dynamic> get meta =>
      (_manifest?['meta'] as Map<String, dynamic>?) ?? {};
  int? get version => (_manifest?['version'] as num?)?.toInt();
  int? get sizeBytes => (_manifest?['sizeBytes'] as num?)?.toInt();

  Future<File> _modelFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/models/$name.tflite');
  }

  Future<File> _manifestFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/models/$name.manifest.json');
  }

  /// Loads a previously downloaded model from disk (offline path), then — if
  /// online — checks the registry and downloads a newer version if published.
  /// Never throws; call fire-and-forget on app start.
  Future<void> ensureLatest() async {
    try {
      await _loadFromDisk();
    } catch (_) {}
    try {
      final res = await _api.dio.get('/models/$name');
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

  /// Runs the model on one input vector, returning [outputSize] floats.
  List<double> run(List<double> input, int outputSize) {
    final output = [List<double>.filled(outputSize, 0)];
    _interpreter!.run([input], output);
    return output[0];
  }
}

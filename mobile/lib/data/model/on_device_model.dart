import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../api/api_client.dart';

/// Generic downloadable on-device model (see OFFLINE_MODEL_PLAN.md):
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

  bool get ready => _manifest != null && (_manifest?['kind'] == 'llm' || _interpreter != null);
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
    final isLlm = manifest['kind'] == 'llm';
    final url = manifest['url'] as String;
    final bytes = (await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    ))
        .data!;
    final digest = sha256.convert(bytes).toString();
    if (digest != manifest['sha256']) {
      throw StateError('model checksum mismatch');
    }
    final file = await _modelFile();
    await file.parent.create(recursive: true);

    if (isLlm) {
      // 1. Save zip temporarily
      final tmpZip = File('${file.path}.zip');
      await tmpZip.writeAsBytes(bytes, flush: true);

      // 2. Unzip into folder models/$name/
      final folderPath = '${file.parent.path}/$name';
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final archiveFile in archive) {
        final filename = archiveFile.name;
        if (archiveFile.isFile) {
          final data = archiveFile.content as List<int>;
          final outFile = File('$folderPath/$filename');
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(data, flush: true);
        }
      }

      // 3. Clean up zip
      if (await tmpZip.exists()) {
        await tmpZip.delete();
      }
    } else {
      // TFLite: Write to a temp name then rename — a half-written file is never loaded.
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(file.path);
    }
    await (await _manifestFile()).writeAsString(jsonEncode(manifest));
  }

  Future<void> _loadFromDisk() async {
    final file = await _modelFile();
    final mf = await _manifestFile();
    if (!await mf.exists()) return;
    
    final manifest = jsonDecode(await mf.readAsString()) as Map<String, dynamic>;
    final isLlm = manifest['kind'] == 'llm';

    if (isLlm) {
      final folder = Directory('${file.parent.path}/$name');
      if (!await folder.exists()) return;
      _manifest = manifest;
    } else {
      if (!await file.exists()) return;
      final digest = sha256.convert(await file.readAsBytes()).toString();
      if (digest != manifest['sha256']) {
        await file.delete();
        return;
      }
      _interpreter?.close();
      _interpreter = Interpreter.fromFile(file);
      _manifest = manifest;
    }
  }

  /// Runs the model on one input vector, returning [outputSize] floats.
  List<double> run(List<double> input, int outputSize) {
    if (_interpreter == null) throw StateError('Interpreter not loaded');
    final output = [List<double>.filled(outputSize, 0)];
    _interpreter!.run([input], output);
    return output[0];
  }
}

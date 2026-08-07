import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny JSON disk cache: every successful fetch is saved, so when the network
/// drops (rural Northern Ghana reality) the app still shows the last known
/// alerts, case details and facilities instead of an empty screen.
class OfflineCache {
  static Future<File> _file(String key) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cache/$key.json');
  }

  static Future<void> put(String key, Object value) async {
    try {
      final file = await _file(key);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(value));
    } catch (_) {
      // Caching must never break the live path.
    }
  }

  static Future<dynamic> get(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      return jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
  }
}

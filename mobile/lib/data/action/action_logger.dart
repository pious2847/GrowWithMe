import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';

/// Privacy-first interaction logging for the on-device action model.
///
/// Only metadata ever leaves the phone: screen ids, action ids, UI targets,
/// coarse flags and durations. Free text, names, phone numbers and health
/// answers are never logged. Logging is off until the caregiver explicitly
/// opts in, and the queue is local-first so it survives offline use.
class ActionLogger {
  ActionLogger(this._api);

  final ApiClient _api;

  static const _consentKey = 'actionDataConsent';
  static const _queueKey = 'actionQueue';
  static const _sessionKey = 'actionSessionId';
  static const _maxQueued = 500;
  static const _batchSize = 50;

  Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> setConsent(bool consent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, consent);
    if (!consent) {
      await prefs.remove(_queueKey);
    }
  }

  Future<String> _sessionId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_sessionKey);
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_sessionKey, id);
    return id;
  }

  /// Record one interaction. Never throws: logging must not break care.
  Future<void> log({
    required String screen,
    required String action,
    String? target,
    Map<String, Object?> params = const {},
    bool success = true,
    int? durationMs,
  }) async {
    try {
      if (!await hasConsent()) return;
      final prefs = await SharedPreferences.getInstance();
      final sessionId = await _sessionId();

      String? country;
      String? region;
      String? language;
      final rawRegion = prefs.getString('regionSettings');
      if (rawRegion != null) {
        try {
          final map = jsonDecode(rawRegion) as Map<String, dynamic>;
          country = map['countryCode'] as String?;
          region = map['region'] as String?;
          language = map['languageCode'] as String?;
        } catch (_) {}
      }

      final event = <String, Object?>{
        'clientEventId': const Uuid().v4(),
        'sessionId': sessionId,
        'screen': screen,
        'action': action,
        'target': ?target,
        'params': {...params, 'language': ?language},
        'success': success,
        'durationMs': ?durationMs,
        'country': country,
        'region': region,
        'appVersion': '1.0.0',
        'platform': 'android',
        'consentVersion': 'v1',
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
      };

      final queue = prefs.getStringList(_queueKey) ?? <String>[];
      queue.add(jsonEncode(event));
      if (queue.length > _maxQueued) {
        queue.removeRange(0, queue.length - _maxQueued);
      }
      await prefs.setStringList(_queueKey, queue);
    } catch (_) {}
  }

  /// Upload queued events in small batches. Called opportunistically when the
  /// app is online; failures are silently retried next time.
  Future<void> flush() async {
    try {
      if (!await hasConsent()) return;
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? <String>[];
      if (queue.isEmpty) return;

      var sent = 0;
      while (sent < queue.length) {
        final end = (sent + _batchSize).clamp(0, queue.length);
        final batch = queue.sublist(sent, end);
        final events = <Map<String, dynamic>>[];
        for (final raw in batch) {
          try {
            events.add(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {}
        }
        if (events.isEmpty) {
          sent = end;
          continue;
        }
        await _api.dio.post('/actions/events', data: {'events': events});
        sent = end;
      }
      await prefs.setStringList(_queueKey, const []);
    } catch (_) {
      // Offline or rejected — keep the queue for the next attempt.
    }
  }

  /// A compact, consenting on-device summary for the settings screen.
  Future<int> queuedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_queueKey) ?? const []).length;
  }
}

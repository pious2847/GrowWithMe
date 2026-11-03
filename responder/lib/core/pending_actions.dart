import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'offline_cache.dart';

/// A status update taken while the phone had no connection.
///
/// In rural field work connectivity drops mid-case. Instead of failing the
/// action, the app records it and replays the updates in order the next time
/// the backend answers — so "Accept", "En route", "At facility" never get lost.
class PendingAction {
  const PendingAction({
    required this.alertId,
    required this.status,
    this.note,
    required this.queuedAt,
  });

  final String alertId;
  final String status;
  final String? note;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
        'alertId': alertId,
        'status': status,
        if (note != null) 'note': note,
        'queuedAt': queuedAt.toIso8601String(),
      };

  static PendingAction? fromJson(dynamic raw) {
    if (raw is! Map) return null;
    final alertId = raw['alertId'];
    final status = raw['status'];
    if (alertId is! String || status is! String) return null;
    return PendingAction(
      alertId: alertId,
      status: status,
      note: raw['note'] is String ? raw['note'] as String : null,
      queuedAt: DateTime.tryParse(raw['queuedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class PendingActions {
  PendingActions._();

  static const _key = 'pending_actions';

  /// Lets the shell show a live "N updates waiting" banner.
  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  static Future<List<PendingAction>> all() async {
    final raw = await OfflineCache.get(_key);
    if (raw is! List) return const [];
    return raw
        .map(PendingAction.fromJson)
        .whereType<PendingAction>()
        .toList(growable: false);
  }

  static Future<void> _save(List<PendingAction> actions) async {
    await OfflineCache.put(_key, actions.map((a) => a.toJson()).toList());
    count.value = actions.length;
  }

  static Future<void> add(PendingAction action) async {
    final actions = [...await all(), action];
    await _save(actions);
  }

  /// Re-reads the queue from disk so a cold start shows what is still waiting
  /// to be sent once connectivity returns.
  static Future<void> refreshCount() async {
    final actions = await all();
    count.value = actions.length;
  }

  /// Replays queued updates oldest-first. Stops keeping an action once the
  /// backend accepts it; a rejected action (e.g. case already closed) is
  /// dropped rather than blocking the whole queue forever.
  static Future<int> flush() async {
    final actions = await all();
    if (actions.isEmpty) return 0;
    final remaining = <PendingAction>[];
    var synced = 0;
    for (final action in actions) {
      try {
        await Api.I.dio.patch(
          '/alerts/${action.alertId}/status',
          data: {
            'status': action.status,
            if (action.note != null) 'note': action.note,
          },
        );
        synced += 1;
      } on DioException catch (e) {
        final code = e.response?.statusCode ?? 0;
        final refused = code >= 400 && code < 500 && code != 401;
        // A 4xx means the server refused it (closed case, lost assignment) —
        // replaying cannot help, so it is dropped. Network failures and auth
        // problems stay queued for the next attempt.
        if (!refused) remaining.add(action);
      } catch (_) {
        remaining.add(action);
      }
    }
    await _save(remaining);
    return synced;
  }

  static Future<void> clear() => _save(const []);
}

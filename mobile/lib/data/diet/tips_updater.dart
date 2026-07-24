import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/diet_guide.dart';
import '../../domain/nutrition_tips.dart';
import '../api/api_client.dart';
import '../assistant/nana_assistant.dart';
import '../db/app_database.dart';

/// Keeps the daily feeding tips fresh: AI-written each day from her real
/// situation (children's ages, pregnancy, season, diet gaps, and avoiding
/// recent repeats), the offline library when disconnected, and an automatic
/// AI upgrade when connectivity returns. Every tip is kept — the history
/// stays browsable forever.
class TipsUpdater {
  TipsUpdater(this._db, this._api, this._assistant);

  final AppDatabase _db;
  final ApiClient _api;
  final NanaAssistant _assistant;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> ensureTodayTips() async {
    try {
      final today = await _db.tipsForDay(_todayKey);
      if (today.any((t) => t.source == 'ai')) return;

      final gotAi = await _tryAiTips(replacing: today);
      if (!gotAi && today.isEmpty) {
        await _saveOfflineTips();
      }
    } catch (_) {
      // Tips must never disturb app startup.
    }
  }

  Future<bool> _tryAiTips({required List<DailyTipRow> replacing}) async {
    try {
      final recent = await (_db.select(_db.dailyTips)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.forDay)])
            ..limit(14))
          .get();
      final baseContext = await _assistant.buildContext();
      final season = currentSeason();
      final context = '$baseContext\n'
          'Season: ${seasonLabel(season)} — in the market now: ${seasonalFoodsHint(season)}\n'
          'Recent tip titles (do NOT repeat): ${recent.map((t) => t.title).toSet().join('; ')}';
      final res = await _api.dio
          .post('/assistant/daily-tips', data: {'context': context});
      final tips = (res.data['tips'] as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (tips.isEmpty) return false;

      for (final tip in tips) {
        await _db.into(_db.dailyTips).insert(DailyTipsCompanion.insert(
              id: const Uuid().v4(),
              clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
              audience: tip['audience'] as String,
              title: tip['title'] as String,
              body: tip['body'] as String,
              forDay: _todayKey,
              source: const Value('ai'),
            ));
      }
      // The AI tips replace today's offline placeholders.
      for (final old in replacing) {
        await (_db.update(_db.dailyTips)..where((t) => t.id.equals(old.id)))
            .write(DailyTipsCompanion(
          deleted: const Value(true),
          clientUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          synced: const Value(false),
        ));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveOfflineTips() async {
    final children = await (_db.select(_db.children)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final pregnancies = await (_db.select(_db.pregnancies)
          ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
        .get();

    Future<void> save(String audience, NutritionTip tip) =>
        _db.into(_db.dailyTips).insert(DailyTipsCompanion.insert(
              id: const Uuid().v4(),
              clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
              audience: audience,
              title: tip.title,
              body: tip.body,
              forDay: _todayKey,
            ));

    if (pregnancies.isNotEmpty) {
      await save('pregnancy', dailyPregnancyTip());
    }
    if (children.isNotEmpty) {
      children.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
      final months =
          DateTime.now().difference(children.first.dateOfBirth).inDays ~/ 30;
      await save('child', dailyChildTip(months));
    }
    if (pregnancies.isEmpty && children.isEmpty) {
      await save('general', dailyPregnancyTip());
    }
  }
}

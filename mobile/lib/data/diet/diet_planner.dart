import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/diet_guide.dart';
import '../api/api_client.dart';
import '../assistant/nana_assistant.dart';
import '../db/app_database.dart';

/// Plans meals. Shared by the home page (auto daily plan) and Nana's Kitchen
/// (wizard). Auto-planning reuses her last budget/pantry answers so the plan
/// waiting on the home page each morning already fits her means.
class DietPlanner {
  DietPlanner(this._db, this._api, this._assistant);

  final AppDatabase _db;
  final ApiClient _api;
  final NanaAssistant _assistant;

  Future<String> detectAudience() async {
    final pregnancies = await (_db.select(_db.pregnancies)
          ..where((t) => t.deleted.equals(false)))
        .get();
    if (pregnancies.any((p) => p.status == 'active')) return 'pregnancy';
    final delivered = pregnancies.where((p) =>
        p.status == 'delivered' &&
        p.deliveredAt != null &&
        DateTime.now().difference(p.deliveredAt!).inDays < 240);
    if (delivered.isNotEmpty) return 'lactating';
    final children = await (_db.select(_db.children)
          ..where((t) => t.deleted.equals(false)))
        .get();
    if (children.isNotEmpty) return 'child';
    return 'general';
  }

  /// Generates (AI when online, offline library otherwise), saves, returns
  /// the plan map. When [spokenText] is given (she talked or typed freely
  /// instead of the wizard), the AI extracts budget/pantry/household from her
  /// own words — both the extraction and the full text are saved.
  Future<Map<String, dynamic>> generate({
    required String budget,
    required String pantry,
    required String household,
    String? spokenText,
  }) async {
    final audience = await detectAudience();
    final season = currentSeason();
    Map<String, dynamic> plan;
    var source = 'offline';
    var savedBudget = budget;
    var savedPantry = pantry;

    try {
      final baseContext = await _assistant.buildContext();
      final situation = spokenText != null && spokenText.trim().isNotEmpty
          ? 'She said, in her own words: "$spokenText"'
          : 'Can afford extra market foods: ${budget == 'ok' ? 'yes' : 'no, very limited money'}\n'
              'Foodstuffs she has at home: ${pantry.isEmpty ? 'not specified' : pantry}\n'
              'People to feed: $household';
      final context = '$baseContext\n'
          'Season: ${seasonLabel(season)} — cheap now: ${seasonalFoodsHint(season)}\n'
          'Stage: $audience\n'
          '$situation';
      final res = await _api.dio
          .post('/assistant/diet-plan', data: {'context': context});
      plan = res.data['plan'] as Map<String, dynamic>;
      source = 'ai';
      // Keep what the AI understood from her words for future auto-plans.
      final extracted = plan['extracted'] as Map<String, dynamic>?;
      if (extracted != null) {
        if (extracted['budget'] is String) savedBudget = extracted['budget'] as String;
        if (extracted['pantry'] is String && (extracted['pantry'] as String).isNotEmpty) {
          savedPantry = extracted['pantry'] as String;
        }
      }
    } catch (_) {
      plan = offlinePlan(audience, season);
    }

    await _db.into(_db.dietPlans).insert(DietPlansCompanion.insert(
          id: const Uuid().v4(),
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          audience: audience,
          season: Value(season),
          budget: Value(savedBudget),
          pantry: Value(savedPantry),
          spokenText: Value(spokenText),
          planJson: jsonEncode(plan),
          source: Value(source),
          plannedFor: DateTime.now(),
        ));
    return plan;
  }

  /// Called on app open AND whenever connectivity returns:
  /// - no plan for today → generate one (AI first, cookbook offline)
  /// - today's plan came from the offline cookbook → try to UPGRADE it to an
  ///   AI plan now that we may be online (only replaced if the AI succeeds —
  ///   never downgraded)
  Future<void> ensureTodayPlan() async {
    try {
      final latest = await _db.latestDietPlan();
      final now = DateTime.now();
      final haveToday = latest != null &&
          latest.plannedFor.year == now.year &&
          latest.plannedFor.month == now.month &&
          latest.plannedFor.day == now.day;

      if (haveToday && latest.source == 'ai') return;

      if (haveToday && latest.source == 'offline') {
        await _tryAiUpgrade(latest);
        return;
      }

      await generate(
        budget: latest?.budget ?? 'low',
        pantry: latest?.pantry ?? '',
        household: '4',
      );
    } catch (_) {
      // Never let auto-planning disturb app startup.
    }
  }

  Future<void> _tryAiUpgrade(DietPlanRow offlineToday) async {
    final audience = await detectAudience();
    final season = currentSeason();
    final budget = offlineToday.budget ?? 'low';
    final pantry = offlineToday.pantry ?? '';
    try {
      final baseContext = await _assistant.buildContext();
      final context = '$baseContext\n'
          'Season: ${seasonLabel(season)} — cheap now: ${seasonalFoodsHint(season)}\n'
          'Stage: $audience\n'
          'Can afford extra market foods: ${budget == 'ok' ? 'yes' : 'no, very limited money'}\n'
          'Foodstuffs she has at home: ${pantry.isEmpty ? 'not specified' : pantry}\n'
          'People to feed: 4';
      final res = await _api.dio
          .post('/assistant/diet-plan', data: {'context': context});
      final plan = res.data['plan'] as Map<String, dynamic>;

      // AI succeeded — the richer plan replaces the cookbook one for today.
      await _db.into(_db.dietPlans).insert(DietPlansCompanion.insert(
            id: const Uuid().v4(),
            clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
            audience: audience,
            season: Value(season),
            budget: Value(budget),
            pantry: Value(pantry),
            planJson: jsonEncode(plan),
            source: const Value('ai'),
            plannedFor: DateTime.now(),
          ));
      await (_db.update(_db.dietPlans)
            ..where((t) => t.id.equals(offlineToday.id)))
          .write(DietPlansCompanion(
        deleted: const Value(true),
        clientUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        synced: const Value(false),
      ));
    } catch (_) {
      // Still offline — the cookbook plan stands until connectivity returns.
    }
  }
}

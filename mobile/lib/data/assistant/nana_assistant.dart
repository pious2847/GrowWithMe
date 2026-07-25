import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';

import '../../domain/nutrition_tips.dart';
import '../api/api_client.dart';
import '../db/app_database.dart';

class NanaAction {
  const NanaAction(this.name, this.params);

  final String name;
  final Map<String, dynamic> params;
}

class NanaReply {
  const NanaReply(this.say, {this.action, this.fromLlm = false});

  final String say;
  final NanaAction? action;
  final bool fromLlm;
}

/// Nana's brain-glue. Builds the caregiver's context from the local database,
/// asks the backend LLM when online, and falls back to a local intent parser
/// offline — so Nana always answers, connectivity or not.
class NanaAssistant {
  NanaAssistant(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  Future<NanaReply> send(
      String text, List<Map<String, String>> history) async {
    final context = await buildContext();
    // Two attempts: a failure re-probes the backend routes (USB bridge may
    // have just died — the Wi-Fi route can take over mid-conversation).
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _api.dio.post('/assistant/chat', data: {
          'messages': [...history, {'role': 'user', 'content': text}],
          'context': context,
        });
        final reply = res.data['reply'] as Map<String, dynamic>;
        final actionJson = reply['action'] as Map<String, dynamic>?;
        return NanaReply(
          reply['say'] as String? ?? '',
          action: actionJson == null
              ? null
              : NanaAction(actionJson['name'] as String? ?? '',
                  (actionJson['params'] as Map<String, dynamic>?) ?? {}),
          fromLlm: true,
        );
      } catch (_) {
        _api.invalidateBaseUrl();
      }
    }
    return localIntent(text);
  }

  /// Offline fallback: recognizes the core requests without any AI.
  Future<NanaReply> localIntent(String text) async {
    final t = text.toLowerCase();

    const symptomWords = [
      'sick', 'fever', 'ill', 'vomit', 'bleed', 'convuls', 'fit',
      'diarrh', 'cough', 'pain', 'weak', 'not moving', 'unwell', 'hot body',
    ];
    if (symptomWords.any(t.contains)) {
      return const NanaReply(
        'I hear you, my daughter. Let us check this properly and safely right now.',
        action: NanaAction('start_health_check', {}),
      );
    }
    if (t.contains('child') && (t.contains('add') || t.contains('new') || t.contains('register'))) {
      return const NanaReply(
        'Let us add your child together. I will open the form for you.',
        action: NanaAction('open_add_child', {}),
      );
    }
    if (t.contains('pregnan')) {
      return const NanaReply(
        'Wonderful news. Let us start tracking your pregnancy.',
        action: NanaAction('open_add_pregnancy', {}),
      );
    }
    if (t.contains('today') || t.contains('visit') || t.contains('remind') || t.contains('calendar')) {
      return NanaReply(await buildBriefing());
    }
    if (t.contains('tip') || t.contains('food') || t.contains('feed') || t.contains('eat')) {
      return NanaReply(await _tipText());
    }
    return const NanaReply(
      'I am Nana, your care helper. You can ask me to add a child, track a '
      'pregnancy, tell you today\'s visits, share a feeding tip, or check '
      'symptoms when someone is unwell.',
    );
  }

  /// Check-in specific context: gestational week + her past check-in history
  /// with the exact questions she answered YES to — this is what lets the AI
  /// genuinely follow up ("last time your feet were swollen — and now?")
  /// instead of guessing.
  Future<String> buildCheckinContext(PregnancyRow pregnancy) async {
    final now = DateTime.now();
    final conception =
        pregnancy.expectedDueDate.subtract(const Duration(days: 280));
    final week = (now.difference(conception).inDays / 7).floor().clamp(1, 42);

    final b = StringBuffer()
      ..writeln('Gestational week: $week of 40 '
          '(due ${DateFormat('yyyy-MM-dd').format(pregnancy.expectedDueDate)})');

    final past = await (_db.select(_db.assessments)
          ..where((t) =>
              t.deleted.equals(false) &
              t.pregnancyId.equals(pregnancy.id))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(5))
        .get();
    if (past.isEmpty) {
      b.writeln('Past check-ins: none yet — this is her first.');
    } else {
      b.writeln('Past check-ins (newest first):');
      for (final a in past) {
        final yes = <String>[];
        try {
          for (final ans in jsonDecode(a.answersJson) as List) {
            if (ans is Map && ans['answer'] == true) {
              yes.add(ans['question'] as String? ?? '');
            }
          }
        } catch (_) {}
        b.writeln('- ${DateFormat('yyyy-MM-dd').format(a.completedAt)}: '
            'risk ${a.riskLevel}'
            '${yes.isEmpty ? ', no symptoms reported' : ', answered YES to: ${yes.join('; ')}'}');
      }
    }

    b.write(await buildContext());
    return b.toString();
  }

  /// The compact data summary sent to the LLM — built entirely from the
  /// local database, so nothing extra is stored server-side.
  Future<String> buildContext() async {
    final now = DateTime.now();
    final children = await (_db.select(_db.children)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final pregnancies = await (_db.select(_db.pregnancies)
          ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
        .get();
    final upcoming = await (_db.select(_db.reminders)
          ..where((t) =>
              t.deleted.equals(false) & t.status.isIn(['upcoming', 'snoozed']))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
          ..limit(5))
        .get();

    final b = StringBuffer('Today: ${DateFormat('yyyy-MM-dd (EEEE)').format(now)}\n');
    b.writeln('Children:');
    if (children.isEmpty) b.writeln('- none registered yet');
    for (final c in children) {
      final months = now.difference(c.dateOfBirth).inDays ~/ 30;
      b.writeln('- ${c.name}, ${c.sex ?? 'sex unknown'}, $months months old');
    }
    if (pregnancies.isNotEmpty) {
      for (final p in pregnancies) {
        b.writeln(
            'Active pregnancy, due ${DateFormat('yyyy-MM-dd').format(p.expectedDueDate)}');
      }
    }
    b.writeln('Next visits:');
    if (upcoming.isEmpty) b.writeln('- none scheduled');
    for (final r in upcoming) {
      b.writeln('- ${DateFormat('yyyy-MM-dd').format(r.dueDate)}: ${r.title}');
    }

    // Health status — lets Nana summarize trends and advise like a companion.
    for (final p in pregnancies) {
      if (p.lastRiskLevel != null) {
        b.writeln(
            'Last pregnancy check-in: ${p.lastRiskLevel}${p.lastCheckinAt != null ? ' on ${DateFormat('yyyy-MM-dd').format(p.lastCheckinAt!)}' : ''}');
      }
    }
    final dietLogs = await (_db.select(_db.dietLogs)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.day)])
          ..limit(7))
        .get();
    if (dietLogs.isNotEmpty) {
      b.writeln(
          'Diet diversity last days (0-8 food groups, 5+ is good): ${dietLogs.reversed.map((l) => '${l.day.substring(5)}=${l.score}').join(', ')}');
      final latestLog = dietLogs.first;
      if (latestLog.eatenMealsJson != null) {
        b.writeln('Meals she prepared most recently: ${latestLog.eatenMealsJson}');
      }
    }
    final weights = await (_db.select(_db.growthRecords)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(3))
        .get();
    for (final w in weights) {
      b.writeln(
          'Child weight: ${w.weightKg}kg on ${DateFormat('yyyy-MM-dd').format(w.measuredAt)}');
    }
    return b.toString();
  }

  /// Spoken daily briefing: visits due soon + today's feeding tip.
  Future<String> buildBriefing() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final soon = await (_db.select(_db.reminders)
          ..where((t) =>
              t.deleted.equals(false) & t.status.isIn(['upcoming', 'snoozed']))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
          ..limit(10))
        .get();
    final dueSoon = soon
        .where((r) => !DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day)
            .isAfter(today.add(const Duration(days: 7))))
        .toList();

    final b = StringBuffer();
    if (dueSoon.isEmpty) {
      b.write('You have no clinic visits due this week. Well done, you are on track. ');
    } else {
      b.write('You have ${dueSoon.length} visit${dueSoon.length == 1 ? '' : 's'} coming up. ');
      for (final r in dueSoon.take(3)) {
        b.write('${DateFormat('EEEE d MMMM').format(r.dueDate)}: ${r.title}. ');
      }
    }
    b.write(await _tipText());
    return b.toString();
  }

  Future<String> _tipText() async {
    final children = await (_db.select(_db.children)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final pregnancies = await (_db.select(_db.pregnancies)
          ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
        .get();
    if (pregnancies.isNotEmpty) {
      final t = dailyPregnancyTip();
      return 'Today\'s tip for you: ${t.title}. ${t.body}';
    }
    if (children.isNotEmpty) {
      children.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
      final months =
          DateTime.now().difference(children.first.dateOfBirth).inDays ~/ 30;
      final t = dailyChildTip(months);
      return 'Today\'s feeding tip: ${t.title}. ${t.body}';
    }
    return 'Add a child or pregnancy and I will give you a feeding tip every day.';
  }
}

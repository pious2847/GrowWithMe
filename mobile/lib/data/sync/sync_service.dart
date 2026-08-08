import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../api/api_client.dart';
import '../db/app_database.dart';

String? _iso(DateTime? d) => d?.toUtc().toIso8601String();

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

/// Implements the client side of POST /api/v1/sync:
/// push all dirty (synced=false) rows, apply the server's pull (records
/// changed since the last checkpoint, including tombstones, plus alerts),
/// then advance the checkpoint to the returned serverTime.
class SyncService {
  SyncService(this._db, this._api);

  final AppDatabase _db;
  final ApiClient _api;

  Future<void> syncNow() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPulledAt = prefs.getInt(kLastPulledAtKey) ?? 0;

    final dirtyChildren = await _db.dirtyChildren();
    final dirtyPregnancies = await _db.dirtyPregnancies();
    final dirtyAssessments = await _db.dirtyAssessments();
    final dirtyReminders = await _db.dirtyReminders();
    final dirtyGrowthRecords = await _db.dirtyGrowthRecords();
    final dirtyChatMessages = await _db.dirtyChatMessages();
    final dirtyDietPlans = await _db.dirtyDietPlans();
    final dirtyDietLogs = await _db.dirtyDietLogs();
    final dirtyDailyTips = await _db.dirtyDailyTips();

    final res = await _api.dio.post('/sync', data: {
      'lastPulledAt': lastPulledAt,
      'push': {
        'children': dirtyChildren.map(_childToJson).toList(),
        'pregnancies': dirtyPregnancies.map(_pregnancyToJson).toList(),
        'assessments': dirtyAssessments.map(_assessmentToJson).toList(),
        'reminders': dirtyReminders.map(_reminderToJson).toList(),
        'growthRecords': dirtyGrowthRecords.map(_growthToJson).toList(),
        'chatMessages': dirtyChatMessages.map(_chatToJson).toList(),
        'dietPlans': dirtyDietPlans.map(_dietPlanToJson).toList(),
        'dietLogs': dirtyDietLogs.map(_dietLogToJson).toList(),
        'dailyTips': dirtyDailyTips.map(_dailyTipToJson).toList(),
      },
    });

    final data = res.data as Map<String, dynamic>;
    final pull = data['pull'] as Map<String, dynamic>;

    await _db.transaction(() async {
      // Everything we pushed is now on the server.
      await _db.markSynced(_db.children, dirtyChildren.map((r) => r.id).toList());
      await _db.markSynced(_db.pregnancies, dirtyPregnancies.map((r) => r.id).toList());
      await _db.markSynced(_db.assessments, dirtyAssessments.map((r) => r.id).toList());
      await _db.markSynced(_db.reminders, dirtyReminders.map((r) => r.id).toList());
      await _db.markSynced(
          _db.growthRecords, dirtyGrowthRecords.map((r) => r.id).toList());
      await _db.markSynced(
          _db.chatMessages, dirtyChatMessages.map((r) => r.id).toList());
      await _db.markSynced(
          _db.dietPlans, dirtyDietPlans.map((r) => r.id).toList());
      await _db.markSynced(
          _db.dietLogs, dirtyDietLogs.map((r) => r.id).toList());
      await _db.markSynced(
          _db.dailyTips, dirtyDailyTips.map((r) => r.id).toList());

      // One malformed document must never take down the whole pull (it used
      // to roll back the entire transaction, leaving a fresh install empty
      // forever) — apply per-doc, log and skip failures.
      await _applyAll('children', pull['children'],
          (d) => _db.into(_db.children).insertOnConflictUpdate(_childFromJson(d)));
      await _applyAll('pregnancies', pull['pregnancies'],
          (d) => _db.into(_db.pregnancies).insertOnConflictUpdate(_pregnancyFromJson(d)));
      await _applyAll('assessments', pull['assessments'],
          (d) => _db.into(_db.assessments).insertOnConflictUpdate(_assessmentFromJson(d)));
      await _applyAll('reminders', pull['reminders'],
          (d) => _db.into(_db.reminders).insertOnConflictUpdate(_reminderFromJson(d)));
      await _applyAll('growthRecords', pull['growthRecords'],
          (d) => _db.into(_db.growthRecords).insertOnConflictUpdate(_growthFromJson(d)));
      await _applyAll('chatMessages', pull['chatMessages'],
          (d) => _db.into(_db.chatMessages).insertOnConflictUpdate(_chatFromJson(d)));
      await _applyAll('dietPlans', pull['dietPlans'],
          (d) => _db.into(_db.dietPlans).insertOnConflictUpdate(_dietPlanFromJson(d)));
      await _applyAll('dietLogs', pull['dietLogs'],
          (d) => _db.into(_db.dietLogs).insertOnConflictUpdate(_dietLogFromJson(d)));
      await _applyAll('dailyTips', pull['dailyTips'],
          (d) => _db.into(_db.dailyTips).insertOnConflictUpdate(_dailyTipFromJson(d)));
      await _applyAll('alerts', pull['alerts'],
          (d) => _db.into(_db.alertsCache).insertOnConflictUpdate(_alertFromJson(d)));
    });

    await prefs.setInt(kLastPulledAtKey, data['serverTime'] as int);
  }

  /// Applies one pulled collection doc-by-doc; a failing document is logged
  /// (id + error) and skipped instead of aborting the sync.
  Future<void> _applyAll(
      String key, dynamic docs, Future<void> Function(Map<String, dynamic>) apply) async {
    final list = (docs as List? ?? []);
    var failed = 0;
    for (final doc in list) {
      try {
        await apply((doc as Map).cast<String, dynamic>());
      } catch (e) {
        failed++;
        if (failed <= 3) {
          debugPrint('[sync] $key doc ${doc is Map ? doc['_id'] : '?'} failed: $e');
        }
      }
    }
    if (failed > 0) {
      debugPrint('[sync] $key: applied ${list.length - failed}/${list.length}, $failed skipped');
    }
  }

  // ---- Row -> backend JSON ----

  Map<String, dynamic> _syncFields(dynamic r) => {
        '_id': r.id,
        'clientUpdatedAt': r.clientUpdatedAt,
        'deleted': r.deleted,
      };

  Map<String, dynamic> _childToJson(ChildRow r) => {
        ..._syncFields(r),
        'name': r.name,
        'sex': r.sex,
        'dateOfBirth': _iso(r.dateOfBirth),
        'photoUrl': r.photoUrl,
        'birthWeightKg': r.birthWeightKg,
        'notes': r.notes,
      };

  Map<String, dynamic> _pregnancyToJson(PregnancyRow r) => {
        ..._syncFields(r),
        'lastMenstrualPeriod': _iso(r.lastMenstrualPeriod),
        'expectedDueDate': _iso(r.expectedDueDate),
        'status': r.status,
        'deliveredAt': _iso(r.deliveredAt),
        'notes': r.notes,
        'hospitalName': r.hospitalName,
        'hospitalPhone': r.hospitalPhone,
        'lastCheckinAt': _iso(r.lastCheckinAt),
        'lastRiskLevel': r.lastRiskLevel,
      };

  Map<String, dynamic> _chatToJson(ChatMessageRow r) => {
        ..._syncFields(r),
        'role': r.role,
        'content': r.content,
        'sentAt': _iso(r.sentAt),
      };

  Map<String, dynamic> _dietPlanToJson(DietPlanRow r) => {
        ..._syncFields(r),
        'audience': r.audience,
        'season': r.season,
        'budget': r.budget,
        'pantry': r.pantry,
        'spokenText': r.spokenText,
        'planJson': r.planJson,
        'source': r.source,
        'plannedFor': _iso(r.plannedFor),
      };

  Map<String, dynamic> _dailyTipToJson(DailyTipRow r) => {
        ..._syncFields(r),
        'audience': r.audience,
        'title': r.title,
        'body': r.body,
        'forDay': r.forDay,
        'source': r.source,
      };

  DailyTipsCompanion _dailyTipFromJson(Map<String, dynamic> d) =>
      DailyTipsCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        audience: Value(d['audience'] as String? ?? 'general'),
        title: Value(d['title'] as String? ?? ''),
        body: Value(d['body'] as String? ?? ''),
        forDay: Value(d['forDay'] as String? ?? ''),
        source: Value(d['source'] as String? ?? 'offline'),
      );

  Map<String, dynamic> _dietLogToJson(DietLogRow r) => {
        ..._syncFields(r),
        'day': r.day,
        'groupsJson': r.groupsJson,
        'score': r.score,
        'eatenMealsJson': r.eatenMealsJson,
      };

  Map<String, dynamic> _assessmentToJson(AssessmentRow r) => {
        ..._syncFields(r),
        'subjectType': r.subjectType,
        'child': r.childId,
        'pregnancy': r.pregnancyId,
        'answers': jsonDecode(r.answersJson),
        'dangerSigns': jsonDecode(r.dangerSignsJson),
        'riskLevel': r.riskLevel,
        'guidance': r.guidance,
        if (r.lng != null && r.lat != null)
          'location': {
            'type': 'Point',
            'coordinates': [r.lng, r.lat],
          },
        'startedAt': _iso(r.startedAt),
        'completedAt': _iso(r.completedAt),
      };

  Map<String, dynamic> _reminderToJson(ReminderRow r) => {
        ..._syncFields(r),
        'child': r.childId,
        'pregnancy': r.pregnancyId,
        'type': r.type,
        'title': r.title,
        'description': r.description,
        'dueDate': _iso(r.dueDate),
        'status': r.status,
        'snoozedUntil': _iso(r.snoozedUntil),
        'completedAt': _iso(r.completedAt),
      };

  Map<String, dynamic> _growthToJson(GrowthRecordRow r) => {
        ..._syncFields(r),
        'child': r.childId,
        'weightKg': r.weightKg,
        'measuredAt': _iso(r.measuredAt),
      };

  // ---- Backend JSON -> companions (synced=true: they came from the server) ----

  GrowthRecordsCompanion _growthFromJson(Map<String, dynamic> d) =>
      GrowthRecordsCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        childId: Value(d['child'] as String? ?? ''),
        weightKg: Value((d['weightKg'] as num).toDouble()),
        measuredAt: Value(_date(d['measuredAt']) ?? DateTime.now()),
      );

  ChildrenCompanion _childFromJson(Map<String, dynamic> d) => ChildrenCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        name: Value(d['name'] as String? ?? ''),
        sex: Value(d['sex'] as String?),
        dateOfBirth: Value(_date(d['dateOfBirth']) ?? DateTime.now()),
        photoUrl: Value(d['photoUrl'] as String?),
        birthWeightKg: Value((d['birthWeightKg'] as num?)?.toDouble()),
        notes: Value(d['notes'] as String?),
      );

  PregnanciesCompanion _pregnancyFromJson(Map<String, dynamic> d) =>
      PregnanciesCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        lastMenstrualPeriod: Value(_date(d['lastMenstrualPeriod'])),
        expectedDueDate: Value(_date(d['expectedDueDate']) ?? DateTime.now()),
        status: Value(d['status'] as String? ?? 'active'),
        deliveredAt: Value(_date(d['deliveredAt'])),
        notes: Value(d['notes'] as String?),
        hospitalName: Value(d['hospitalName'] as String?),
        hospitalPhone: Value(d['hospitalPhone'] as String?),
        lastCheckinAt: Value(_date(d['lastCheckinAt'])),
        lastRiskLevel: Value(d['lastRiskLevel'] as String?),
      );

  ChatMessagesCompanion _chatFromJson(Map<String, dynamic> d) =>
      ChatMessagesCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        role: Value(d['role'] as String),
        content: Value(d['content'] as String),
        sentAt: Value(_date(d['sentAt']) ?? DateTime.now()),
      );

  DietPlansCompanion _dietPlanFromJson(Map<String, dynamic> d) =>
      DietPlansCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        audience: Value(d['audience'] as String? ?? 'general'),
        season: Value(d['season'] as String?),
        budget: Value(d['budget'] as String?),
        pantry: Value(d['pantry'] as String?),
        spokenText: Value(d['spokenText'] as String?),
        planJson: Value(d['planJson'] as String? ?? '{}'),
        source: Value(d['source'] as String? ?? 'offline'),
        plannedFor: Value(_date(d['plannedFor']) ?? DateTime.now()),
      );

  DietLogsCompanion _dietLogFromJson(Map<String, dynamic> d) =>
      DietLogsCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        day: Value(d['day'] as String),
        groupsJson: Value(d['groupsJson'] as String? ?? '[]'),
        score: Value((d['score'] as num?)?.toInt() ?? 0),
        eatenMealsJson: Value(d['eatenMealsJson'] as String?),
      );

  AssessmentsCompanion _assessmentFromJson(Map<String, dynamic> d) {
    final coords = (d['location']?['coordinates'] as List?);
    return AssessmentsCompanion(
      id: Value(d['_id'] as String),
      clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
      deleted: Value(d['deleted'] as bool? ?? false),
      synced: const Value(true),
      subjectType: Value(d['subjectType'] as String),
      childId: Value(d['child'] as String?),
      pregnancyId: Value(d['pregnancy'] as String?),
      answersJson: Value(jsonEncode(d['answers'] ?? [])),
      dangerSignsJson: Value(jsonEncode(d['dangerSigns'] ?? [])),
      riskLevel: Value(d['riskLevel'] as String),
      guidance: Value(d['guidance'] as String?),
      lng: Value(coords != null ? (coords[0] as num).toDouble() : null),
      lat: Value(coords != null ? (coords[1] as num).toDouble() : null),
      startedAt: Value(_date(d['startedAt'])),
      completedAt: Value(_date(d['completedAt']) ?? DateTime.now()),
    );
  }

  RemindersCompanion _reminderFromJson(Map<String, dynamic> d) =>
      RemindersCompanion(
        id: Value(d['_id'] as String),
        clientUpdatedAt: Value((d['clientUpdatedAt'] as num).toInt()),
        deleted: Value(d['deleted'] as bool? ?? false),
        synced: const Value(true),
        childId: Value(d['child'] as String?),
        pregnancyId: Value(d['pregnancy'] as String?),
        type: Value(d['type'] as String),
        title: Value(d['title'] as String),
        description: Value(d['description'] as String?),
        dueDate: Value(_date(d['dueDate']) ?? DateTime.now()),
        status: Value(d['status'] as String? ?? 'upcoming'),
        snoozedUntil: Value(_date(d['snoozedUntil'])),
        completedAt: Value(_date(d['completedAt'])),
      );

  AlertsCacheCompanion _alertFromJson(Map<String, dynamic> d) =>
      AlertsCacheCompanion(
        id: Value(d['_id'] as String),
        status: Value(d['status'] as String),
        summary: Value(d['summary'] as String? ?? ''),
        assessmentId: Value(d['assessment'] as String?),
        volunteerName: Value(d['volunteer']?['name'] as String?),
        volunteerPhone: Value(d['volunteer']?['phone'] as String?),
        facilityName: Value(d['facility']?['name'] as String?),
        facilityPhone: Value(d['facility']?['phone'] as String?),
        createdAt: Value(_date(d['createdAt'])),
      );
}

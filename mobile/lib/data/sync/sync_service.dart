import 'dart:convert';

import 'package:drift/drift.dart';
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

    final res = await _api.dio.post('/sync', data: {
      'lastPulledAt': lastPulledAt,
      'push': {
        'children': dirtyChildren.map(_childToJson).toList(),
        'pregnancies': dirtyPregnancies.map(_pregnancyToJson).toList(),
        'assessments': dirtyAssessments.map(_assessmentToJson).toList(),
        'reminders': dirtyReminders.map(_reminderToJson).toList(),
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

      for (final doc in (pull['children'] as List? ?? [])) {
        await _db.into(_db.children).insertOnConflictUpdate(_childFromJson(doc));
      }
      for (final doc in (pull['pregnancies'] as List? ?? [])) {
        await _db.into(_db.pregnancies).insertOnConflictUpdate(_pregnancyFromJson(doc));
      }
      for (final doc in (pull['assessments'] as List? ?? [])) {
        await _db.into(_db.assessments).insertOnConflictUpdate(_assessmentFromJson(doc));
      }
      for (final doc in (pull['reminders'] as List? ?? [])) {
        await _db.into(_db.reminders).insertOnConflictUpdate(_reminderFromJson(doc));
      }
      for (final doc in (pull['alerts'] as List? ?? [])) {
        await _db.into(_db.alertsCache).insertOnConflictUpdate(_alertFromJson(doc));
      }
    });

    await prefs.setInt(kLastPulledAtKey, data['serverTime'] as int);
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

  // ---- Backend JSON -> companions (synced=true: they came from the server) ----

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

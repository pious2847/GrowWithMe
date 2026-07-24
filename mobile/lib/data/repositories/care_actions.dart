import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/care_plan.dart';
import '../db/app_database.dart';

const _uuid = Uuid();

/// The write-side actions of the app, shared by the UI screens and the Nana
/// assistant so "add a child for me" does exactly what the Add Child screen
/// does: create locally (offline-first) with the full care calendar.
class CareActions {
  CareActions(this._db);

  final AppDatabase _db;

  Future<String> addChild({
    required String name,
    String? sex,
    required DateTime dateOfBirth,
  }) async {
    final childId = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.children).insert(ChildrenCompanion.insert(
            id: childId,
            clientUpdatedAt: now.millisecondsSinceEpoch,
            name: name,
            sex: Value(sex),
            dateOfBirth: dateOfBirth,
          ));
      for (final reminder in generateChildCarePlan(childId, dateOfBirth)) {
        await _db.into(_db.reminders).insert(reminder);
      }
    });
    return childId;
  }

  Future<String> addPregnancy({required DateTime expectedDueDate}) async {
    final pregnancyId = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.pregnancies).insert(PregnanciesCompanion.insert(
            id: pregnancyId,
            clientUpdatedAt: now.millisecondsSinceEpoch,
            expectedDueDate: expectedDueDate,
          ));
      for (final r in generatePregnancyCarePlan(pregnancyId, expectedDueDate)) {
        await _db.into(_db.reminders).insert(r);
      }
    });
    return pregnancyId;
  }

  Future<ChildRow?> findChildByName(String name) async {
    final children = await (_db.select(_db.children)
          ..where((t) => t.deleted.equals(false)))
        .get();
    final query = name.trim().toLowerCase();
    for (final c in children) {
      if (c.name.toLowerCase() == query) return c;
    }
    for (final c in children) {
      if (c.name.toLowerCase().contains(query)) return c;
    }
    return null;
  }

  Future<void> logWeight({required String childId, required double weightKg}) {
    return _db.into(_db.growthRecords).insert(GrowthRecordsCompanion.insert(
          id: _uuid.v4(),
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          childId: childId,
          weightKg: weightKg,
          measuredAt: DateTime.now(),
        ));
  }

  /// A personal reminder on any date & time — created from the calendar or by
  /// asking Nana. Fires a phone notification at the chosen moment and rides
  /// the same sync + SMS pipeline as every other reminder.
  Future<String> addCustomReminder({
    required String title,
    required DateTime when,
    String? note,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.reminders).insert(RemindersCompanion.insert(
          id: id,
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          type: 'custom',
          title: title,
          description: Value(note),
          dueDate: when,
        ));
    return id;
  }
}

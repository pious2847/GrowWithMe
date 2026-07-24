import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Columns shared by every local-first table, mirroring the backend sync
/// protocol: client-generated UUID id, device timestamp for last-write-wins,
/// soft-delete tombstone, and a dirty flag (synced=false → needs push).
mixin SyncColumns on Table {
  TextColumn get id => text()();
  IntColumn get clientUpdatedAt => integer()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChildRow')
class Children extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get sex => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime()();
  TextColumn get photoUrl => text().nullable()();
  RealColumn get birthWeightKg => real().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('PregnancyRow')
class Pregnancies extends Table with SyncColumns {
  DateTimeColumn get lastMenstrualPeriod => dateTime().nullable()();
  DateTimeColumn get expectedDueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

@DataClassName('AssessmentRow')
class Assessments extends Table with SyncColumns {
  TextColumn get subjectType => text()();
  TextColumn get childId => text().nullable()();
  TextColumn get pregnancyId => text().nullable()();
  TextColumn get answersJson => text().withDefault(const Constant('[]'))();
  TextColumn get dangerSignsJson => text().withDefault(const Constant('[]'))();
  TextColumn get riskLevel => text()();
  TextColumn get guidance => text().nullable()();
  RealColumn get lng => real().nullable()();
  RealColumn get lat => real().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime()();
}

@DataClassName('ReminderRow')
class Reminders extends Table with SyncColumns {
  TextColumn get childId => text().nullable()();
  TextColumn get pregnancyId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('upcoming'))();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// Weights recorded at growth-monitoring visits, plotted against WHO
/// weight-for-age curves for offline malnutrition screening.
@DataClassName('GrowthRecordRow')
class GrowthRecords extends Table with SyncColumns {
  TextColumn get childId => text()();
  RealColumn get weightKg => real()();
  DateTimeColumn get measuredAt => dateTime()();
}

/// Server-authored referral alerts, cached read-only for offline viewing.
@DataClassName('AlertRow')
class AlertsCache extends Table {
  TextColumn get id => text()();
  TextColumn get status => text()();
  TextColumn get summary => text()();
  TextColumn get assessmentId => text().nullable()();
  TextColumn get volunteerName => text().nullable()();
  TextColumn get volunteerPhone => text().nullable()();
  TextColumn get facilityName => text().nullable()();
  TextColumn get facilityPhone => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [Children, Pregnancies, Assessments, Reminders, GrowthRecords, AlertsCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'growwithme'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(growthRecords);
          }
        },
      );

  // ---- Watch queries for the UI ----

  Stream<List<ChildRow>> watchChildren() => (select(children)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
      .watch();

  Stream<List<ReminderRow>> watchUpcomingReminders() => (select(reminders)
        ..where((t) => t.deleted.equals(false) & t.status.isIn(['upcoming', 'snoozed']))
        ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
      .watch();

  Stream<List<ReminderRow>> watchAllReminders() => (select(reminders)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
      .watch();

  Stream<List<PregnancyRow>> watchPregnancies() => (select(pregnancies)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.expectedDueDate)]))
      .watch();

  Stream<List<AlertRow>> watchAlerts() => (select(alertsCache)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Stream<List<AssessmentRow>> watchAssessments() => (select(assessments)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
      .watch();

  // ---- Dirty rows for sync push ----

  Future<List<ChildRow>> dirtyChildren() =>
      (select(children)..where((t) => t.synced.equals(false))).get();
  Future<List<PregnancyRow>> dirtyPregnancies() =>
      (select(pregnancies)..where((t) => t.synced.equals(false))).get();
  Future<List<AssessmentRow>> dirtyAssessments() =>
      (select(assessments)..where((t) => t.synced.equals(false))).get();
  Future<List<ReminderRow>> dirtyReminders() =>
      (select(reminders)..where((t) => t.synced.equals(false))).get();
  Future<List<GrowthRecordRow>> dirtyGrowthRecords() =>
      (select(growthRecords)..where((t) => t.synced.equals(false))).get();

  Stream<List<GrowthRecordRow>> watchGrowthRecords(String childId) =>
      (select(growthRecords)
            ..where((t) => t.deleted.equals(false) & t.childId.equals(childId))
            ..orderBy([(t) => OrderingTerm.asc(t.measuredAt)]))
          .watch();

  Future<void> markSynced(TableInfo table, List<String> ids) async {
    if (ids.isEmpty) return;
    await customUpdate(
      'UPDATE ${table.actualTableName} SET synced = 1 WHERE id IN (${List.filled(ids.length, '?').join(',')})',
      variables: [for (final id in ids) Variable.withString(id)],
      updates: {table},
    );
  }
}

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
  // Where she does her checks/scans — receives the PDF report on high risk
  TextColumn get hospitalName => text().nullable()();
  TextColumn get hospitalPhone => text().nullable()();
  DateTimeColumn get lastCheckinAt => dateTime().nullable()();
  TextColumn get lastRiskLevel => text().nullable()();
}

/// Nana conversation history — persisted so she remembers, and synced so the
/// data can help the patient's care team when needed.
@DataClassName('ChatMessageRow')
class ChatMessages extends Table with SyncColumns {
  TextColumn get role => text()(); // user | assistant
  TextColumn get content => text()();
  DateTimeColumn get sentAt => dateTime()();
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

/// Saved one-day meal plans from Nana's Kitchen (AI or offline library).
@DataClassName('DietPlanRow')
class DietPlans extends Table with SyncColumns {
  TextColumn get audience => text()(); // pregnancy | lactating | child | general
  TextColumn get season => text().nullable()();
  TextColumn get budget => text().nullable()(); // low | ok
  TextColumn get pantry => text().nullable()();
  // Her full spoken/typed words when she talked to Nana instead of the wizard
  TextColumn get spokenText => text().nullable()();
  TextColumn get planJson => text()();
  TextColumn get source => text().withDefault(const Constant('offline'))();
  DateTimeColumn get plannedFor => dateTime()();
}

/// Daily Plate tracker: food groups eaten each day + diversity score, and
/// which of Nana's recommended meals she actually prepared ("I made this").
@DataClassName('DietLogRow')
class DietLogs extends Table with SyncColumns {
  TextColumn get day => text()(); // YYYY-MM-DD
  TextColumn get groupsJson => text()(); // JSON array of group indexes
  IntColumn get score => integer()();
  TextColumn get eatenMealsJson => text().nullable()(); // JSON array of meal labels
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

@DriftDatabase(tables: [
  Children,
  Pregnancies,
  Assessments,
  Reminders,
  GrowthRecords,
  ChatMessages,
  DietPlans,
  DietLogs,
  AlertsCache
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'growwithme'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(growthRecords);
          }
          if (from < 3) {
            await m.createTable(chatMessages);
            await m.addColumn(pregnancies, pregnancies.hospitalName);
            await m.addColumn(pregnancies, pregnancies.hospitalPhone);
            await m.addColumn(pregnancies, pregnancies.lastCheckinAt);
            await m.addColumn(pregnancies, pregnancies.lastRiskLevel);
          }
          if (from < 4) {
            await m.createTable(dietPlans);
            await m.createTable(dietLogs);
          }
          if (from < 5) {
            await m.addColumn(dietPlans, dietPlans.spokenText);
          }
          if (from < 6) {
            await m.addColumn(dietLogs, dietLogs.eatenMealsJson);
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

  Future<List<ReminderRow>> upcomingCustomReminders() => (select(reminders)
        ..where((t) =>
            t.deleted.equals(false) &
            t.type.equals('custom') &
            t.status.equals('upcoming') &
            t.dueDate.isBiggerThanValue(DateTime.now())))
      .get();

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

  /// All pregnancy-related assessments (check-ins + health checks), oldest
  /// first — feeds the risk wave chart.
  Stream<List<AssessmentRow>> watchPregnancyAssessments() => (select(assessments)
        ..where((t) =>
            t.deleted.equals(false) & t.subjectType.equals('pregnancy'))
        ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]))
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
  Future<List<ChatMessageRow>> dirtyChatMessages() =>
      (select(chatMessages)..where((t) => t.synced.equals(false))).get();

  Future<List<ChatMessageRow>> recentChatMessages(int limit) =>
      (select(chatMessages)
            ..where((t) => t.deleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.sentAt)])
            ..limit(limit))
          .get();

  Future<List<DietPlanRow>> dirtyDietPlans() =>
      (select(dietPlans)..where((t) => t.synced.equals(false))).get();
  Future<List<DietLogRow>> dirtyDietLogs() =>
      (select(dietLogs)..where((t) => t.synced.equals(false))).get();

  Stream<DietPlanRow?> watchLatestDietPlan() => (select(dietPlans)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.plannedFor)])
        ..limit(1))
      .watchSingleOrNull();

  Future<DietPlanRow?> latestDietPlan() => (select(dietPlans)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.plannedFor)])
        ..limit(1))
      .getSingleOrNull();

  Stream<List<DietLogRow>> watchRecentDietLogs(int days) => (select(dietLogs)
        ..where((t) => t.deleted.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.day)])
        ..limit(days))
      .watch();

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

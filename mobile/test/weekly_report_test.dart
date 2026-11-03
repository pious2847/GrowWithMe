import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/data/db/app_database.dart';
import 'package:grow_with_me/domain/weekly_report.dart';

void main() {
  final anchor = DateTime(2026, 11, 2);

  ChildRow child({
    String id = 'c1',
    String name = 'Ama',
    DateTime? dateOfBirth,
  }) => ChildRow(
    id: id,
    clientUpdatedAt: 0,
    deleted: false,
    synced: true,
    name: name,
    dateOfBirth: dateOfBirth ?? DateTime(2025, 5, 1),
  );

  ReminderRow reminder({
    required String id,
    required DateTime dueDate,
    String status = 'upcoming',
    DateTime? completedAt,
  }) => ReminderRow(
    id: id,
    clientUpdatedAt: 0,
    deleted: false,
    synced: true,
    type: 'immunization',
    title: 'Clinic visit',
    dueDate: dueDate,
    status: status,
    completedAt: completedAt,
  );

  AssessmentRow assessment({
    required String id,
    required DateTime completedAt,
    String riskLevel = 'low',
    String subjectType = 'child',
  }) => AssessmentRow(
    id: id,
    clientUpdatedAt: 0,
    deleted: false,
    synced: true,
    subjectType: subjectType,
    answersJson: '[]',
    dangerSignsJson: '[]',
    riskLevel: riskLevel,
    completedAt: completedAt,
  );

  GrowthRecordRow growth({
    required String id,
    required DateTime measuredAt,
    String childId = 'c1',
    double weightKg = 9.8,
  }) => GrowthRecordRow(
    id: id,
    clientUpdatedAt: 0,
    deleted: false,
    synced: true,
    childId: childId,
    weightKg: weightKg,
    measuredAt: measuredAt,
  );

  DietLogRow diet({required String id, required String day, int score = 8}) =>
      DietLogRow(
        id: id,
        clientUpdatedAt: 0,
        deleted: false,
        synced: true,
        day: day,
        groupsJson: '[]',
        score: score,
      );

  WeeklyReport build({
    List<ChildRow> children = const [],
    List<ReminderRow> reminders = const [],
    List<AssessmentRow> assessments = const [],
    List<PregnancyRow> pregnancies = const [],
    List<GrowthRecordRow> growthRecords = const [],
    List<DietLogRow> dietLogs = const [],
  }) => buildWeeklyReport(
    children: children,
    reminders: reminders,
    assessments: assessments,
    pregnancies: pregnancies,
    growthRecords: growthRecords,
    dietLogs: dietLogs,
    anchor: anchor,
    caregiverName: 'Akosua Mensah',
  );

  test('a family-less week is honest and welcoming', () {
    final report = build();

    expect(report.hasFamily, isFalse);
    expect(report.hasActivity, isFalse);
    expect(report.careScore, isNull);
    expect(report.scoreLabel, 'Let us begin');
    expect(report.firstName, 'Akosua');
    expect(report.mealPattern, hasLength(7));
    expect(report.mealPattern.every((meal) => !meal), isTrue);
    expect(report.closingLine, contains('Add your child'));
    expect(report.insights.single.tone, ReportTone.nudge);
  });

  test('a strong week scores from visits, checks, meals and growth', () {
    final report = build(
      children: [child()],
      reminders: [
        reminder(
          id: 'r1',
          dueDate: DateTime(2026, 10, 28),
          status: 'done',
          completedAt: DateTime(2026, 10, 28),
        ),
        reminder(id: 'r2', dueDate: DateTime(2026, 11, 2)),
      ],
      assessments: [
        assessment(id: 'a1', completedAt: DateTime(2026, 10, 28)),
        assessment(id: 'a2', completedAt: DateTime(2026, 11, 1)),
      ],
      growthRecords: [growth(id: 'g1', measuredAt: DateTime(2026, 10, 30))],
      dietLogs: [
        diet(id: 'd1', day: '2026-10-27'),
        diet(id: 'd2', day: '2026-10-28'),
        diet(id: 'd3', day: '2026-10-29'),
        diet(id: 'd4', day: '2026-10-30'),
        diet(id: 'd5', day: '2026-10-31'),
      ],
    );

    expect(report.visitsDue, 2);
    expect(report.visitsDone, 1);
    expect(report.visitsUpcoming, 1);
    expect(report.healthChecks, 2);
    expect(report.growthChecks, 1);
    expect(report.mealDays, 5);
    expect(report.avgPlateScore, 8);
    expect(report.activeDays, 6);

    // 0.5*0.4 + 1.0*0.25 + 0.749*0.20 + 1.0*0.15 = 74.97 -> 75.
    expect(report.careScore, 75);
    expect(report.scoreLabel, 'Strong week');
    expect(report.closingLine, contains('building something steady'));

    expect(report.mealPattern.take(5).every((meal) => meal), isTrue);
    expect(report.mealPattern.skip(5).any((meal) => meal), isFalse);

    final tones = report.insights.map((i) => i.tone).toList();
    expect(tones, contains(ReportTone.win));
    expect(tones, contains(ReportTone.nudge));
    expect(report.children.single.firstName, 'Ama');
    expect(report.children.single.latestWeightKg, 9.8);
    expect(report.children.single.measuredThisWeek, isTrue);
  });

  test('missed visits and urgent checks surface as nudges and alerts', () {
    final report = build(
      children: [child()],
      reminders: [reminder(id: 'r1', dueDate: DateTime(2026, 10, 28))],
      assessments: [
        assessment(
          id: 'a1',
          completedAt: DateTime(2026, 11, 1),
          riskLevel: 'urgent',
        ),
      ],
    );

    expect(report.visitsMissed, 1);
    expect(report.urgentChecks, 1);
    expect(report.careScore, lessThan(30));

    final texts = report.insights.map((i) => i.text).join(' ');
    expect(texts, contains('slipped by'));
    expect(report.insights.any((i) => i.tone == ReportTone.alert), isTrue);
  });

  test('records outside the rolling seven days are ignored', () {
    final report = build(
      children: [child()],
      assessments: [
        assessment(id: 'old-a', completedAt: DateTime(2026, 10, 20)),
      ],
      growthRecords: [growth(id: 'old-g', measuredAt: DateTime(2026, 9, 1))],
      dietLogs: [
        diet(id: 'old-d', day: '2026-10-20'),
        diet(id: 'new-d', day: '2026-10-27'),
      ],
    );

    expect(report.healthChecks, 0);
    expect(report.growthChecks, 0);
    expect(report.mealDays, 1);
    expect(report.mealPattern.first, isTrue);
    expect(report.mealPattern.skip(1).any((meal) => meal), isFalse);
    expect(report.activeDays, 1);
  });

  test('pregnancy week is derived from the due date', () {
    final pregnancies = [
      PregnancyRow(
        id: 'p1',
        clientUpdatedAt: 0,
        deleted: false,
        synced: true,
        expectedDueDate: anchor.add(const Duration(days: 70)),
        status: 'active',
      ),
    ];
    final report = build(pregnancies: pregnancies);

    expect(report.hasFamily, isTrue);
    expect(report.activePregnancies, 1);
    expect(report.pregnancyWeek, 30);
    expect(report.careScore, isNull);
    expect(report.scoreLabel, 'A fresh week');
    expect(report.insights.any((i) => i.text.contains('week 30')), isTrue);
  });

  test('a family with no recorded care gets a gentle start, not a zero', () {
    final report = build(children: [child()]);

    expect(report.hasFamily, isTrue);
    expect(report.hasActivity, isFalse);
    expect(report.careScore, isNull);
    expect(report.scoreLabel, 'A fresh week');
    expect(report.closingLine, contains('Small steps count'));
  });

  test('deleted records never count', () {
    final report = build(
      children: [
        ChildRow(
          id: 'gone',
          clientUpdatedAt: 0,
          deleted: true,
          synced: true,
          name: 'Gone',
          dateOfBirth: DateTime(2025, 1, 1),
        ),
      ],
      reminders: [
        ReminderRow(
          id: 'gone-r',
          clientUpdatedAt: 0,
          deleted: true,
          synced: true,
          type: 'immunization',
          title: 'Deleted visit',
          dueDate: DateTime(2026, 10, 28),
          status: 'upcoming',
        ),
      ],
      dietLogs: [
        DietLogRow(
          id: 'gone-d',
          clientUpdatedAt: 0,
          deleted: true,
          synced: true,
          day: '2026-10-28',
          groupsJson: '[]',
          score: 8,
        ),
      ],
    );

    expect(report.children, isEmpty);
    expect(report.visitsDue, 0);
    expect(report.mealDays, 0);
    expect(report.hasFamily, isFalse);
  });
}

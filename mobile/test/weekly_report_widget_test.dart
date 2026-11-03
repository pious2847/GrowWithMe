import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/core/providers.dart';
import 'package:grow_with_me/core/theme/app_theme.dart';
import 'package:grow_with_me/data/db/app_database.dart';
import 'package:grow_with_me/domain/weekly_report.dart';
import 'package:grow_with_me/features/plus/plus_screen.dart';
import 'package:grow_with_me/features/report/weekly_report_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
    final fraunces = FontLoader('Fraunces')
      ..addFont(rootBundle.load('assets/fonts/Fraunces-Variable.ttf'));
    await Future.wait([manrope.load(), fraunces.load()]);
  });

  final report = WeeklyReport(
    start: DateTime(2026, 10, 27),
    end: DateTime(2026, 11, 2),
    visitsDone: 3,
    visitsDue: 4,
    visitsMissed: 1,
    visitsUpcoming: 0,
    healthChecks: 2,
    urgentChecks: 1,
    growthChecks: 1,
    mealDays: 5,
    mealPattern: const [true, true, true, true, true, false, false],
    avgPlateScore: 7,
    activeDays: 6,
    children: const [
      ChildWeekSnapshot(
        name: 'Ama Mensah',
        ageMonths: 18,
        latestWeightKg: 9.8,
        measuredThisWeek: true,
      ),
    ],
    activePregnancies: 0,
    pregnancyWeek: null,
    careScore: 75,
    insights: const [
      ReportInsight(
        'Every care visit due this week is done. Well kept.',
        ReportTone.win,
      ),
    ],
    hasFamily: true,
    hasActivity: true,
    caregiverName: 'Akosua Mensah',
  );

  const palettes = [
    ReportCardTheme(
      name: 'Forest',
      colors: [Color(0xFF124C3A), Color(0xFF06241B)],
      ink: Color(0xFFFBF7EC),
      subtle: Color(0xCCFBF7EC),
      accent: Color(0xFFC7F06B),
      chip: Color(0x14FFFFFF),
      chipInk: Color(0xFFFBF7EC),
      line: Color(0x20FFFFFF),
    ),
    ReportCardTheme(
      name: 'Sunrise',
      colors: [Color(0xFFFF8A63), Color(0xFFD94722)],
      ink: Colors.white,
      subtle: Color(0xD9FFFFFF),
      accent: Color(0xFFFFE9A8),
      chip: Color(0x26FFFFFF),
      chipInk: Colors.white,
      line: Color(0x33FFFFFF),
    ),
    ReportCardTheme(
      name: 'Heritage',
      colors: [Color(0xFFF9F0DC), Color(0xFFEADCC0)],
      ink: Color(0xFF06241B),
      subtle: Color(0xCC3C4D45),
      accent: Color(0xFFF2643F),
      chip: Color(0xEFFFFFFF),
      chipInk: Color(0xFF06241B),
      line: Color(0xFFDCCBA8),
    ),
  ];

  testWidgets('share poster renders at 4:5 in every palette', (tester) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(420, 620) * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final palette in palettes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: ReportShareCard(report: report, cardTheme: palette),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: palette.name);
      expect(find.textContaining("Akosua's week"), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.textContaining('WEEK OF'), findsOneWidget);
      expect(find.text('TOVO LABs'), findsOneWidget);
    }
  });

  testWidgets('quiet-week poster reads as a fresh start, not a score', (
    tester,
  ) async {
    final emptyWeek = WeeklyReport(
      start: DateTime(2026, 10, 27),
      end: DateTime(2026, 11, 2),
      visitsDone: 0,
      visitsDue: 0,
      visitsMissed: 0,
      visitsUpcoming: 0,
      healthChecks: 0,
      urgentChecks: 0,
      growthChecks: 0,
      mealDays: 0,
      mealPattern: const [false, false, false, false, false, false, false],
      avgPlateScore: 0,
      activeDays: 0,
      children: const [
        ChildWeekSnapshot(
          name: 'Ama Mensah',
          ageMonths: 18,
          latestWeightKg: null,
          measuredThisWeek: false,
        ),
      ],
      activePregnancies: 0,
      pregnancyWeek: null,
      careScore: null,
      insights: const [
        ReportInsight('Nothing has been logged yet.', ReportTone.nudge),
      ],
      hasFamily: true,
      hasActivity: false,
      caregiverName: 'Akosua Mensah',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: ReportShareCard(
              report: emptyWeek,
              cardTheme: palettes.first,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Nothing logged'), findsOneWidget);
    expect(find.text('ADD ONE SMALL STEP'), findsOneWidget);
    expect(find.textContaining('/100'), findsNothing);
  });

  testWidgets('poster keeps its designed scale with large accessibility text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(420, 620) * 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: ReportShareCard(report: report, cardTheme: palettes.first),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Nana Plus starts and ends a clearly-labelled preview', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 3;
    // Tall viewport so the lazily-built ListView has the plan CTA in the tree.
    tester.view.physicalSize = const Size(360, 1200) * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const PlusScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining('Care that remembers'), findsOneWidget);
    expect(find.text('Start 7-day preview'), findsOneWidget);
    expect(find.textContaining('no payment'), findsWidgets);

    await tester.ensureVisible(find.text('Start 7-day preview'));
    await tester.pump();
    await tester.tap(find.text('Start 7-day preview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Start your 7-day preview?'), findsOneWidget);
    await tester.tap(find.text('Start preview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Preview active'), findsOneWidget);
    expect(find.text('End preview early'), findsOneWidget);
    expect(find.text('Start 7-day preview'), findsNothing);

    await tester.ensureVisible(find.text('End preview early'));
    await tester.pump();
    await tester.tap(find.text('End preview early'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('End your preview?'), findsOneWidget);
    await tester.tap(find.text('End preview'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Start 7-day preview'), findsOneWidget);
  });

  testWidgets('report screen fits a narrow 320 dp phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(320, 1400) * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final child = ChildRow(
      id: 'c1',
      clientUpdatedAt: 0,
      deleted: false,
      synced: true,
      name: 'Ama',
      dateOfBirth: DateTime(2025, 5, 1),
    );
    final growth = GrowthRecordRow(
      id: 'g1',
      clientUpdatedAt: 0,
      deleted: false,
      synced: true,
      childId: 'c1',
      weightKg: 9.8,
      measuredAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    final diet = DietLogRow(
      id: 'd1',
      clientUpdatedAt: 0,
      deleted: false,
      synced: true,
      day: dayKey(DateTime.now()),
      groupsJson: '[]',
      score: 7,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value([child])),
          allRemindersProvider.overrideWith(
            (ref) => Stream.value(<ReminderRow>[]),
          ),
          assessmentsProvider.overrideWith(
            (ref) => Stream.value(<AssessmentRow>[]),
          ),
          pregnanciesProvider.overrideWith(
            (ref) => Stream.value(<PregnancyRow>[]),
          ),
          allGrowthRecordsProvider.overrideWith(
            (ref) => Stream.value([growth]),
          ),
          dietLogsSinceProvider.overrideWith(
            (ref, key) => Stream.value([diet]),
          ),
          userNameProvider.overrideWith((ref) async => 'Akosua Mensah'),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WeeklyReportScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(find.text('This week'), findsOneWidget);
    expect(find.textContaining("Akosua's week"), findsOneWidget);
    expect(find.text('This week in numbers'), findsOneWidget);
    expect(find.text('How your score is built'), findsOneWidget);

    // The date range must describe the same window the card does.
    final today = dayStart(DateTime.now());
    final expectedRange =
        '${DateFormat('d MMM').format(today.subtract(const Duration(days: 6)))}'
        ' – ${DateFormat('d MMM yyyy').format(today)}';
    expect(find.text(expectedRange), findsOneWidget);
  });

  testWidgets('free report keeps past weeks behind Nana Plus', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(360, 1200) * 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith((ref) => Stream.value(<ChildRow>[])),
          allRemindersProvider.overrideWith(
            (ref) => Stream.value(<ReminderRow>[]),
          ),
          assessmentsProvider.overrideWith(
            (ref) => Stream.value(<AssessmentRow>[]),
          ),
          pregnanciesProvider.overrideWith(
            (ref) => Stream.value(<PregnancyRow>[]),
          ),
          allGrowthRecordsProvider.overrideWith(
            (ref) => Stream.value(<GrowthRecordRow>[]),
          ),
          dietLogsSinceProvider.overrideWith(
            (ref, key) => Stream.value(<DietLogRow>[]),
          ),
          userNameProvider.overrideWith((ref) async => 'Akosua Mensah'),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WeeklyReportScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Keep every week'), findsOneWidget);
    expect(find.text('See Nana Plus'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
  });
}

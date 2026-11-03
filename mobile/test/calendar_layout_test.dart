import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/core/providers.dart';
import 'package:grow_with_me/core/theme/app_theme.dart';
import 'package:grow_with_me/data/db/app_database.dart';
import 'package:grow_with_me/features/calendar/calendar_tab.dart';
import 'package:table_calendar/table_calendar.dart';

/// Regression guard for the theme's button minimum size. A
/// `Size.fromHeight` minimum makes buttons demand infinite width and silently
/// corrupts any Row containing a button (the calendar shipped broken once).
void main() {
  Future<void> pumpCalendar(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allRemindersProvider.overrideWith(
            (ref) => Stream<List<ReminderRow>>.value(const []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            appBar: AppBar(title: const Text('Care calendar')),
            body: const CalendarTab(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('calendar lays out without constraint errors', (tester) async {
    await pumpCalendar(tester, const Size(1080, 2400));

    expect(tester.takeException(), isNull);
    final header = tester.getRect(find.text('No visits this month'));
    final table = tester.getRect(find.byType(TableCalendar<ReminderRow>));
    final legend = tester.getRect(find.text('My reminder'));

    expect(header.bottom, lessThanOrEqualTo(table.top));
    expect(table.bottom, lessThanOrEqualTo(legend.top));
    expect(legend.left, greaterThanOrEqualTo(0));
  });

  testWidgets('calendar survives a narrow phone', (tester) async {
    await pumpCalendar(tester, const Size(960, 2100));

    expect(tester.takeException(), isNull);
    expect(find.text('Remind me'), findsOneWidget);
  });
}

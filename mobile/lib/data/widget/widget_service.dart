import 'package:drift/drift.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../domain/nutrition_tips.dart';
import '../db/app_database.dart';

/// Pushes fresh data to the Android home-screen widget: today's/next care
/// visits plus the daily feeding tip. Everything is computed locally so the
/// widget works with zero connectivity.
class WidgetService {
  WidgetService(this._db);

  final AppDatabase _db;

  Future<void> refresh() async {
    try {
      final now = DateTime.now();
      final reminders = await (_db.select(_db.reminders)
            ..where((t) =>
                t.deleted.equals(false) & t.status.isIn(['upcoming', 'snoozed']))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
            ..limit(3))
          .get();

      final children = await (_db.select(_db.children)
            ..where((t) => t.deleted.equals(false)))
          .get();
      final pregnancies = await (_db.select(_db.pregnancies)
            ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
          .get();

      final fmt = DateFormat('E d MMM');
      final today = DateTime(now.year, now.month, now.day);
      String whenLabel(DateTime due) {
        final day = DateTime(due.year, due.month, due.day);
        if (day.isBefore(today)) return 'Overdue';
        if (day == today) return 'Today';
        if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
        return fmt.format(due);
      }

      // Daily tip: pregnancy takes priority, else youngest child's age band.
      String tip;
      if (pregnancies.isNotEmpty) {
        final t = dailyPregnancyTip();
        tip = '${t.title}: ${t.body}';
      } else if (children.isNotEmpty) {
        children.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
        final months = now.difference(children.first.dateOfBirth).inDays ~/ 30;
        final t = dailyChildTip(months);
        tip = '${t.title}: ${t.body}';
      } else {
        tip = 'Add a child or pregnancy in the app to get daily feeding tips.';
      }

      await HomeWidget.saveWidgetData<String>(
          'title', DateFormat('EEEE, d MMMM').format(now));
      for (var i = 0; i < 3; i++) {
        final has = i < reminders.length;
        await HomeWidget.saveWidgetData<String>(
            'when${i + 1}', has ? whenLabel(reminders[i].dueDate) : '');
        await HomeWidget.saveWidgetData<String>(
            'title${i + 1}',
            has
                ? reminders[i].title
                : (i == 0 ? 'No upcoming visits — all caught up!' : ''));
      }
      await HomeWidget.saveWidgetData<String>('tip', tip);
      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
      );

      // Nana widget: today's message = next visit (if any) + the daily tip.
      final nextLine = reminders.isEmpty
          ? ''
          : '${whenLabel(reminders.first.dueDate)}: ${reminders.first.title}. ';
      await HomeWidget.saveWidgetData<String>(
          'nana_date', DateFormat('EEE d MMM').format(now));
      await HomeWidget.saveWidgetData<String>('nana_message', '$nextLine$tip');
      await HomeWidget.updateWidget(
        name: 'NanaWidgetProvider',
        androidName: 'NanaWidgetProvider',
      );
    } catch (_) {
      // Widget refresh must never break app flows (e.g. no widget added yet).
    }
  }
}

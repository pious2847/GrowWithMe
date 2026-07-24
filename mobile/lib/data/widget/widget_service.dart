import 'package:drift/drift.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../domain/motivation.dart';
import '../../domain/nutrition_tips.dart';
import '../db/app_database.dart';

/// Feeds the home-screen widgets — all computed locally, refreshed on every
/// app open/sync and every 30 minutes by the launcher:
/// - Reminders widget: countdown to delivery (or child's age), this week's
///   checks, and the daily motivation line.
/// - Nana widget: her daily message (next visit + tip).
class WidgetService {
  WidgetService(this._db);

  final AppDatabase _db;

  Future<void> refresh() async {
    try {
      final now = DateTime.now();
      final weekAhead = now.add(const Duration(days: 7));

      final reminders = await (_db.select(_db.reminders)
            ..where((t) =>
                t.deleted.equals(false) & t.status.isIn(['upcoming', 'snoozed']))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
            ..limit(10))
          .get();
      final children = await (_db.select(_db.children)
            ..where((t) => t.deleted.equals(false)))
          .get();
      final pregnancies = await (_db.select(_db.pregnancies)
            ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
          .get();

      // ---- Countdown: delivery first, else youngest child's age ----
      String big;
      String small;
      if (pregnancies.isNotEmpty) {
        pregnancies.sort(
            (a, b) => a.expectedDueDate.compareTo(b.expectedDueDate));
        final daysLeft =
            pregnancies.first.expectedDueDate.difference(now).inDays;
        if (daysLeft > 0) {
          big = '$daysLeft day${daysLeft == 1 ? '' : 's'}';
          small = 'to delivery 🍼';
        } else {
          big = 'Baby is due';
          small = 'stay close to your clinic';
        }
      } else if (children.isNotEmpty) {
        children.sort((a, b) => b.dateOfBirth.compareTo(a.dateOfBirth));
        final youngest = children.first;
        final days = now.difference(youngest.dateOfBirth).inDays;
        if (days < 60) {
          big = '${(days / 7).floor()} weeks';
        } else {
          big = '${days ~/ 30} months';
        }
        small = '${youngest.name} is growing 🌱';
      } else {
        big = 'Welcome';
        small = 'to GrowWithMe';
      }

      // ---- This week's checks ----
      final weekChecks = reminders
          .where((r) => !r.dueDate.isAfter(weekAhead))
          .take(3)
          .toList();

      await HomeWidget.saveWidgetData<String>('countdown_big', big);
      await HomeWidget.saveWidgetData<String>('countdown_small', small);
      // Raw values so the widget recomputes the countdown and motivation at
      // every render — it stays correct daily even if the app never opens.
      await HomeWidget.saveWidgetData<String>(
          'edd_millis',
          pregnancies.isNotEmpty
              ? pregnancies.first.expectedDueDate.millisecondsSinceEpoch
                  .toString()
              : '');
      await HomeWidget.saveWidgetData<String>(
          'dob_millis',
          children.isNotEmpty
              ? children.first.dateOfBirth.millisecondsSinceEpoch.toString()
              : '');
      await HomeWidget.saveWidgetData<String>(
          'child_name', children.isNotEmpty ? children.first.name : '');
      await HomeWidget.saveWidgetData<String>(
          'motivations', motivationLines.join('|'));
      for (var i = 0; i < 3; i++) {
        await HomeWidget.saveWidgetData<String>(
          'check${i + 1}',
          i < weekChecks.length
              ? '${DateFormat('EEE').format(weekChecks[i].dueDate)} · ${weekChecks[i].title}'
              : (i == 0 ? 'No visits this week — on track! 🎉' : ''),
        );
      }
      await HomeWidget.saveWidgetData<String>(
          'motivation', dailyMotivation());
      await HomeWidget.updateWidget(
        name: 'ReminderWidgetProvider',
        androidName: 'ReminderWidgetProvider',
      );

      // ---- Nana widget: next visit + daily tip ----
      String tip;
      if (pregnancies.isNotEmpty) {
        final t = dailyPregnancyTip();
        tip = '${t.title}: ${t.body}';
      } else if (children.isNotEmpty) {
        final months = now.difference(children.first.dateOfBirth).inDays ~/ 30;
        final t = dailyChildTip(months);
        tip = '${t.title}: ${t.body}';
      } else {
        tip = 'Add a child or pregnancy in the app to get daily feeding tips.';
      }
      final nextLine = reminders.isEmpty
          ? ''
          : '${DateFormat('EEE d MMM').format(reminders.first.dueDate)}: ${reminders.first.title}. ';
      await HomeWidget.saveWidgetData<String>(
          'nana_date', DateFormat('EEE d MMM').format(now));
      await HomeWidget.saveWidgetData<String>('nana_message', '$nextLine$tip');
      // The sleek strip widget shows just one short line.
      await HomeWidget.saveWidgetData<String>(
          'nana_short',
          nextLine.isNotEmpty
              ? nextLine.trim().replaceAll(RegExp(r'\.\s*$'), '')
              : tip.split(':').first);
      await HomeWidget.updateWidget(
        name: 'NanaWidgetProvider',
        androidName: 'NanaWidgetProvider',
      );
    } catch (_) {
      // Widget refresh must never break app flows.
    }
  }
}

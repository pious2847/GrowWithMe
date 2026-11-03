import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/weekly_report.dart';

/// How much history each plan keeps.
const kFreeReportWeeks = 1;
const kPlusReportWeeks = 12;

int reportHistoryLimit(bool plus) => plus ? kPlusReportWeeks : kFreeReportWeeks;

/// The current local day, rolled over just after midnight and whenever the app
/// returns to the foreground.
///
/// Rolling seven-day windows are anchored to this value, so a phone that stays
/// open overnight still shows a report that ends today rather than yesterday.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> with WidgetsBindingObserver {
  Timer? _timer;
  bool _observing = false;

  @override
  DateTime build() {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    ref.onDispose(() {
      _timer?.cancel();
      if (_observing) {
        WidgetsBinding.instance.removeObserver(this);
        _observing = false;
      }
    });
    final now = DateTime.now();
    _scheduleNextDay(now);
    return dayStart(now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    final today = dayStart(DateTime.now());
    if (today != state) state = today;
    _scheduleNextDay(DateTime.now());
  }

  void _scheduleNextDay(DateTime now) {
    _timer?.cancel();
    final tomorrow = dayStart(now).add(const Duration(days: 1));
    _timer = Timer(
      tomorrow.difference(now) + const Duration(seconds: 1),
      _refresh,
    );
  }
}

/// Builds the report for [weekOffset] weeks back (0 = the current week).
///
/// Returns null while the local streams are still loading their first frame.
/// Everything is computed on the device — opening a report never touches the
/// network.
final weeklyReportProvider = Provider.family<WeeklyReport?, int>((
  ref,
  weekOffset,
) {
  final offset = weekOffset < 0 ? 0 : weekOffset;
  final anchor = ref.watch(todayProvider).subtract(Duration(days: 7 * offset));

  final children = ref.watch(childrenProvider).value;
  final reminders = ref.watch(allRemindersProvider).value;
  final assessments = ref.watch(assessmentsProvider).value;
  final pregnancies = ref.watch(pregnanciesProvider).value;
  final growthRecords = ref.watch(allGrowthRecordsProvider).value;
  final dietStart = dayKey(anchor.subtract(const Duration(days: 6)));
  final dietLogs = ref.watch(dietLogsSinceProvider(dietStart)).value;

  if (children == null ||
      reminders == null ||
      assessments == null ||
      pregnancies == null ||
      growthRecords == null ||
      dietLogs == null) {
    return null;
  }

  return buildWeeklyReport(
    children: children,
    reminders: reminders,
    assessments: assessments,
    pregnancies: pregnancies,
    growthRecords: growthRecords,
    dietLogs: dietLogs,
    anchor: anchor,
    caregiverName: ref.watch(userNameProvider).value,
  );
});

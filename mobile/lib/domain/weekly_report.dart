import 'package:flutter/foundation.dart';

import '../data/db/app_database.dart';

/// A warm, plain-language weekly summary of the care a family actually did.
///
/// Everything here is derived on the device from local records. Nothing is
/// sent anywhere to build it, so the report works offline and respects the
/// app's privacy promise.

enum ReportTone { win, nudge, alert }

@immutable
class ReportInsight {
  const ReportInsight(this.text, this.tone);

  final String text;
  final ReportTone tone;
}

@immutable
class ChildWeekSnapshot {
  const ChildWeekSnapshot({
    required this.name,
    required this.ageMonths,
    this.latestWeightKg,
    this.measuredThisWeek = false,
  });

  final String name;
  final int ageMonths;
  final double? latestWeightKg;
  final bool measuredThisWeek;

  String get ageLabel {
    if (ageMonths < 1) return 'newborn';
    if (ageMonths < 24) return '$ageMonths months';
    final years = ageMonths ~/ 12;
    return '$years year${years == 1 ? '' : 's'}';
  }

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Your child';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

@immutable
class WeeklyReport {
  const WeeklyReport({
    required this.start,
    required this.end,
    required this.visitsDone,
    required this.visitsDue,
    required this.visitsMissed,
    required this.visitsUpcoming,
    required this.healthChecks,
    required this.urgentChecks,
    required this.growthChecks,
    required this.mealDays,
    required this.mealPattern,
    required this.avgPlateScore,
    required this.activeDays,
    required this.children,
    required this.activePregnancies,
    required this.pregnancyWeek,
    required this.careScore,
    required this.insights,
    required this.hasFamily,
    required this.hasActivity,
    required this.caregiverName,
  });

  /// Inclusive first day and exclusive end of the seven-day window.
  final DateTime start;
  final DateTime end;

  final int visitsDone;
  final int visitsDue;
  final int visitsMissed;
  final int visitsUpcoming;

  final int healthChecks;
  final int urgentChecks;
  final int growthChecks;

  /// One flag per day in the window, oldest first, for the meal dot row.
  final List<bool> mealPattern;

  final int mealDays;
  final int avgPlateScore;

  /// Days in the window with at least one recorded care action.
  final int activeDays;

  final List<ChildWeekSnapshot> children;
  final int activePregnancies;
  final int? pregnancyWeek;

  /// 0-100, or null when there is not enough activity to score honestly.
  final int? careScore;
  final List<ReportInsight> insights;
  final bool hasFamily;
  final bool hasActivity;
  final String? caregiverName;

  String? get firstName {
    final trimmed = (caregiverName ?? '').trim();
    if (trimmed.isEmpty) return null;
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get scoreLabel {
    final score = careScore;
    if (score == null) return hasFamily ? 'A fresh week' : 'Let us begin';
    if (score >= 85) return 'Thriving';
    if (score >= 70) return 'Strong week';
    if (score >= 50) return 'Growing well';
    if (score > 0) return 'A good start';
    return 'A fresh week';
  }

  String get closingLine {
    final score = careScore;
    if (!hasFamily) {
      return 'Add your child or pregnancy and I will help you build the first '
          'care plan, one small step at a time.';
    }
    if (score == null || score < 50) {
      return 'Small steps count. Pick one thing today — a check-in, a meal, '
          'or a visit — and we will grow from there.';
    }
    if (score < 85) {
      return 'You are building something steady. Keep going, and let Nana '
          'carry the reminders for you.';
    }
    return 'What a week of care. Rest well, mama — your family is stronger '
        'because of you.';
  }
}

class _Acc {
  double weighted = 0;
  double weight = 0;

  void add(double value, double w) {
    if (value.isNaN || value.isInfinite) return;
    weighted += value.clamp(0, 1) * w;
    weight += w;
  }

  int? get score => weight == 0 ? null : (weighted / weight * 100).round();
}

DateTime dayStart(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';

int _ageMonths(DateTime dob, DateTime at) {
  final days = at.difference(dayStart(dob)).inDays;
  if (days <= 0) return 0;
  return (days / 30.44).floor();
}

int? _pregnancyWeek(DateTime dueDate, DateTime at) {
  final daysLeft = dayStart(dueDate).difference(dayStart(at)).inDays;
  final week = 40 - (daysLeft / 7).ceil();
  if (week < 1) return 1;
  if (week > 42) return 42;
  return week;
}

/// Builds the seven-day window ending on [anchor] (today by default).
WeeklyReport buildWeeklyReport({
  required List<ChildRow> children,
  required List<ReminderRow> reminders,
  required List<AssessmentRow> assessments,
  required List<PregnancyRow> pregnancies,
  required List<GrowthRecordRow> growthRecords,
  required List<DietLogRow> dietLogs,
  DateTime? anchor,
  String? caregiverName,
}) {
  final today = dayStart(anchor ?? DateTime.now());
  final start = today.subtract(const Duration(days: 6));
  final end = today.add(const Duration(days: 1));
  final startKey = dayKey(start);
  final endKey = dayKey(today);

  bool inWindow(DateTime? value) =>
      value != null && !value.isBefore(start) && value.isBefore(end);

  final liveChildren = children.where((c) => !c.deleted).toList();
  final livePregnancies = pregnancies
      .where((p) => !p.deleted && p.status == 'active')
      .toList();
  final liveReminders = reminders.where((r) => !r.deleted).toList();

  final dueReminders = liveReminders
      .where((r) => inWindow(r.dueDate))
      .toList(growable: false);

  bool isDone(ReminderRow r) =>
      r.status == 'done' || (r.completedAt != null && inWindow(r.completedAt));

  final visitsDue = dueReminders.length;
  final visitsDone = dueReminders.where(isDone).length;
  final visitsMissed = dueReminders.where((r) {
    if (isDone(r)) return false;
    return r.status == 'missed' || r.dueDate.isBefore(today);
  }).length;
  final visitsUpcoming = dueReminders.where((r) {
    if (isDone(r) || r.status == 'missed') return false;
    return !r.dueDate.isBefore(today);
  }).length;

  final weekAssessments = assessments
      .where((a) => !a.deleted && inWindow(a.completedAt))
      .toList(growable: false);
  final healthChecks = weekAssessments.length;
  final urgentChecks = weekAssessments
      .where((a) => a.riskLevel == 'urgent')
      .length;

  final weekGrowth = growthRecords
      .where((g) => !g.deleted && inWindow(g.measuredAt))
      .toList(growable: false);
  final growthChecks = weekGrowth.length;

  final weekDiet = dietLogs
      .where((d) {
        if (d.deleted) return false;
        return d.day.compareTo(startKey) >= 0 && d.day.compareTo(endKey) <= 0;
      })
      .toList(growable: false);

  final mealDays = weekDiet.map((d) => d.day).toSet().length;
  final mealDaysLogged = weekDiet.map((d) => d.day).toSet();
  final mealPattern = List<bool>.generate(
    7,
    (i) => mealDaysLogged.contains(dayKey(start.add(Duration(days: i)))),
    growable: false,
  );
  final avgPlateScore = weekDiet.isEmpty
      ? 0
      : (weekDiet.map((d) => d.score).reduce((a, b) => a + b) / weekDiet.length)
            .round();

  final activeDayKeys = <String>{};
  for (final r in liveReminders) {
    if (inWindow(r.completedAt)) activeDayKeys.add(dayKey(r.completedAt!));
  }
  for (final a in weekAssessments) {
    activeDayKeys.add(dayKey(a.completedAt));
  }
  for (final g in weekGrowth) {
    activeDayKeys.add(dayKey(g.measuredAt));
  }
  for (final d in weekDiet) {
    activeDayKeys.add(d.day);
  }

  final snapshots = <ChildWeekSnapshot>[];
  for (final child in liveChildren) {
    GrowthRecordRow? latest;
    var measuredThisWeek = false;
    for (final record in growthRecords) {
      if (record.deleted || record.childId != child.id) continue;
      if (inWindow(record.measuredAt)) measuredThisWeek = true;
      if (latest == null || record.measuredAt.isAfter(latest.measuredAt)) {
        latest = record;
      }
    }
    snapshots.add(
      ChildWeekSnapshot(
        name: child.name,
        ageMonths: _ageMonths(child.dateOfBirth, today),
        latestWeightKg: latest?.weightKg,
        measuredThisWeek: measuredThisWeek,
      ),
    );
  }
  snapshots.sort((a, b) => a.ageMonths.compareTo(b.ageMonths));

  final hasFamily = liveChildren.isNotEmpty || livePregnancies.isNotEmpty;
  final pregnancyWeek = livePregnancies.isEmpty
      ? null
      : _pregnancyWeek(livePregnancies.first.expectedDueDate, today);

  final acc = _Acc();
  if (visitsDue > 0) acc.add(visitsDone / visitsDue, 0.40);
  if (hasFamily) acc.add((healthChecks / 2).clamp(0, 1).toDouble(), 0.25);
  if (hasFamily) {
    acc.add((mealDays / 7) * 0.6 + (avgPlateScore / 10) * 0.4, 0.20);
  }
  if (liveChildren.isNotEmpty) {
    acc.add(growthChecks > 0 ? 1 : 0, 0.15);
  }

  final hasActivity =
      activeDayKeys.isNotEmpty ||
      healthChecks > 0 ||
      growthChecks > 0 ||
      visitsDone > 0;
  final careScore = hasActivity ? acc.score : null;

  final insights = <ReportInsight>[];
  if (!hasFamily) {
    insights.add(
      const ReportInsight(
        'Add a child or pregnancy so Nana can build your care plan.',
        ReportTone.nudge,
      ),
    );
  } else {
    if (visitsDue > 0) {
      if (visitsMissed > 0) {
        insights.add(
          ReportInsight(
            '$visitsMissed visit${visitsMissed == 1 ? '' : 's'} slipped by. '
            'Tap Calendar and we will rebook together.',
            ReportTone.nudge,
          ),
        );
      } else if (visitsDone == visitsDue) {
        insights.add(
          ReportInsight(
            'Every care visit due this week is done. Well kept.',
            ReportTone.win,
          ),
        );
      } else if (visitsUpcoming > 0) {
        insights.add(
          ReportInsight(
            '$visitsUpcoming visit${visitsUpcoming == 1 ? '' : 's'} still '
            'coming this week. Keep the date.',
            ReportTone.nudge,
          ),
        );
      }
    }
    if (urgentChecks > 0) {
      insights.add(
        const ReportInsight(
          'One check needed urgent care. Follow the referral plan and keep '
          'your phone close.',
          ReportTone.alert,
        ),
      );
    } else if (healthChecks > 0) {
      insights.add(
        ReportInsight(
          'You checked ${healthChecks == 1 ? 'a health concern' : '$healthChecks health concerns'} '
          'with Nana.',
          ReportTone.win,
        ),
      );
    }
    if (mealDays >= 4) {
      insights.add(
        ReportInsight(
          'Meals logged on $mealDays days — a strong, varied plate.',
          ReportTone.win,
        ),
      );
    } else if (mealDays > 0) {
      insights.add(
        ReportInsight(
          'Meals logged on $mealDays day${mealDays == 1 ? '' : 's'}. '
          'One more colourful plate tomorrow would help.',
          ReportTone.nudge,
        ),
      );
    } else {
      insights.add(
        const ReportInsight(
          'No meals logged yet. Add today\'s plate in Nana\'s Kitchen.',
          ReportTone.nudge,
        ),
      );
    }
    if (liveChildren.isNotEmpty) {
      insights.add(
        growthChecks > 0
            ? ReportInsight(
                '$growthChecks growth check${growthChecks == 1 ? '' : 's'} '
                'recorded this week.',
                ReportTone.win,
              )
            : const ReportInsight(
                'No weighing recorded this week. A growth check keeps the '
                'chart honest.',
                ReportTone.nudge,
              ),
      );
    }
    if (pregnancyWeek != null) {
      insights.add(
        ReportInsight(
          'You are in week $pregnancyWeek of pregnancy. Keep your next '
          'antenatal visit.',
          ReportTone.nudge,
        ),
      );
    }
    if (activeDayKeys.length >= 5) {
      insights.add(
        ReportInsight(
          'You showed up on ${activeDayKeys.length} of 7 days. That consistency '
          'is the whole game.',
          ReportTone.win,
        ),
      );
    }
  }

  return WeeklyReport(
    start: start,
    end: today,
    visitsDone: visitsDone,
    visitsDue: visitsDue,
    visitsMissed: visitsMissed,
    visitsUpcoming: visitsUpcoming,
    healthChecks: healthChecks,
    urgentChecks: urgentChecks,
    growthChecks: growthChecks,
    mealDays: mealDays,
    mealPattern: mealPattern,
    avgPlateScore: avgPlateScore,
    activeDays: activeDayKeys.length,
    children: snapshots,
    activePregnancies: livePregnancies.length,
    pregnancyWeek: pregnancyWeek,
    careScore: careScore,
    insights: insights,
    hasFamily: hasFamily,
    hasActivity: hasActivity,
    caregiverName: caregiverName,
  );
}

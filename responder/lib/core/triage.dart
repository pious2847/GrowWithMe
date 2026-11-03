import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme/app_colors.dart';

/// Visual triage level used to rank and colour case cards.
///
/// This is a *display* heuristic built from the danger signs already embedded
/// in the alert summary — it never replaces the clinical judgement of the
/// responder. Sorting simply puts the most alarming cases first.
enum TriageLevel { critical, high, standard }

class Triage {
  const Triage(this.level, this.signs);

  final TriageLevel level;
  final List<String> signs;

  int get signCount => signs.length;

  String get label => switch (level) {
        TriageLevel.critical => 'CRITICAL',
        TriageLevel.high => 'HIGH',
        TriageLevel.standard => 'STABLE',
      };

  Color get foreground => switch (level) {
        TriageLevel.critical => const Color(0xFF9A1B08),
        TriageLevel.high => const Color(0xFF8A4A00),
        TriageLevel.standard => AppColors.forest,
      };

  Color get background => switch (level) {
        TriageLevel.critical => AppColors.coralSoft,
        TriageLevel.high => AppColors.amberSoft,
        TriageLevel.standard => AppColors.limeSoft,
      };

  String get hint => switch (level) {
        TriageLevel.critical =>
          'Multiple serious signs — respond now and arrange referral.',
        TriageLevel.high => 'Needs a skilled pair of hands soon.',
        TriageLevel.standard => 'Monitor and support as needed.',
      };
}

const _criticalTerms = [
  'convulsion',
  'unconscious',
  'not breathing',
  'difficulty breathing',
  'bleeding',
  'severe headache',
  'blurred vision',
  'no movement',
  'cord',
  'fever',
  'vomiting everything',
  'swelling',
];

/// Reads the danger signs the caregiver app placed in the alert summary.
/// The backend builds it as "… Danger signs: a, b, c."
List<String> dangerSignsOf(Map<String, dynamic> alert) {
  final assessment = alert['assessment'];
  if (assessment is Map) {
    final signs = assessment['dangerSigns'];
    if (signs is List) {
      return signs.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    }
  }
  final summary = (alert['summary'] as String?) ?? '';
  final marker = summary.indexOf('Danger signs:');
  if (marker < 0) return const [];
  var tail = summary.substring(marker + 'Danger signs:'.length).trim();
  final stop = tail.indexOf('.');
  if (stop >= 0) tail = tail.substring(0, stop);
  if (tail.toLowerCase() == 'not specified') return const [];
  return tail
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.toLowerCase() != 'none')
      .toList();
}

Triage triageOf(Map<String, dynamic> alert) {
  final signs = dangerSignsOf(alert);
  final lower = signs.map((s) => s.toLowerCase()).join(' ');
  final serious =
      _criticalTerms.any((term) => lower.contains(term)) || signs.length >= 3;
  final level = serious
      ? TriageLevel.critical
      : signs.isNotEmpty
          ? TriageLevel.high
          : TriageLevel.standard;
  return Triage(level, signs);
}

/// Ordering weight: live cases before closed ones, newest demand first.
int statusRank(String? status) => switch (status) {
      'pending' || 'notified' || 'unassigned' => 0,
      'acknowledged' => 1,
      'en_route' => 2,
      'at_facility' => 3,
      'closed' => 4,
      _ => 5,
    };

/// Sorts a copy of the list most-urgent first: open before closed, then by
/// triage level, then by age (oldest waiting case first).
List<Map<String, dynamic>> sortCases(List<Map<String, dynamic>> alerts) {
  final copy = [...alerts];
  copy.sort((a, b) {
    final byStatus =
        statusRank(a['status'] as String?).compareTo(statusRank(b['status'] as String?));
    if (byStatus != 0) return byStatus;
    final byTriage = triageOf(a).level.index.compareTo(triageOf(b).level.index);
    if (byTriage != 0) return byTriage;
    final aAt = DateTime.tryParse(a['createdAt'] as String? ?? '');
    final bAt = DateTime.tryParse(b['createdAt'] as String? ?? '');
    if (aAt != null && bAt != null) return aAt.compareTo(bAt);
    return 0;
  });
  return copy;
}

/// Distance in metres between an alert location ([lng, lat]) and the responder.
double? distanceMeters(Map<String, dynamic> alert, double? myLat, double? myLng) {
  final location = alert['location'];
  final coords = location is Map ? location['coordinates'] : null;
  if (coords is! List || coords.length != 2 || myLat == null || myLng == null) {
    return null;
  }
  final lat = (coords[1] as num).toDouble();
  final lng = (coords[0] as num).toDouble();
  const earth = 6371000.0;
  final dLat = (lat - myLat) * math.pi / 180;
  final dLng = (lng - myLng) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(myLat * math.pi / 180) *
          math.cos(lat * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String distanceLabel(double? meters) {
  if (meters == null) return 'Distance unknown';
  if (meters < 950) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// "just now", "4 min", "3 h" — compact enough for chips.
String shortAgo(DateTime? time) {
  if (time == null) return '';
  final d = DateTime.now().difference(time.toLocal());
  if (d.isNegative || d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} d';
}

String clockOf(dynamic iso) {
  final t = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  if (t == null) return '';
  return DateFormat('HH:mm').format(t);
}

String dayLabel(dynamic iso) {
  final t = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  if (t == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return DateFormat('d MMM').format(t);
}

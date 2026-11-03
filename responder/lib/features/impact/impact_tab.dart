import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../home/widgets/case_card.dart';

/// Personal impact ledger built from the responder's real case history
/// (`GET /alerts`). Nothing is invented: if there is no history the screen
/// says so.
class ImpactTab extends StatelessWidget {
  const ImpactTab({
    super.key,
    required this.alerts,
    required this.onOpenAlert,
    required this.onRefresh,
    required this.loading,
    required this.fromCache,
  });

  final List<Map<String, dynamic>> alerts;
  final ValueChanged<Map<String, dynamic>> onOpenAlert;
  final Future<void> Function() onRefresh;
  final bool loading;
  final bool fromCache;

  static DateTime? _eventTime(Map<String, dynamic> alert, String event) {
    final timeline = alert['timeline'];
    if (timeline is! List) return null;
    for (final entry in timeline) {
      if (entry is Map && entry['event'] == event && entry['at'] is String) {
        return DateTime.tryParse(entry['at'] as String)?.toLocal();
      }
    }
    return null;
  }

  static Duration? _between(
      Map<String, dynamic> alert, String fromEvent, String toEvent) {
    final start = fromEvent == 'created'
        ? DateTime.tryParse(alert['createdAt'] as String? ?? '')?.toLocal()
        : _eventTime(alert, fromEvent);
    final end = _eventTime(alert, toEvent);
    if (start == null || end == null) return null;
    final diff = end.difference(start);
    return diff.isNegative ? null : diff;
  }

  static String _duration(Duration? d) {
    if (d == null) return '—';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 48) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m == 0 ? '$h h' : '${h}h ${m}m';
    }
    // Some legacy test cases were acknowledged weeks later — report days
    // instead of a five-digit hour count.
    final days = d.inDays;
    final hours = d.inHours % 24;
    return hours == 0 ? '${days}d' : '${days}d ${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final closed = alerts
        .where((a) => a['status'] == 'closed')
        .toList()
      ..sort((a, b) {
        final aAt = _eventTime(a, 'closed') ??
            DateTime.tryParse(a['updatedAt'] as String? ?? '');
        final bAt = _eventTime(b, 'closed') ??
            DateTime.tryParse(b['updatedAt'] as String? ?? '');
        if (aAt == null || bAt == null) return 0;
        return bAt.compareTo(aAt);
      });

    final accepted = alerts
        .where((a) => _eventTime(a, 'acknowledged') != null)
        .toList();

    final acceptTimes = alerts
        .map((a) => _between(a, 'created', 'acknowledged'))
        .whereType<Duration>()
        .toList();
    final facilityTimes = alerts
        .map((a) => _between(a, 'acknowledged', 'at_facility'))
        .whereType<Duration>()
        .toList();

    final avgAccept = acceptTimes.isEmpty
        ? null
        : Duration(
            seconds:
                acceptTimes.fold<int>(0, (s, d) => s + d.inSeconds) ~/
                    acceptTimes.length,
          );
    final avgFacility = facilityTimes.isEmpty
        ? null
        : Duration(
            seconds:
                facilityTimes.fold<int>(0, (s, d) => s + d.inSeconds) ~/
                    facilityTimes.length,
          );

    final weekStart = DateTime.now()
        .subtract(const Duration(days: 6));
    final closedThisWeek = closed.where((a) {
      final at = _eventTime(a, 'closed');
      return at != null &&
          at.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).length;

    final days = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      final count = alerts.where((a) {
        final events = a['timeline'];
        if (events is! List) return false;
        return events.any((e) {
          if (e is! Map) return false;
          if (!['acknowledged', 'closed', 'at_facility'].contains(e['event'])) {
            return false;
          }
          final at = DateTime.tryParse(e['at'] as String? ?? '')?.toLocal();
          return at != null &&
              at.year == day.year &&
              at.month == day.month &&
              at.day == day.day;
        });
      }).length;
      return (day, count);
    });

    if (loading && alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          if (fromCache) ...[
            const NoticeBanner(
              icon: Icons.cloud_off_rounded,
              message: 'Offline — impact shown from your last saved history.',
            ),
            const SizedBox(height: 12),
          ],
          _ImpactHero(
            closed: closed.length,
            closedThisWeek: closedThisWeek,
            inProgress: alerts.length - closed.length,
            days: days,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bolt_rounded,
                  accent: AppColors.limeInk,
                  background: AppColors.limeSoft,
                  value: _duration(avgAccept),
                  label: 'AVG ACCEPT TIME',
                  note: 'From alert to “I’m coming”',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_hospital_rounded,
                  accent: AppColors.teal,
                  background: AppColors.tealSoft,
                  value: _duration(avgFacility),
                  label: 'AVG TO FACILITY',
                  note: 'Accepted → arrived',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_alt_rounded,
                  accent: AppColors.sky,
                  background: AppColors.skySoft,
                  value: '${accepted.length}',
                  label: 'ACCEPTED',
                  note: 'Cases you stepped into',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  icon: Icons.verified_user_rounded,
                  accent: AppColors.violet,
                  background: AppColors.violetSoft,
                  value: _completion(accepted.length, closed.length),
                  label: 'LOOP CLOSED',
                  note: 'Accepted cases fully closed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Recent outcomes',
            subtitle: 'Closed referral loops on your account',
          ),
          if (closed.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.insights_rounded,
                      size: 34, color: AppColors.faint),
                  const SizedBox(height: 10),
                  Text(
                    'Your first closed case will appear here.',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Impact is counted from real referral outcomes, not taps.',
                    textAlign: TextAlign.center,
                    style: t.bodySmall?.copyWith(
                        color: AppColors.faint, fontSize: 11.5),
                  ),
                ],
              ),
            )
          else
            for (final alert in closed.take(15)) ...[
              CaseCard(
                alert: alert,
                assigned: true,
                onTap: () => onOpenAlert(alert),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  static String _completion(int accepted, int closed) {
    if (accepted == 0) return '—';
    final pct = (closed / accepted * 100).round();
    return '$pct%';
  }
}

class _ImpactHero extends StatelessWidget {
  const _ImpactHero({
    required this.closed,
    required this.closedThisWeek,
    required this.inProgress,
    required this.days,
  });

  final int closed;
  final int closedThisWeek;
  final int inProgress;
  final List<(DateTime, int)> days;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(1, (m, d) => d.$2 > m ? d.$2 : m);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.forestDeep),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'YOUR IMPACT',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: AppColors.lime,
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, size: 14,
                  color: AppColors.cream.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$closed',
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 58,
                  height: 0.92,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                  fontVariations: [
                    FontVariation('wght', 700),
                    FontVariation('opsz', 48),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  closed == 1
                      ? 'referral loop\nclosed'
                      : 'referral loops\nclosed',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cream.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const Spacer(),
              _HeroChip(
                value: '+$closedThisWeek',
                label: 'THIS WEEK',
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Seven-day activity bars.
          SizedBox(
            height: 54,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 420),
                            height: 6 + (34 * day.$2 / maxCount),
                            decoration: BoxDecoration(
                              color: day.$2 == 0
                                  ? AppColors.cream.withValues(alpha: 0.16)
                                  : AppColors.lime,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('E').format(day.$1).substring(0, 1),
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroChip(value: '$inProgress', label: 'IN PROGRESS'),
              const SizedBox(width: 8),
              _HeroChip(value: '$closedThisWeek', label: 'OUTCOMES 7D'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.cream.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.accent,
    required this.background,
    required this.value,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final String value;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: accent,
            background: background,
            size: 34,
            iconSize: 17,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              height: 1.3,
              color: AppColors.faint,
            ),
          ),
        ],
      ),
    );
  }
}

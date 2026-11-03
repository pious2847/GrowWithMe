import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/triage.dart';
import '../../../core/ui/app_widgets.dart';

/// One case in the queue. Leads with severity and elapsed waiting time so a
/// responder can scan the list at arm's length, then the patient and the
/// danger signs, then distance and community.
class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.alert,
    required this.onTap,
    this.distance,
    this.assigned = false,
  });

  final Map<String, dynamic> alert;
  final VoidCallback onTap;
  final double? distance;

  /// True when this case belongs to the responder (shows the live status).
  final bool assigned;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final triage = triageOf(alert);
    final caregiver = alert['caregiver'] is Map
        ? (alert['caregiver'] as Map).cast<String, dynamic>()
        : null;
    final name = caregiver?['name'] as String? ?? 'Urgent case';
    final community = caregiver?['community'] as String?;
    final created = DateTime.tryParse(alert['createdAt'] as String? ?? '');
    final int? waiting = created == null
        ? null
        : DateTime.now().difference(created.toLocal()).inMinutes;
    final status = alert['status'] as String? ?? 'pending';
    final closed = status == 'closed';
    final signs = triage.signs;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: AppRadii.lg,
      onTap: onTap,
      borderColor: triage.level == TriageLevel.critical
          ? AppColors.coral.withValues(alpha: 0.35)
          : AppColors.line,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: triage.foreground,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadii.lg),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TriagePill(
                          label: triage.label,
                          foreground: triage.foreground,
                          background: triage.background,
                          icon: triage.level == TriageLevel.critical
                              ? Icons.priority_high_rounded
                              : null,
                          dense: true,
                        ),
                        const SizedBox(width: 6),
                        if (assigned) StatusPill(status: status, dense: true),
                        const Spacer(),
                        if (!closed && waiting != null && waiting > 0)
                          _WaitChip(
                            minutes: waiting,
                            urgent: waiting >= 10 &&
                                statusRank(status) == 0,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.titleMedium?.copyWith(
                              fontSize: 17,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (distance != null)
                          Text(
                            distanceLabel(distance),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (community != null && community.isNotEmpty) community,
                        if (_subject(alert) != null) _subject(alert)!,
                      ].join('  ·  '),
                      style: t.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (signs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final sign in signs.take(2))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: triage.background,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                sign,
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: triage.foreground,
                                ),
                              ),
                            ),
                          if (signs.length > 2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.creamDeep,
                                borderRadius:
                                    BorderRadius.circular(AppRadii.pill),
                              ),
                              child: Text(
                                '+${signs.length - 2} more',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          assigned
                              ? Icons.arrow_circle_right_rounded
                              : Icons.touch_app_rounded,
                          size: 16,
                          color: AppColors.forest,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          closed
                              ? 'View case record'
                              : assigned
                                  ? 'Open live case'
                                  : 'Tap to step in',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _subject(Map<String, dynamic> alert) {
    final summary = (alert['summary'] as String?) ?? '';
    if (summary.contains('child under 5')) return 'Child under 5';
    if (summary.contains('pregnant mother')) return 'Pregnant mother';
    if (summary.contains('mother')) return 'Mother';
    return null;
  }
}

class _WaitChip extends StatelessWidget {
  const _WaitChip({required this.minutes, required this.urgent});

  final int minutes;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final label = minutes < 60
        ? '$minutes min'
        : minutes < 48 * 60
            ? '${minutes ~/ 60} h'
            : '${minutes ~/ 1440} d';
    return AnimatedContainer(
      duration: AppMotion.base,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? AppColors.coralSoft : AppColors.creamDeep,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 12,
            color: urgent ? AppColors.coral : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: urgent ? AppColors.coral : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

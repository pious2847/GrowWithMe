import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/ui/app_widgets.dart';

/// The responder's command header: who you are, whether you are on duty, and
/// the three numbers that matter at a glance.
class DutyHero extends StatelessWidget {
  const DutyHero({
    super.key,
    required this.user,
    required this.available,
    required this.onChanged,
    required this.activeCases,
    required this.nearbyCases,
    required this.closedThisWeek,
    this.locationKnown = true,
  });

  final Map<String, dynamic> user;
  final bool available;
  final ValueChanged<bool> onChanged;
  final int activeCases;
  final int nearbyCases;
  final int closedThisWeek;
  final bool locationKnown;

  String get _name => (user['name'] as String?)?.trim().isNotEmpty == true
      ? user['name'] as String
      : 'Responder';

  String get _tier => kTiers[user['credentials']?['tier'] as String?] ??
      'Community responder';

  bool get _verified => user['credentials']?['status'] == 'verified';

  String get _initials {
    final parts =
        _name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.forestDeep),
        boxShadow: AppShadows.raised,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -50,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.lime.withValues(alpha: 0.20),
                        AppColors.lime.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 22,
              top: 58,
              child: Sparkle(
                size: 13,
                color: AppColors.lime.withValues(alpha: 0.7),
              ),
            ),
            Positioned(
              right: 46,
              top: 112,
              child: Sparkle(
                size: 8,
                color: AppColors.cream.withValues(alpha: 0.32),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.limeGradient,
                          border: Border.all(
                              color: AppColors.cream.withValues(alpha: 0.35),
                              width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting,',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cream.withValues(alpha: 0.66),
                              ),
                            ),
                            Text(
                              _name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 23,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cream,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _tier,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.cream
                                          .withValues(alpha: 0.72),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _verified
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 13,
                                  color: _verified
                                      ? AppColors.lime
                                      : AppColors.amber,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _DutyToggle(available: available, onChanged: onChanged),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.cream.withValues(alpha: 0.12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          value: '$activeCases',
                          label: 'LIVE CASES',
                          icon: Icons.bolt_rounded,
                          accent: AppColors.lime,
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: MetricTile(
                          value: '$nearbyCases',
                          label: 'NEARBY',
                          icon: Icons.radar_rounded,
                          accent: AppColors.cream.withValues(alpha: 0.85),
                        ),
                      ),
                      _Divider(),
                      Expanded(
                        child: MetricTile(
                          value: '$closedThisWeek',
                          label: 'CLOSED · 7D',
                          icon: Icons.task_alt_rounded,
                          accent: AppColors.cream.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  if (!locationKnown || !available) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            available
                                ? Icons.location_off_rounded
                                : Icons.do_not_disturb_on_rounded,
                            size: 14,
                            color: AppColors.cream.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              available
                                  ? 'Location unavailable — enable GPS to see nearby cases.'
                                  : 'Off duty — nearby cases are paused. You can still open your own.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cream.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: AppColors.cream.withValues(alpha: 0.12),
    );
  }
}

class _DutyToggle extends StatelessWidget {
  const _DutyToggle({required this.available, required this.onChanged});

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => onChanged(!available),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.enter,
            width: 56,
            height: 32,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: available
                  ? AppColors.lime
                  : AppColors.cream.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: AnimatedAlign(
              duration: AppMotion.base,
              curve: AppMotion.enter,
              alignment:
                  available ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: available ? AppColors.forestDeep : AppColors.cream,
                  boxShadow: AppShadows.floating,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          available ? 'ON DUTY' : 'OFF DUTY',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: available
                ? AppColors.lime
                : AppColors.cream.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

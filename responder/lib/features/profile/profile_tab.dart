import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';

/// Identity, credentials and field tools. Kept deliberately boring and
/// legible: this is where a responder checks their verification state, the
/// offline model and who can see their data.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.user,
    required this.available,
    required this.onAvailabilityChanged,
    required this.onRefreshUser,
    required this.onLogout,
    required this.pendingUpdates,
    required this.modelReady,
    required this.modelVersion,
  });

  final Map<String, dynamic> user;
  final bool available;
  final ValueChanged<bool> onAvailabilityChanged;
  final Future<void> Function() onRefreshUser;
  final VoidCallback onLogout;
  final int pendingUpdates;
  final bool modelReady;
  final int? modelVersion;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final credentials = user['credentials'] is Map
        ? (user['credentials'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final status = credentials['status'] as String? ?? 'unverified';
    final tier = kTiers[credentials['tier']] ?? 'Responder';
    final docs = (credentials['documents'] as List?) ?? const [];
    final hasCard = docs.any((d) => d is Map && d['kind'] == 'ghana_card');
    final hasLicense = docs.any((d) => d is Map && d['kind'] == 'license');
    final name = (user['name'] as String?)?.trim().isNotEmpty == true
        ? user['name'] as String
        : 'Responder';
    final phone = user['phone'] as String? ?? '';
    final region = user['region'] as String? ?? '';
    final district = user['district'] as String? ?? '';
    final community = user['community'] as String? ?? '';

    final (statusLabel, statusColor, statusBg, statusIcon) = switch (status) {
      'verified' => (
          'VERIFIED',
          AppColors.teal,
          AppColors.tealSoft,
          Icons.verified_rounded
        ),
      'rejected' => (
          'NOT APPROVED',
          AppColors.coral,
          AppColors.coralSoft,
          Icons.report_gmailerrorred_rounded
        ),
      'pending' => (
          'IN REVIEW',
          const Color(0xFF8A4A00),
          AppColors.amberSoft,
          Icons.hourglass_top_rounded
        ),
      _ => (
          'UNVERIFIED',
          AppColors.muted,
          AppColors.creamDeep,
          Icons.shield_outlined
        ),
    };

    return RefreshIndicator(
      onRefresh: onRefreshUser,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          Text('Profile', style: t.displaySmall?.copyWith(
            color: AppColors.forestDeep, height: 1.05)),
          const SizedBox(height: 6),
          Text(
            'Your credentials, duty status and field tools.',
            style: t.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.all(18),
            gradient: AppColors.heroGradient,
            borderColor: AppColors.forestDeep,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ResponderMark(
                      size: 46,
                      showShadow: false,
                      background: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.forestMid, AppColors.forest],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 22,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cream,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tier,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  AppColors.cream.withValues(alpha: 0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Pill(
                      label: statusLabel,
                      icon: statusIcon,
                      foreground: statusColor,
                      background: statusBg,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  color: AppColors.cream.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _IdentityLine(
                        icon: Icons.phone_iphone_rounded,
                        label: 'PHONE',
                        value: phone.isEmpty ? '—' : phone,
                      ),
                    ),
                    Expanded(
                      child: _IdentityLine(
                        icon: Icons.public_rounded,
                        label: 'REGION',
                        value: region.isEmpty ? '—' : region,
                      ),
                    ),
                  ],
                ),
                if (district.isNotEmpty || community.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _IdentityLine(
                    icon: Icons.place_rounded,
                    label: 'AREA',
                    value: [district, community]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                IconBubble(
                  icon: available
                      ? Icons.health_and_safety_rounded
                      : Icons.do_not_disturb_on_rounded,
                  color: available ? AppColors.forest : AppColors.muted,
                  background:
                      available ? AppColors.limeSoft : AppColors.creamDeep,
                  size: 42,
                  iconSize: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(available ? 'On duty' : 'Off duty',
                          style: t.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        available
                            ? 'Urgent cases nearby can be routed to you.'
                            : 'You will not receive new cases.',
                        style: t.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: available,
                  onChanged: onAvailabilityChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Credentials',
            subtitle: 'What reviewers and routing can see',
          ),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _CredRow(
                  icon: Icons.credit_card_rounded,
                  label: 'Ghana Card',
                  done: hasCard,
                  optional: false,
                ),
                const Divider(height: 22),
                _CredRow(
                  icon: Icons.badge_rounded,
                  label: credentials['licenseNumber'] is String &&
                          (credentials['licenseNumber'] as String).isNotEmpty
                      ? 'License ${credentials['licenseNumber']}'
                      : 'Professional license',
                  done: hasLicense,
                  optional: !const ['nurse', 'midwife', 'doctor']
                      .contains(credentials['tier']),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    Icon(
                      statusIcon,
                      size: 19,
                      color: statusColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        switch (status) {
                          'verified' => 'Approved by an administrator',
                          'rejected' => 'Reviewer requested new documents',
                          'pending' => 'Waiting for administrator review',
                          _ => 'Documents not submitted yet',
                        },
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onRefreshUser,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Field tools',
            subtitle: 'Built to keep working when the network does not',
          ),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ToolRow(
                  icon: Icons.offline_bolt_rounded,
                  color: AppColors.violet,
                  background: AppColors.violetSoft,
                  title: 'Offline risk model',
                  subtitle: modelReady
                      ? 'Ready on this phone · v${modelVersion ?? '—'}'
                      : 'Downloads when you are online',
                  trailing: Pill(
                    label: modelReady ? 'READY' : 'OFFLINE',
                    foreground:
                        modelReady ? AppColors.teal : AppColors.muted,
                    background:
                        modelReady ? AppColors.tealSoft : AppColors.creamDeep,
                    dense: true,
                  ),
                ),
                const Divider(height: 22),
                _ToolRow(
                  icon: Icons.cloud_upload_rounded,
                  color: AppColors.sky,
                  background: AppColors.skySoft,
                  title: 'Queued updates',
                  subtitle: pendingUpdates == 0
                      ? 'Everything is synced'
                      : '$pendingUpdates status change${pendingUpdates == 1 ? '' : 's'} waiting for signal',
                  trailing: Pill(
                    label: '$pendingUpdates',
                    foreground: pendingUpdates == 0
                        ? AppColors.muted
                        : const Color(0xFF8A4A00),
                    background: pendingUpdates == 0
                        ? AppColors.creamDeep
                        : AppColors.amberSoft,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Privacy',
            subtitle: 'How patient data is handled',
          ),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in const [
                  'Patient names, phone numbers and locations are visible only while a case is routed to you.',
                  'Access is logged. Screenshots or sharing patient information ends your access.',
                  'Your ID documents and location data are encrypted in transit and handled under Ghana’s Data Protection Act, 2012 (Act 843).',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.shield_outlined,
                              size: 13, color: AppColors.forest),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line,
                            style: t.bodySmall?.copyWith(
                              color: AppColors.inkSoft,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sign out'),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'GrowWithMe Responder · v$kAppVersion',
              style: t.bodySmall?.copyWith(
                color: AppColors.faint,
                fontSize: 10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.cream.withValues(alpha: 0.55)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppColors.cream.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({
    required this.icon,
    required this.label,
    required this.done,
    required this.optional,
  });

  final IconData icon;
  final String label;
  final bool done;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 19,
            color: done
                ? AppColors.teal
                : optional
                    ? AppColors.muted
                    : AppColors.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Pill(
          label: done
              ? 'ON FILE'
              : optional
                  ? 'OPTIONAL'
                  : 'MISSING',
          foreground: done
              ? AppColors.teal
              : optional
                  ? AppColors.muted
                  : AppColors.coral,
          background: done
              ? AppColors.tealSoft
              : optional
                  ? AppColors.creamDeep
                  : AppColors.coralSoft,
          dense: true,
        ),
      ],
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBubble(
          icon: icon,
          color: color,
          background: background,
          size: 38,
          iconSize: 19,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  height: 1.35,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        trailing,
      ],
    );
  }
}

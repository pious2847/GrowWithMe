import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/regions.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../companion/nana_companion.dart';
import '../plus/plus_controller.dart';
import '../plus/plus_screen.dart';
import '../report/weekly_report_screen.dart';
import 'privacy_info_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = ref.watch(userNameProvider).value ?? '';
    final region = ref.watch(regionProvider).value ?? RegionSettings.defaults;
    final companion = ref.watch(companionVisibleProvider).value ?? true;
    final autoVoice = ref.watch(autoVoiceProvider).value ?? false;
    final voice = ref.watch(voiceProviderProvider).value ?? 'elevenlabs';
    final actionConsent = ref.watch(actionConsentProvider).value ?? false;
    final plus = ref.watch(plusProvider).value ?? const PlusState.free();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
        children: [
          SurfaceCard(
            gradient: AppColors.heroGradient,
            borderColor: AppColors.forest,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.trim().isEmpty
                        ? 'G'
                        : name.trim().characters.first.toUpperCase(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.forestDeep,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.trim().isEmpty ? 'Your care profile' : name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${region.country.flag} ${region.country.name}'
                        '${region.region == null ? '' : ' · ${region.region}'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cream.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const Pill(
                  label: 'FAMILY',
                  dense: true,
                  foreground: AppColors.forestDeep,
                  background: AppColors.lime,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _SettingsLabel('YOUR CARE'),
          _SettingsTile(
            icon: Icons.public_rounded,
            color: AppColors.sky,
            background: AppColors.skySoft,
            title: 'Country & language',
            subtitle: '${region.country.name} · ${_languageLabel(region)}',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => const _RegionEditorSheet(),
            ),
          ),
          _SettingsTile(
            icon: Icons.auto_graph_rounded,
            color: AppColors.teal,
            background: AppColors.tealSoft,
            title: 'Weekly care report',
            subtitle: 'Your week, summarised and ready to share',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsLabel('NANA, YOUR COMPANION'),
          _SettingsSwitch(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.forest,
            background: AppColors.limeSoft,
            title: 'Show Nana on screen',
            subtitle: companion
                ? 'She floats above your care pages'
                : 'Nana is resting — tap to bring her back',
            value: companion,
            onChanged: (v) =>
                ref.read(companionVisibleProvider.notifier).setVisible(v),
          ),
          _SettingsSwitch(
            icon: Icons.volume_up_rounded,
            color: AppColors.amber,
            background: AppColors.amberSoft,
            title: 'Read every question aloud',
            subtitle: 'Hands-free help for low-literacy caregivers',
            value: autoVoice,
            onChanged: (_) => ref.read(autoVoiceProvider.notifier).toggle(),
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconBubble(
                      icon: Icons.graphic_eq_rounded,
                      color: AppColors.violet,
                      size: 40,
                      iconSize: 19,
                      background: AppColors.violetSoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nana\'s voice',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'Natural speech when online',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'elevenlabs',
                      label: Text('ElevenLabs'),
                      icon: Icon(Icons.auto_awesome_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: 'fish_audio',
                      label: Text('Fish Audio'),
                      icon: Icon(Icons.waves_rounded, size: 15),
                    ),
                  ],
                  selected: {voice},
                  onSelectionChanged: (s) => ref
                      .read(voiceProviderProvider.notifier)
                      .setProvider(s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsLabel('NANA PLUS'),
          SurfaceCard(
            gradient: AppColors.heroGradient,
            borderColor: AppColors.forest,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PlusScreen())),
            child: Row(
              children: [
                const NanaPortrait(
                  size: 44,
                  alive: true,
                  asset: 'assets/illustrations/nana_happy.webp',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nana Plus',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.cream,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Pill(
                            label: plus.isActive ? 'ACTIVE' : 'NEW',
                            dense: true,
                            foreground: plus.isActive
                                ? AppColors.forestDeep
                                : AppColors.lime,
                            background: plus.isActive
                                ? AppColors.lime
                                : Colors.white.withValues(alpha: 0.10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plus.isActive
                            ? plus.renewalLine
                            : '12 weeks of reports · all insights · card styles',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cream.withValues(alpha: 0.74),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lime,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SettingsLabel('PRIVACY & TRUST'),
          _SettingsTile(
            icon: Icons.shield_rounded,
            color: AppColors.teal,
            background: AppColors.tealSoft,
            title: 'Your data is protected',
            subtitle: 'How we keep your family\'s information safe',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyInfoScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.data_usage_rounded,
            color: AppColors.violet,
            background: AppColors.violetSoft,
            title: 'Help improve GrowWithMe',
            subtitle: actionConsent
                ? 'On · anonymous taps only, never health details'
                : 'Share anonymous usage data · off by default',
            trailing: Switch(
              value: actionConsent,
              onChanged: (v) => _setActionConsent(context, ref, v),
            ),
            onTap: () => _setActionConsent(context, ref, !actionConsent),
          ),
          const SizedBox(height: 20),
          const _SettingsLabel('ABOUT'),
          SurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const BrandMark(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GrowWithMe', style: theme.textTheme.titleSmall),
                          Text(
                            'Version 1.0.0 (1) · TOVO LABs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  'GrowWithMe is an offline-first AI care companion for '
                  'mothers and children under five. It supports care — it '
                  'never replaces a health worker.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.coral,
              side: const BorderSide(color: AppColors.coralSoft),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Made with care in Ghana · for every family',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.faint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Opt-in is explicit and explained first: this data trains the on-device
  /// action model, so caregivers must know exactly what leaves the phone.
  static Future<void> _setActionConsent(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    if (enable) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Help Nana learn?'),
          content: const Text(
            'GrowWithMe can share which buttons and screens you use — like '
            '"opened Health check" or "added a child".\n\n'
            'It never shares names, phone numbers, messages, answers about '
            'your health, or where you are. You can turn this off anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(actionConsentProvider.notifier).set(enable);
  }

  static String _languageLabel(RegionSettings region) {
    final match = region.country.languages.where(
      (l) => l.code == region.languageCode,
    );
    return match.isEmpty ? 'English' : match.first.label;
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          letterSpacing: 1.1,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        padding: const EdgeInsets.all(13),
        onTap: onTap,
        child: Row(
          children: [
            IconBubble(
              icon: icon,
              color: color,
              size: 40,
              iconSize: 19,
              background: background,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SurfaceCard(
        padding: const EdgeInsets.all(13),
        child: Row(
          children: [
            IconBubble(
              icon: icon,
              color: color,
              size: 40,
              iconSize: 19,
              background: background,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _RegionEditorSheet extends ConsumerStatefulWidget {
  const _RegionEditorSheet();

  @override
  ConsumerState<_RegionEditorSheet> createState() => _RegionEditorSheetState();
}

class _RegionEditorSheetState extends ConsumerState<_RegionEditorSheet> {
  late CountryConfig _country;
  String? _region;
  late String _language;

  @override
  void initState() {
    super.initState();
    final current = ref.read(regionProvider).value ?? RegionSettings.defaults;
    _country = current.country;
    _region = current.region;
    _language = current.languageCode;
  }

  Future<void> _save() async {
    await ref
        .read(regionProvider.notifier)
        .save(
          RegionSettings(
            countryCode: _country.code,
            region: _region,
            languageCode: _language,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      minChildSize: 0.5,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
        children: [
          Text('Country & language', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'This sets your clinic calendar, emergency number and local '
            'nutrition guidance.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          for (final c in supportedCountries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: PressScale(
                borderRadius: AppRadii.md,
                onTap: () => setState(() {
                  _country = c;
                  _region = null;
                  _language = c.languages.first.code;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _country.code == c.code
                        ? AppColors.limeSoft
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: _country.code == c.code
                          ? AppColors.forest
                          : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_country.code == c.code)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.forest,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (_country.regions.length > 1) ...[
            const SizedBox(height: 12),
            Text('Region', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _country.regions)
                  ChoiceChip(
                    label: Text(r),
                    selected: _region == r,
                    onSelected: (_) => setState(() => _region = r),
                  ),
              ],
            ),
          ],
          if (_country.languages.length > 1) ...[
            const SizedBox(height: 16),
            Text('Language', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in _country.languages)
                  ChoiceChip(
                    label: Text(l.beta ? '${l.label} · soon' : l.label),
                    selected: _language == l.code,
                    onSelected: (_) => setState(() {
                      if (!l.beta) _language = l.code;
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          FilledButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}

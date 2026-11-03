import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/regions.dart';
import '../../core/constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../settings/privacy_info_screen.dart';

/// Onboarding profile + consent. Consent must be explicit (MEST policy):
/// data processing is required to use the app; location-on-urgent and SMS
/// reminders are optional.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _communityController = TextEditingController();
  final _districtController = TextEditingController();
  String? _language;
  bool _consentData = false;
  bool _consentLocation = true;
  bool _consentSms = true;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _communityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please tell us your name')));
      return;
    }
    if (!_consentData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Consent to data processing is needed to use GrowWithMe',
          ),
        ),
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    final region = ref.read(regionProvider).value ?? RegionSettings.defaults;
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'name': _nameController.text.trim(),
        'language': _language ?? region.languageCode,
        'community': _communityController.text.trim(),
        'district': _districtController.text.trim(),
        'region': region.region ?? '',
        'country': region.country.code,
        'consent': {
          'dataProcessing': _consentData,
          'locationOnUrgent': _consentLocation,
          'smsReminders': _consentSms,
        },
      });
      ref.read(authControllerProvider.notifier).signedIn();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = ref.watch(regionProvider).value ?? RegionSettings.defaults;
    final language = _language ?? region.languageCode;
    String? languageLabel;
    for (final l in region.country.languages) {
      if (l.code == language) languageLabel = l.label;
    }
    languageLabel ??= kLanguages[language];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Row(
                children: [
                  Text(
                    'Almost there',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  const ProgressDotBar(count: 3, index: 2, activeWidth: 22),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                children: [
                  Text(
                    'Tell us about\nyour family',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.forestDeep,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps Nana and your care calendar speak to your '
                    'family the right way.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      hintText: 'e.g. Ama Abdulai',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _districtController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'District',
                            hintText: 'e.g. Tamale Metro',
                            prefixIcon: Icon(Icons.map_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _communityController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Community',
                            hintText: 'e.g. Sagnarigu',
                            prefixIcon: Icon(Icons.home_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      prefixIcon: Icon(Icons.translate_rounded),
                    ),
                    items: [
                      for (final l in region.country.languages)
                        if (!l.beta)
                          DropdownMenuItem(value: l.code, child: Text(l.label)),
                      for (final e in kLanguages.entries)
                        if (!region.country.languages.any(
                          (l) => l.code == e.key,
                        ))
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: (v) => setState(() => _language = v),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Text('Your consent', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyInfoScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.shield_outlined, size: 16),
                        label: const Text('Learn more'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _ConsentTile(
                    value: _consentData,
                    onChanged: (v) => setState(() => _consentData = v),
                    title: 'Store my health data securely',
                    subtitle:
                        'Required so the app can remember your family\'s care. '
                        'Encrypted and never sold.',
                    required: true,
                  ),
                  _ConsentTile(
                    value: _consentLocation,
                    onChanged: (v) => setState(() => _consentLocation = v),
                    title: 'Share my location in an emergency',
                    subtitle:
                        'Only when you raise an urgent alert, so a volunteer '
                        'can find you.',
                  ),
                  _ConsentTile(
                    value: _consentSms,
                    onChanged: (v) => setState(() => _consentSms = v),
                    title: 'Send SMS reminders',
                    subtitle:
                        'Gentle texts before clinic visits and immunizations.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Region: ${region.country.flag} ${region.country.name}'
                    '${region.region == null ? '' : ' · ${region.region}'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  if (languageLabel != null)
                    Text(
                      'Language: $languageLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: LimeButton(
                  label: _busy ? 'Setting up your care…' : 'Start caring',
                  icon: _busy ? null : Icons.favorite_rounded,
                  onPressed: _busy ? null : _finish,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    this.required = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        borderRadius: AppRadii.md,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: value ? AppColors.limeSoft : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: value ? AppColors.forest : AppColors.line,
              width: value ? 1.3 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: value ? AppColors.forest : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: value ? AppColors.forest : AppColors.lineStrong,
                  ),
                ),
                child: value
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.lime,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        if (required) ...[
                          const SizedBox(width: 6),
                          const Pill(
                            label: 'REQUIRED',
                            dense: true,
                            foreground: AppColors.forest,
                            background: AppColors.white,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

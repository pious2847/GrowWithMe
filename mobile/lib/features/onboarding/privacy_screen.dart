import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';
import 'profile_screen.dart';

/// Onboarding: how data is protected, in plain spoken-friendly language,
/// BEFORE consent is requested. A "Listen" button reads it aloud.
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  static const _spoken =
      'Before you start, hear how GrowWithMe protects you. '
      'What we keep: your name, phone number, your children and pregnancy '
      'records, and your health check answers. '
      'Your location is shared only in an emergency, so help can find you — '
      'and only if you allow it. '
      'Who can see it: only you, and the health worker who comes to help you '
      'in an emergency. We never sell your information or show it to anyone '
      'else. '
      'Your rights: you can see your information, correct it, or ask us to '
      'delete everything, at any time. '
      'Your data is locked with encryption and protected under Ghana\'s Data '
      'Protection Act. '
      'On the next page you can choose what you allow.';

  @override
  void dispose() {
    ref.read(ttsProvider).stop();
    super.dispose();
  }

  void _continue() {
    ref.read(ttsProvider).stop();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.limeSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.forest,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      const ProgressDotBar(count: 3, index: 2, activeWidth: 12),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Your data is\nprotected',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.forestDeep,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your health information belongs to YOU. Here is exactly '
                    'what we keep and who can see it.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => ref.read(ttsProvider).speak(_spoken),
                      icon: const Icon(Icons.volume_up_rounded, size: 19),
                      label: const Text('Listen to this page'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _Point(
                    icon: Icons.folder_shared_rounded,
                    title: 'What we keep',
                    text:
                        'Your name and phone number, your children and '
                        'pregnancy records, and your health check answers — so '
                        'the app can care for your family.',
                  ),
                  const _Point(
                    icon: Icons.location_on_rounded,
                    title: 'Your location',
                    text:
                        'Shared ONLY during an emergency, so a nurse or '
                        'volunteer can find you quickly — and only if you '
                        'allow it on the next page.',
                  ),
                  const _Point(
                    icon: Icons.visibility_rounded,
                    title: 'Who can see it',
                    text:
                        'Only you — and, in an emergency, the health worker '
                        'coming to help you. We never sell your information or '
                        'give it to anyone else.',
                  ),
                  const _Point(
                    icon: Icons.pan_tool_rounded,
                    title: 'Your rights',
                    text:
                        'You can look at your information, correct it, or ask '
                        'us to delete everything — at any time, no questions '
                        'asked.',
                  ),
                  const _Point(
                    icon: Icons.lock_rounded,
                    title: 'How it is protected',
                    text:
                        'Your data is encrypted and handled under Ghana\'s '
                        'Data Protection Act, 2012 (Act 843), with the same '
                        'care hospitals give medical records.',
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: LimeButton(
                  label: 'I understand — continue',
                  onPressed: _continue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, size: 17, color: AppColors.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    height: 1.42,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

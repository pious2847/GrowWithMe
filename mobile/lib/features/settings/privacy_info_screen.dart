import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_widgets.dart';

class PrivacyInfoScreen extends ConsumerStatefulWidget {
  const PrivacyInfoScreen({super.key});

  @override
  ConsumerState<PrivacyInfoScreen> createState() => _PrivacyInfoScreenState();
}

class _PrivacyInfoScreenState extends ConsumerState<PrivacyInfoScreen> {
  static const _spoken =
      'Your health information belongs to you. We keep only what helps us '
      'care for your family: your name, phone number, children and pregnancy '
      'records, and your health check answers. '
      'Your location is shared only during an emergency, and only if you '
      'allow it. '
      'Only you and the health worker helping you in an emergency can see '
      'your information. We never sell it. '
      'You can see, correct, or delete your information at any time. '
      'Your data is encrypted and protected under Ghana\'s Data Protection '
      'Act.';

  @override
  void dispose() {
    ref.read(ttsProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your data is protected')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          SurfaceCard(
            gradient: AppColors.heroGradient,
            borderColor: AppColors.forest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBubble(
                  icon: Icons.shield_rounded,
                  color: AppColors.lime,
                  size: 46,
                  background: Color(0x22FFFFFF),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your health information\nbelongs to you.',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.cream,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plain words. No surprises.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                LimeButton(
                  label: 'Listen to this page',
                  icon: Icons.volume_up_rounded,
                  onPressed: () => ref.read(ttsProvider).speak(_spoken),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Point(
            icon: Icons.folder_shared_rounded,
            color: AppColors.sky,
            background: AppColors.skySoft,
            title: 'What we keep',
            text:
                'Your name and phone number, your children and pregnancy '
                'records, and your health check answers — so the app can care '
                'for your family.',
          ),
          const _Point(
            icon: Icons.location_on_rounded,
            color: AppColors.coral,
            background: AppColors.coralSoft,
            title: 'Your location',
            text:
                'Shared ONLY during an emergency, so a nurse or volunteer '
                'can find you quickly — and only if you allow it.',
          ),
          const _Point(
            icon: Icons.visibility_rounded,
            color: AppColors.teal,
            background: AppColors.tealSoft,
            title: 'Who can see it',
            text:
                'Only you — and, in an emergency, the health worker coming '
                'to help you. We never sell your information or give it to '
                'anyone else.',
          ),
          const _Point(
            icon: Icons.pan_tool_rounded,
            color: AppColors.violet,
            background: AppColors.violetSoft,
            title: 'Your rights',
            text:
                'You can look at your information, correct it, or ask us to '
                'delete everything — at any time, no questions asked.',
          ),
          const _Point(
            icon: Icons.lock_rounded,
            color: AppColors.amber,
            background: AppColors.amberSoft,
            title: 'How it is protected',
            text:
                'Your data is encrypted and handled under Ghana\'s Data '
                'Protection Act, 2012 (Act 843), with the same care hospitals '
                'give medical records.',
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Questions? privacy@tovolabs.com',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

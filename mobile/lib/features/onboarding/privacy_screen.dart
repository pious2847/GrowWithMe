import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'profile_screen.dart';

/// Onboarding: how her data is protected, in plain spoken-friendly language,
/// BEFORE she is asked to consent on the profile screen. A "Listen" button
/// reads it aloud for caregivers who cannot read.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your data is protected')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Your health information belongs to YOU.',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.read(ttsProvider).speak(_spoken),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Listen to this page'),
                ),
                const SizedBox(height: 16),
                const _Point(
                  icon: Icons.folder_shared,
                  title: 'What we keep',
                  text: 'Your name and phone number, your children and '
                      'pregnancy records, and your health check answers — so '
                      'the app can care for your family.',
                ),
                const _Point(
                  icon: Icons.location_on,
                  title: 'Your location',
                  text: 'Shared ONLY during an emergency, so a nurse or '
                      'volunteer can find you quickly — and only if you '
                      'allow it on the next page.',
                ),
                const _Point(
                  icon: Icons.visibility,
                  title: 'Who can see your information',
                  text: 'Only you — and, in an emergency, the health worker '
                      'coming to help you. We never sell your information or '
                      'give it to anyone else.',
                ),
                const _Point(
                  icon: Icons.pan_tool,
                  title: 'Your rights',
                  text: 'You can look at your information, correct it, or ask '
                      'us to delete everything — at any time, no questions '
                      'asked.',
                ),
                const _Point(
                  icon: Icons.lock,
                  title: 'How it is protected',
                  text: 'Your data is locked with encryption and handled '
                      'under Ghana\'s Data Protection Act, 2012 (Act 843), '
                      'with the same care hospitals give medical records.',
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  ref.read(ttsProvider).stop();
                  Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                },
                child: const Text('I understand — continue'),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

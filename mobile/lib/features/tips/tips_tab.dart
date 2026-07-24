import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/nutrition_tips.dart';

/// Daily, age-appropriate feeding guidance using foods from Northern Ghana
/// markets — fully offline. Shows today's tip per child (and pregnancy), plus
/// the full advice list for each child's age band.
class TipsTab extends ConsumerWidget {
  const TipsTab({super.key});

  int _ageMonths(DateTime dob) => DateTime.now().difference(dob).inDays ~/ 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const [];
    final pregnancies = (ref.watch(pregnanciesProvider).value ?? const [])
        .where((p) => p.status == 'active')
        .toList();

    if (children.isEmpty && pregnancies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Add a child or start pregnancy tracking to get daily feeding tips '
            'with foods from your local market.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        if (pregnancies.isNotEmpty) ...[
          _TodayCard(
            icon: Icons.pregnant_woman,
            heading: 'For you, mother',
            tip: dailyPregnancyTip(),
          ),
          const SizedBox(height: 8),
        ],
        for (final child in children) ...[
          _TodayCard(
            icon: Icons.child_care,
            heading:
                '${child.name} — ${bandForAge(_ageMonths(child.dateOfBirth)).label}',
            tip: dailyChildTip(_ageMonths(child.dateOfBirth)),
          ),
          const SizedBox(height: 4),
          ExpansionTile(
            title: Text('All feeding advice for ${child.name}\'s age'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final tip
                  in bandForAge(_ageMonths(child.dateOfBirth)).tips)
                ListTile(
                  leading: const Icon(Icons.restaurant, size: 20),
                  title: Text(tip.title),
                  subtitle: Text(tip.body),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (pregnancies.isNotEmpty)
          ExpansionTile(
            title: const Text('All pregnancy advice'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final tip in pregnancyTips)
                ListTile(
                  leading: const Icon(Icons.favorite, size: 20),
                  title: Text(tip.title),
                  subtitle: Text(tip.body),
                ),
            ],
          ),
      ],
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard(
      {required this.icon, required this.heading, required this.tip});

  final IconData icon;
  final String heading;
  final NutritionTip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(heading,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Read aloud',
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => ref
                      .read(ttsProvider)
                      .speak('${tip.title}. ${tip.body}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tip.title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(tip.body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/diet_guide.dart';
import '../../domain/nutrition_tips.dart';
import '../diet/diet_screen.dart';

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
        // Nana's Kitchen: meal plans + the Daily Plate tracker
        Card(
          color: Colors.orange.shade50,
          child: ListTile(
            leading: const Text('🍲', style: TextStyle(fontSize: 28)),
            title: const Text('Nana\'s Kitchen',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'Meal plans for your budget · ${seasonLabel(currentSeason())}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DietScreen())),
          ),
        ),
        const SizedBox(height: 8),

        // ---- Today's tips: fresh from Nana's AI when available, library
        // otherwise, with every past day kept below. ----
        Builder(builder: (context) {
          final allTips = ref.watch(dailyTipsProvider).value ?? const [];
          final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final todayTips =
              allTips.where((t) => t.forDay == todayKey).toList();
          if (todayTips.isEmpty) return const SizedBox.shrink();
          return Column(
            children: [
              for (final tip in todayTips) ...[
                _TodayCard(
                  icon: switch (tip.audience) {
                    'pregnancy' => Icons.pregnant_woman,
                    'lactating' => Icons.child_friendly,
                    _ => Icons.child_care,
                  },
                  heading: tip.source == 'ai'
                      ? 'Fresh from Nana today'
                      : 'Today\'s tip',
                  tip: NutritionTip(tip.title, tip.body),
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
        }),
        if ((ref.watch(dailyTipsProvider).value ?? const [])
            .where((t) =>
                t.forDay == DateFormat('yyyy-MM-dd').format(DateTime.now()))
            .isEmpty) ...[
          if (pregnancies.isNotEmpty) ...[
            _TodayCard(
              icon: Icons.pregnant_woman,
              heading: 'For you, mother',
              tip: dailyPregnancyTip(),
            ),
            const SizedBox(height: 8),
          ],
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

        // ---- Past tips: every day's tip stays accessible ----
        Builder(builder: (context) {
          final allTips = ref.watch(dailyTipsProvider).value ?? const [];
          final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final past = allTips.where((t) => t.forDay != todayKey).toList();
          if (past.isEmpty) return const SizedBox.shrink();
          return ExpansionTile(
            leading: const Icon(Icons.history),
            title: Text('Past tips (${past.length})'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final DailyTipRow tip in past.take(30))
                ListTile(
                  leading: Text(
                    switch (tip.audience) {
                      'pregnancy' => '🤰',
                      'lactating' => '🤱',
                      _ => '👶',
                    },
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(tip.title),
                  subtitle: Text(
                      '${DateFormat('EEE d MMM').format(DateTime.parse(tip.forDay))} · ${tip.body}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: () => ref
                        .read(ttsProvider)
                        .speak('${tip.title}. ${tip.body}'),
                  ),
                ),
            ],
          );
        }),
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

import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/care_plan.dart';
import '../../domain/pregnancy_guide.dart';
import '../children/add_child_screen.dart';
import 'checkin_screen.dart';
import 'pregnancy_records_screen.dart';

/// The pregnancy journey card: gestational progress with a local baby-size
/// analogy, last check-in risk badge, the "check-in due" prompt (every 2–3
/// days), week-aware do's & don'ts, the registered hospital, and the
/// "Baby is born" transition into postnatal + newborn care.
class PregnancyCard extends ConsumerWidget {
  const PregnancyCard({super.key, required this.pregnancy});

  final PregnancyRow pregnancy;

  bool get _checkinDue {
    final last = pregnancy.lastCheckinAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 48;
  }

  Future<void> _editHospital(BuildContext context, WidgetRef ref) async {
    final nameController =
        TextEditingController(text: pregnancy.hospitalName ?? '');
    final phoneController =
        TextEditingController(text: pregnancy.hospitalPhone ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('My check-up hospital'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'The hospital or clinic where you do your checks and scans. '
                'If a check-in ever finds a risk, they receive your report.'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Hospital name'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Hospital phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    final db = ref.read(dbProvider);
    await (db.update(db.pregnancies)..where((t) => t.id.equals(pregnancy.id)))
        .write(PregnanciesCompanion(
      hospitalName: Value(nameController.text.trim()),
      hospitalPhone: Value(phoneController.text.trim()),
      clientUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      synced: const Value(false),
    ));
    ref.read(syncControllerProvider.notifier).sync();
  }

  Future<void> _babyBorn(BuildContext context, WidgetRef ref) async {
    final delivered = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
      helpText: 'When was the baby born?',
    );
    if (delivered == null || !context.mounted) return;

    final db = ref.read(dbProvider);
    final now = DateTime.now();
    await db.transaction(() async {
      await (db.update(db.pregnancies)
            ..where((t) => t.id.equals(pregnancy.id)))
          .write(PregnanciesCompanion(
        status: const Value('delivered'),
        deliveredAt: Value(delivered),
        clientUpdatedAt: Value(now.millisecondsSinceEpoch),
        synced: const Value(false),
      ));
      await (db.update(db.reminders)
            ..where((t) =>
                t.pregnancyId.equals(pregnancy.id) &
                t.status.equals('upcoming') &
                t.type.equals('anc')))
          .write(RemindersCompanion(
        status: const Value('done'),
        clientUpdatedAt: Value(now.millisecondsSinceEpoch),
        synced: const Value(false),
      ));
      for (final r in generatePostnatalCarePlan(pregnancy.id, delivered)) {
        await db.into(db.reminders).insert(r);
      }
    });
    ref.read(syncControllerProvider.notifier).sync();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Congratulations! Postnatal visits added to your calendar.')));
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final conception =
        pregnancy.expectedDueDate.subtract(const Duration(days: 280));
    final week = (now.difference(conception).inDays / 7).floor().clamp(1, 42);
    final progress = (week / 40).clamp(0.0, 1.0);
    final daysLeft = pregnancy.expectedDueDate.difference(now).inDays;
    final guide = guidanceForWeek(week);
    final risk = pregnancy.lastRiskLevel;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: Colors.white54,
                      ),
                      Center(
                        child: Text('W$week',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My pregnancy — week $week',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Baby is about the size of ${babySize(week)}'),
                      Text(
                        daysLeft > 0
                            ? '~$daysLeft days to ${DateFormat.MMMMd().format(pregnancy.expectedDueDate)}'
                            : 'Due date passed — stay close to your midwife',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (risk != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: switch (risk) {
                      'urgent' => Colors.red.shade100,
                      'moderate' => Colors.orange.shade100,
                      _ => Colors.green.shade100,
                    },
                    label: Text(
                      switch (risk) {
                        'urgent' => 'High risk',
                        'moderate' => 'Watch',
                        _ => 'All well',
                      },
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: switch (risk) {
                          'urgent' => Colors.red.shade900,
                          'moderate' => Colors.orange.shade900,
                          _ => Colors.green.shade900,
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Check-in: due every 2-3 days, personalized by Nana when online.
            if (_checkinDue)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CheckinScreen(pregnancy: pregnancy))),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Check-in due — how are you feeling?'),
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Checked in ${DateFormat('EEE d MMM').format(pregnancy.lastCheckinAt!)} — next in a few days',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                CheckinScreen(pregnancy: pregnancy))),
                    child: const Text('Check now'),
                  ),
                ],
              ),

            // Week-aware do's and don'ts
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Do\'s & don\'ts for week $week',
                  style: theme.textTheme.titleSmall),
              children: [
                for (final d in guide.dos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✅ '),
                        Expanded(child: Text(d)),
                      ],
                    ),
                  ),
                for (final d in guide.donts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🚫 '),
                        Expanded(child: Text(d)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),

            // Hospital on file — full-width, no cramped link
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.surface,
                ),
                onPressed: () => _editHospital(context, ref),
                icon: const Icon(Icons.local_hospital, size: 20),
                label: Text(
                  pregnancy.hospitalName?.isNotEmpty == true
                      ? pregnancy.hospitalName!
                      : 'Add my check-up hospital',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Records (risk wave) + birth transition, side by side
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: theme.colorScheme.surface,
                    ),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                const PregnancyRecordsScreen())),
                    icon: const Icon(Icons.show_chart, size: 20),
                    label: const Text('My records'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _babyBorn(context, ref),
                    icon: const Icon(Icons.child_friendly, size: 20),
                    label: const Text('Baby is born'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

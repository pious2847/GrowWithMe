import 'package:drift/drift.dart' hide Column, Table;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/care_plan.dart';
import '../children/add_child_screen.dart';

/// Journey card for an active pregnancy: gestational week, progress to the
/// due date, and the "Baby is born" transition — which closes the pregnancy,
/// generates the mother's postnatal calendar, and hands off to adding the
/// newborn (whose own immunization calendar starts at birth).
class PregnancyCard extends ConsumerWidget {
  const PregnancyCard({super.key, required this.pregnancy});

  final PregnancyRow pregnancy;

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
      // Cancel remaining ANC visits; the journey continues as postnatal care.
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
    // Hand off to registering the newborn for their immunization calendar.
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final conception =
        pregnancy.expectedDueDate.subtract(const Duration(days: 280));
    final week = (now.difference(conception).inDays / 7).floor().clamp(1, 42);
    final progress = (week / 40).clamp(0.0, 1.0);
    final daysLeft = pregnancy.expectedDueDate.difference(now).inDays;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pregnant_woman, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('My pregnancy — week $week',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, minHeight: 10),
            ),
            const SizedBox(height: 8),
            Text(
              daysLeft > 0
                  ? 'About $daysLeft days to ${DateFormat.MMMMd().format(pregnancy.expectedDueDate)}'
                  : 'Due date has passed — keep close contact with your midwife',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => _babyBorn(context, ref),
                icon: const Icon(Icons.child_friendly),
                label: const Text('Baby is born'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import 'pregnancy_card.dart';
import 'pregnancy_records_screen.dart';

/// All pregnancy trackers — the current one in full, past (delivered/ended)
/// ones as history, and the ability to remove a tracker entirely (it
/// disappears everywhere along with its scheduled visits, synced).
class PregnanciesScreen extends ConsumerWidget {
  const PregnanciesScreen({super.key});

  Future<void> _delete(
      BuildContext context, WidgetRef ref, PregnancyRow pregnancy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this pregnancy tracker?'),
        content: const Text(
            'The tracker and its scheduled visits will be removed from your '
            'calendar. Your check-in history stays in your records.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(dbProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await (db.update(db.pregnancies)
            ..where((t) => t.id.equals(pregnancy.id)))
          .write(PregnanciesCompanion(
        deleted: const Value(true),
        clientUpdatedAt: Value(now),
        synced: const Value(false),
      ));
      // Its visits leave the calendar too.
      await (db.update(db.reminders)
            ..where((t) => t.pregnancyId.equals(pregnancy.id)))
          .write(RemindersCompanion(
        deleted: const Value(true),
        clientUpdatedAt: Value(now),
        synced: const Value(false),
      ));
    });
    ref.read(syncControllerProvider.notifier).sync();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pregnancy tracker removed')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pregnancies = ref.watch(pregnanciesProvider).value ?? const [];
    final active =
        pregnancies.where((p) => p.status == 'active').toList();
    final past =
        pregnancies.where((p) => p.status != 'active').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My pregnancies')),
      body: pregnancies.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No pregnancy trackers yet.',
                    style: theme.textTheme.bodyLarge),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (active.isNotEmpty) ...[
                  Text('Current', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  for (final p in active) ...[
                    PregnancyCard(pregnancy: p),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _delete(context, ref, p),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        label: const Text('Remove tracker',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Past', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  for (final p in past)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(
                              p.status == 'delivered' ? '👶' : '🤍',
                              style: const TextStyle(fontSize: 20)),
                        ),
                        title: Text(p.status == 'delivered'
                            ? 'Delivered ${p.deliveredAt != null ? DateFormat('d MMM yyyy').format(p.deliveredAt!) : ''}'
                            : 'Ended'),
                        subtitle: Text(
                            'Was due ${DateFormat('d MMM yyyy').format(p.expectedDueDate)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Check-in records',
                              icon: const Icon(Icons.show_chart),
                              onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PregnancyRecordsScreen())),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _delete(context, ref, p),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

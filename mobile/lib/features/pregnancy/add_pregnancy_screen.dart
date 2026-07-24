import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/care_plan.dart';

/// Register a pregnancy from either the last menstrual period (LMP) or a
/// known expected due date. Generates the full ANC visit calendar offline.
class AddPregnancyScreen extends ConsumerStatefulWidget {
  const AddPregnancyScreen({super.key});

  @override
  ConsumerState<AddPregnancyScreen> createState() => _AddPregnancyScreenState();
}

class _AddPregnancyScreenState extends ConsumerState<AddPregnancyScreen> {
  DateTime? _lmp;
  DateTime? _edd;
  bool _busy = false;

  DateTime? get _effectiveEdd =>
      _edd ?? _lmp?.add(const Duration(days: 280));

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 60)),
      firstDate: now.subtract(const Duration(days: 280)),
      lastDate: now,
      helpText: 'First day of your last period',
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  Future<void> _pickEdd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 120)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 280)),
      helpText: 'Expected due date (from your ANC card)',
    );
    if (picked != null) setState(() => _edd = picked);
  }

  Future<void> _save() async {
    final edd = _effectiveEdd;
    if (edd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select your last period date or due date')));
      return;
    }
    setState(() => _busy = true);
    final db = ref.read(dbProvider);
    final pregnancyId = const Uuid().v4();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.into(db.pregnancies).insert(PregnanciesCompanion.insert(
            id: pregnancyId,
            clientUpdatedAt: now.millisecondsSinceEpoch,
            lastMenstrualPeriod: Value(_lmp),
            expectedDueDate: edd,
          ));
      for (final r in generatePregnancyCarePlan(pregnancyId, edd)) {
        await db.into(db.reminders).insert(r);
      }
    });
    ref.read(syncControllerProvider.notifier).sync();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final edd = _effectiveEdd;
    final fmt = DateFormat.yMMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Track my pregnancy')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Tell us one of these and GrowWithMe will build your antenatal '
            'visit calendar and give you weekly guidance.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _pickLmp,
            icon: const Icon(Icons.calendar_today),
            label: Text(_lmp == null
                ? 'First day of last period'
                : 'Last period: ${fmt.format(_lmp!)}'),
          ),
          const SizedBox(height: 8),
          Center(
              child: Text('or',
                  style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickEdd,
            icon: const Icon(Icons.event),
            label: Text(_edd == null
                ? 'Expected due date (from ANC card)'
                : 'Due date: ${fmt.format(_edd!)}'),
          ),
          const SizedBox(height: 24),
          if (edd != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Baby expected around',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Text(fmt.format(edd),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Start tracking'),
          ),
        ],
      ),
    );
  }
}

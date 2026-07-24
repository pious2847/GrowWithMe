import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/care_plan.dart';

class AddChildScreen extends ConsumerStatefulWidget {
  const AddChildScreen({super.key});

  @override
  ConsumerState<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends ConsumerState<AddChildScreen> {
  final _nameController = TextEditingController();
  String? _sex;
  DateTime? _dateOfBirth;
  bool _busy = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      // Children 0-59 months
      firstDate: DateTime(now.year - 5, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and date of birth are required')));
      return;
    }
    setState(() => _busy = true);
    final db = ref.read(dbProvider);
    final childId = const Uuid().v4();
    final now = DateTime.now();

    // Save child + their generated care calendar in one transaction — all
    // offline; sync picks it up whenever a connection exists.
    await db.transaction(() async {
      await db.into(db.children).insert(ChildrenCompanion.insert(
            id: childId,
            clientUpdatedAt: now.millisecondsSinceEpoch,
            name: name,
            sex: Value(_sex),
            dateOfBirth: _dateOfBirth!,
          ));
      for (final reminder in generateChildCarePlan(childId, _dateOfBirth!)) {
        await db.into(db.reminders).insert(reminder);
      }
    });

    // Fire-and-forget: okay to fail offline.
    ref.read(syncControllerProvider.notifier).sync();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add child')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
                labelText: 'Child\'s name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(
                labelText: 'Sex', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'female', child: Text('Girl')),
              DropdownMenuItem(value: 'male', child: Text('Boy')),
            ],
            onChanged: (v) => setState(() => _sex = v),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.cake),
            label: Text(_dateOfBirth == null
                ? 'Date of birth'
                : DateFormat.yMMMMd().format(_dateOfBirth!)),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save child & create care calendar'),
          ),
        ],
      ),
    );
  }
}

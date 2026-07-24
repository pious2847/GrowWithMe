import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';

/// One calendar for the whole care journey — antenatal visits, immunizations,
/// growth checks, postnatal care AND her own personal reminders. Any date can
/// carry a custom alert (title + time → phone notification), added here or by
/// simply asking Nana.
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

Color colorForType(String type) => switch (type) {
      'immunization' => const Color(0xFF1E88E5),
      'growth_monitoring' => const Color(0xFF43A047),
      'vitamin_a' => const Color(0xFFFB8C00),
      'deworming' => const Color(0xFF8E24AA),
      'anc' => const Color(0xFFD81B60),
      'pnc' => const Color(0xFF00897B),
      'custom' => const Color(0xFF3949AB),
      _ => const Color(0xFF757575),
    };

String labelForType(String type) => switch (type) {
      'immunization' => 'Immunization',
      'growth_monitoring' => 'Growth check',
      'vitamin_a' => 'Vitamin A',
      'deworming' => 'Deworming',
      'anc' => 'Antenatal',
      'pnc' => 'Postnatal',
      'custom' => 'My reminder',
      _ => 'Visit',
    };

String emojiForType(String type) => switch (type) {
      'immunization' => '💉',
      'growth_monitoring' => '⚖️',
      'vitamin_a' => '💊',
      'deworming' => '💊',
      'anc' => '🤰',
      'pnc' => '👶',
      'custom' => '🔔',
      _ => '🗓️',
    };

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _addReminder() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddReminderSheet(day: _selectedDay),
    );
    if (result == null) return;

    final time = result['time'] as TimeOfDay;
    final when = DateTime(_selectedDay.year, _selectedDay.month,
        _selectedDay.day, time.hour, time.minute);
    final id = await ref.read(careActionsProvider).addCustomReminder(
          title: result['title'] as String,
          when: when,
          note: result['note'] as String?,
        );
    await ref.read(notificationServiceProvider).schedule(
          reminderId: id,
          title: 'GrowWithMe reminder',
          body: result['title'] as String,
          when: when,
        );
    ref.read(syncControllerProvider.notifier).sync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Reminder set for ${DateFormat('EEE d MMM').format(when)} at ${DateFormat.jm().format(when)} 🔔')));
  }

  Future<void> _deleteCustom(ReminderRow r) async {
    final db = ref.read(dbProvider);
    await (db.update(db.reminders)..where((t) => t.id.equals(r.id)))
        .write(RemindersCompanion(
      deleted: const Value(true),
      clientUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      synced: const Value(false),
    ));
    await ref.read(notificationServiceProvider).cancel(r.id);
    ref.read(syncControllerProvider.notifier).sync();
  }

  Future<void> _markDone(ReminderRow r) async {
    final db = ref.read(dbProvider);
    await (db.update(db.reminders)..where((t) => t.id.equals(r.id)))
        .write(RemindersCompanion(
      status: const Value('done'),
      completedAt: Value(DateTime.now()),
      clientUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      synced: const Value(false),
    ));
    ref.read(syncControllerProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = ref.watch(allRemindersProvider).value ?? const [];
    final byDay = <DateTime, List<ReminderRow>>{};
    for (final r in reminders) {
      (byDay[_dayKey(r.dueDate)] ??= []).add(r);
    }
    final selectedEvents = (byDay[_dayKey(_selectedDay)] ?? const [])
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final monthCount = reminders
        .where((r) =>
            r.dueDate.year == _focusedDay.year &&
            r.dueDate.month == _focusedDay.month)
        .length;

    return Column(
      children: [
        // ---- Gradient month header ----
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, const Color(0xFF1B5E20)],
            ),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20), bottom: Radius.circular(6)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () => setState(() => _focusedDay = DateTime(
                    _focusedDay.year, _focusedDay.month - 1, 1)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_focusedDay),
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      monthCount == 0
                          ? 'No visits this month'
                          : '$monthCount visit${monthCount == 1 ? '' : 's'} & reminders',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () => setState(() => _focusedDay = DateTime(
                    _focusedDay.year, _focusedDay.month + 1, 1)),
              ),
            ],
          ),
        ),

        // ---- Calendar grid ----
        Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(6), bottom: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TableCalendar<ReminderRow>(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
              focusedDay: _focusedDay,
              headerVisible: false,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
              startingDayOfWeek: StartingDayOfWeek.monday,
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant),
                weekendStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle:
                    TextStyle(color: theme.colorScheme.primary),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 4,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  return Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final e in events.take(4))
                          Container(
                            width: 6,
                            height: 6,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: colorForType(e.type),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              }),
              onPageChanged: (focused) =>
                  setState(() => _focusedDay = focused),
            ),
          ),
        ),

        // ---- Legend ----
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final t in const [
                'custom',
                'anc',
                'pnc',
                'immunization',
                'growth_monitoring',
                'vitamin_a',
                'deworming'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: colorForType(t), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(labelForType(t),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ---- Selected day ----
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isSameDay(_selectedDay, DateTime.now())
                      ? 'Today, ${DateFormat('d MMMM').format(_selectedDay)}'
                      : DateFormat('EEEE, d MMMM').format(_selectedDay),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addReminder,
                icon: const Icon(Icons.add_alert, size: 18),
                label: const Text('Remind me'),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(
                        'Nothing on this day.\nTap "Remind me" to add your own alert.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  children: [
                    for (final r in selectedEvents)
                      _EventTile(
                        reminder: r,
                        onDone: () => _markDone(r),
                        onDelete:
                            r.type == 'custom' ? () => _deleteCustom(r) : null,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile(
      {required this.reminder, required this.onDone, this.onDelete});

  final ReminderRow reminder;
  final VoidCallback onDone;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = reminder.status == 'done';
    final missed = reminder.status == 'missed';
    final isCustom = reminder.type == 'custom';
    final hasTime =
        reminder.dueDate.hour != 0 || reminder.dueDate.minute != 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorForType(reminder.type).withValues(alpha: 0.15),
          child: Text(emojiForType(reminder.type),
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          reminder.title,
          style: done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          [
            if (hasTime) DateFormat.jm().format(reminder.dueDate),
            done
                ? 'Done'
                : missed
                    ? 'Missed — go for catch-up'
                    : labelForType(reminder.type),
            if (reminder.description?.isNotEmpty == true)
              reminder.description!,
          ].join(' · '),
          style: TextStyle(color: missed ? Colors.orange.shade800 : null),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (done)
              const Icon(Icons.check_circle, color: Colors.green)
            else
              IconButton(
                tooltip: 'Mark done',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: onDone,
              ),
            if (isCustom && onDelete != null)
              IconButton(
                tooltip: 'Remove reminder',
                icon: Icon(Icons.delete_outline,
                    color: theme.colorScheme.onSurfaceVariant, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet({required this.day});

  final DateTime day;

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('🔔 Remind me on ${DateFormat('EEE, d MMMM').format(widget.day)}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'What should I remind you about?',
                  hintText: 'e.g. Buy ORS at the market',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final picked = await showTimePicker(
                      context: context, initialTime: _time);
                  if (picked != null) setState(() => _time = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 10),
                      Text('At ${_time.format(context)}',
                          style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Text('Change',
                          style:
                              TextStyle(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(context, {
                      'title': title,
                      'time': _time,
                      'note': _noteController.text.trim().isEmpty
                          ? null
                          : _noteController.text.trim(),
                    });
                  },
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Set reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

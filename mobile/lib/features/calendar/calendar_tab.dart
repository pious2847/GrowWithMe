import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';

/// One calendar for the whole care journey: antenatal visits during
/// pregnancy, then immunizations, growth checks, Vitamin A, deworming and
/// postnatal care after birth. Colored dots mark event types; tapping a day
/// lists its visits, which can be marked done in place.
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
      _ => const Color(0xFF757575),
    };

String labelForType(String type) => switch (type) {
      'immunization' => 'Immunization',
      'growth_monitoring' => 'Growth check',
      'vitamin_a' => 'Vitamin A',
      'deworming' => 'Deworming',
      'anc' => 'Antenatal',
      'pnc' => 'Postnatal',
      _ => 'Visit',
    };

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final reminders = ref.watch(allRemindersProvider).value ?? const [];
    final byDay = <DateTime, List<ReminderRow>>{};
    for (final r in reminders) {
      (byDay[_dayKey(r.dueDate)] ??= []).add(r);
    }
    final selectedEvents = byDay[_dayKey(_selectedDay)] ?? const [];

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TableCalendar<ReminderRow>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365 * 5)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => byDay[_dayKey(day)] ?? const [],
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 4,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final e in events.take(4))
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: colorForType(e.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                );
              },
            ),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => _focusedDay = focused,
          ),
        ),
        _Legend(),
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Text(
                    'No visits on ${DateFormat.yMMMd().format(_selectedDay)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                  children: [
                    for (final r in selectedEvents) _EventTile(reminder: r),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  static const _types = [
    'anc',
    'pnc',
    'immunization',
    'growth_monitoring',
    'vitamin_a',
    'deworming'
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final t in _types)
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
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.reminder});

  final ReminderRow reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final done = reminder.status == 'done';
    final missed = reminder.status == 'missed';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 6,
          backgroundColor: colorForType(reminder.type),
        ),
        title: Text(
          reminder.title,
          style: done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          done
              ? 'Done'
              : missed
                  ? 'Missed — go for catch-up'
                  : labelForType(reminder.type),
          style: TextStyle(color: missed ? Colors.orange.shade800 : null),
        ),
        trailing: done
            ? const Icon(Icons.check_circle, color: Colors.green)
            : IconButton(
                tooltip: 'Mark done',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () async {
                  await (db.update(db.reminders)
                        ..where((t) => t.id.equals(reminder.id)))
                      .write(RemindersCompanion(
                    status: const Value('done'),
                    completedAt: Value(DateTime.now()),
                    clientUpdatedAt:
                        Value(DateTime.now().millisecondsSinceEpoch),
                    synced: const Value(false),
                  ));
                  ref.read(syncControllerProvider.notifier).sync();
                },
              ),
      ),
    );
  }
}

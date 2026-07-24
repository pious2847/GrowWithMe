import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';

const _uuid = Uuid();

class _PlanItem {
  const _PlanItem(this.daysFromBirth, this.type, this.title);

  final int daysFromBirth;
  final String type;
  final String title;
}

// Ghana EPI immunization schedule (simplified) + Vitamin A and growth checks.
const _childSchedule = <_PlanItem>[
  _PlanItem(0, 'immunization', 'BCG + OPV 0 (at birth)'),
  _PlanItem(42, 'immunization', 'OPV 1, Penta 1, PCV 1, Rota 1 (6 weeks)'),
  _PlanItem(70, 'immunization', 'OPV 2, Penta 2, PCV 2, Rota 2 (10 weeks)'),
  _PlanItem(98, 'immunization', 'OPV 3, Penta 3, PCV 3 (14 weeks)'),
  _PlanItem(180, 'vitamin_a', 'Vitamin A dose (6 months)'),
  _PlanItem(270, 'immunization', 'Measles-Rubella 1 + Yellow Fever (9 months)'),
  _PlanItem(365, 'vitamin_a', 'Vitamin A dose (12 months)'),
  _PlanItem(365, 'deworming', 'Deworming (12 months)'),
  _PlanItem(540, 'immunization', 'Measles-Rubella 2 + MenA (18 months)'),
  _PlanItem(540, 'deworming', 'Deworming (18 months)'),
];

/// Generates the offline care calendar for a child from their date of birth.
/// Only future items (and those due within the last 30 days, still worth
/// catching up on) are created. Monthly growth monitoring runs to 24 months.
List<RemindersCompanion> generateChildCarePlan(String childId, DateTime dateOfBirth) {
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 30));
  final items = <RemindersCompanion>[];

  void add(DateTime due, String type, String title, [String? description]) {
    if (due.isBefore(cutoff)) return;
    items.add(RemindersCompanion.insert(
      id: _uuid.v4(),
      clientUpdatedAt: now.millisecondsSinceEpoch,
      childId: Value(childId),
      type: type,
      title: title,
      description: Value(description),
      dueDate: due,
    ));
  }

  for (final item in _childSchedule) {
    add(dateOfBirth.add(Duration(days: item.daysFromBirth)), item.type, item.title);
  }
  for (var month = 1; month <= 24; month++) {
    add(
      DateTime(dateOfBirth.year, dateOfBirth.month + month, dateOfBirth.day),
      'growth_monitoring',
      'Weighing & growth check (month $month)',
    );
  }

  items.sort((a, b) => a.dueDate.value.compareTo(b.dueDate.value));
  return items;
}

/// Postnatal care for the mother after delivery: WHO-recommended PNC contacts
/// plus a family-planning counselling reminder.
List<RemindersCompanion> generatePostnatalCarePlan(
    String pregnancyId, DateTime deliveryDate) {
  final now = DateTime.now();
  const contacts = [
    (days: 3, title: 'Postnatal check for mother & baby (day 3)'),
    (days: 7, title: 'Postnatal check for mother & baby (day 7)'),
    (days: 14, title: 'Postnatal check (week 2)'),
    (days: 42, title: 'Postnatal check & family planning talk (week 6)'),
  ];
  return [
    for (final c in contacts)
      RemindersCompanion.insert(
        id: _uuid.v4(),
        clientUpdatedAt: now.millisecondsSinceEpoch,
        pregnancyId: Value(pregnancyId),
        type: 'pnc',
        title: c.title,
        dueDate: deliveryDate.add(Duration(days: c.days)),
      ),
  ];
}

/// ANC contact schedule (simplified WHO 8-contact model) from the expected due
/// date, assuming a 280-day term.
List<RemindersCompanion> generatePregnancyCarePlan(
    String pregnancyId, DateTime expectedDueDate) {
  final now = DateTime.now();
  final conception = expectedDueDate.subtract(const Duration(days: 280));
  const contactWeeks = [12, 20, 26, 30, 34, 36, 38, 40];
  final items = <RemindersCompanion>[];

  for (var i = 0; i < contactWeeks.length; i++) {
    final due = conception.add(Duration(days: contactWeeks[i] * 7));
    if (due.isBefore(now.subtract(const Duration(days: 14)))) continue;
    items.add(RemindersCompanion.insert(
      id: _uuid.v4(),
      clientUpdatedAt: now.millisecondsSinceEpoch,
      pregnancyId: Value(pregnancyId),
      type: 'anc',
      title: 'Antenatal visit ${i + 1} (week ${contactWeeks[i]})',
      dueDate: due,
    ));
  }
  return items;
}

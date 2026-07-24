import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/growth_reference.dart';
import '../../domain/nutrition_tips.dart';
import '../assessment/assessment_screen.dart';

/// A child's health page: WHO growth chart with offline malnutrition
/// screening, weight logging from weighing visits, today's feeding tip, and
/// a shortcut into the symptom check.
class ChildDetailScreen extends ConsumerWidget {
  const ChildDetailScreen({super.key, required this.child});

  final ChildRow child;

  double _ageMonthsAt(DateTime when) =>
      when.difference(child.dateOfBirth).inDays / 30.44;

  Future<void> _addWeight(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final weight = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Weight for ${child.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight in kg (from the scale)',
            hintText: 'e.g. 7.4',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (weight == null || weight <= 0 || weight > 40) return;

    final db = ref.read(dbProvider);
    await db.into(db.growthRecords).insert(GrowthRecordsCompanion.insert(
          id: const Uuid().v4(),
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          childId: child.id,
          weightKg: weight,
          measuredAt: DateTime.now(),
        ));
    ref.read(syncControllerProvider.notifier).sync();

    if (!context.mounted) return;
    final result = assessWeight(weight, _ageMonthsAt(DateTime.now()), child.sex);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.message),
      duration: const Duration(seconds: 6),
      backgroundColor: switch (result.status) {
        GrowthStatus.healthy => Colors.green.shade700,
        GrowthStatus.underweight => Colors.orange.shade800,
        GrowthStatus.severelyUnderweight => Colors.red.shade700,
      },
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(growthRecordsProvider(child.id)).value ??
        const <GrowthRecordRow>[];
    final ageMonths = _ageMonthsAt(DateTime.now());
    final latest = records.isNotEmpty ? records.last : null;
    final latestAssessment = latest == null
        ? null
        : assessWeight(
            latest.weightKg, _ageMonthsAt(latest.measuredAt), child.sex);
    final tip = dailyChildTip(ageMonths.floor());

    return Scaffold(
      appBar: AppBar(title: Text(child.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                  radius: 24, child: Text(child.name.characters.first)),
              title: Text(child.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${child.sex == 'female' ? 'Girl' : 'Boy'} · ${ageMonths.floor()} months · born ${DateFormat.yMMMd().format(child.dateOfBirth)}'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Growth', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => _addWeight(context, ref),
                icon: const Icon(Icons.monitor_weight, size: 18),
                label: const Text('Add weight'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latestAssessment != null)
            Card(
              color: switch (latestAssessment.status) {
                GrowthStatus.healthy => Colors.green.shade50,
                GrowthStatus.underweight => Colors.orange.shade50,
                GrowthStatus.severelyUnderweight => Colors.red.shade50,
              },
              child: ListTile(
                leading: Icon(
                  switch (latestAssessment.status) {
                    GrowthStatus.healthy => Icons.check_circle,
                    GrowthStatus.underweight => Icons.warning_amber,
                    GrowthStatus.severelyUnderweight => Icons.emergency,
                  },
                  color: switch (latestAssessment.status) {
                    GrowthStatus.healthy => Colors.green.shade700,
                    GrowthStatus.underweight => Colors.orange.shade800,
                    GrowthStatus.severelyUnderweight => Colors.red.shade700,
                  },
                ),
                title: Text(
                    'Last weight: ${latest!.weightKg.toStringAsFixed(1)} kg'),
                subtitle: Text(latestAssessment.message),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: SizedBox(
                height: 220,
                child: records.isEmpty
                    ? Center(
                        child: Text(
                          'Add the weight from each weighing visit to see '
                          '${child.name}\'s growth against the healthy range.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : _GrowthChart(child: child, records: records),
              ),
            ),
          ),
          if (records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Green band: healthy range (WHO). Below the orange line means '
                'underweight — screening only, the clinic confirms.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          Text('Today\'s feeding tip',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(tip.title),
              subtitle: Text(tip.body),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    AssessmentScreen(subjectType: 'child', childId: child.id))),
            icon: const Icon(Icons.health_and_safety),
            label: Text('Check ${child.name}\'s symptoms'),
          ),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({required this.child, required this.records});

  final ChildRow child;
  final List<GrowthRecordRow> records;

  @override
  Widget build(BuildContext context) {
    final maxAge = [
      12.0,
      ...records.map((r) =>
          r.measuredAt.difference(child.dateOfBirth).inDays / 30.44 + 2),
    ].reduce((a, b) => a > b ? a : b).clamp(6.0, 60.0);

    List<FlSpot> curve(double Function(double age, String? sex) f) => [
          for (double m = 0; m <= maxAge; m += maxAge / 24)
            FlSpot(m, f(m, child.sex)),
        ];

    final points = [
      for (final r in records)
        FlSpot(
          r.measuredAt.difference(child.dateOfBirth).inDays / 30.44,
          r.weightKg,
        ),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxAge,
        minY: 0,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Age (months)'),
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxAge <= 15 ? 3 : 12,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                  style: const TextStyle(fontSize: 10)),
            ),
          ),
        ),
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Healthy median
          LineChartBarData(
            spots: curve(medianWeight),
            color: Colors.green.shade400,
            dotData: const FlDotData(show: false),
            barWidth: 2,
          ),
          // Underweight threshold (-2SD)
          LineChartBarData(
            spots: curve(minus2sdWeight),
            color: Colors.orange.shade600,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
            barWidth: 2,
          ),
          // Severe threshold (-3SD)
          LineChartBarData(
            spots: curve(minus3sdWeight),
            color: Colors.red.shade400,
            dashArray: [3, 4],
            dotData: const FlDotData(show: false),
            barWidth: 1.5,
          ),
          // The child's actual weights
          LineChartBarData(
            spots: points,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isCurved: false,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

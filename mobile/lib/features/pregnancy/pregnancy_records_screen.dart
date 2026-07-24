import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';

double _riskY(String risk) => switch (risk) {
      'urgent' => 3,
      'moderate' => 2,
      _ => 1,
    };

Color _riskColor(String risk) => switch (risk) {
      'urgent' => const Color(0xFFD32F2F),
      'moderate' => const Color(0xFFF57C00),
      _ => const Color(0xFF2E7D32),
    };

String _riskLabel(String risk) => switch (risk) {
      'urgent' => 'High risk',
      'moderate' => 'Watch',
      _ => 'All well',
    };

/// The pregnancy health record: a "risk wave" of every check-in and health
/// check over time, plus the full assessment history — the picture a midwife
/// wants to see at a glance.
class PregnancyRecordsScreen extends ConsumerWidget {
  const PregnancyRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final records = ref.watch(pregnancyAssessmentsProvider).value ??
        const <AssessmentRow>[];

    return Scaffold(
      appBar: AppBar(title: const Text('My pregnancy record')),
      body: records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No check-ins yet. Your risk chart will grow here with every '
                  'check-in — do one every few days and Nana will watch the '
                  'pattern with you.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ---- Risk wave ----
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text('Risk over time',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: LineChart(
                            LineChartData(
                              minY: 0.5,
                              maxY: 3.5,
                              minX: 0,
                              maxX: (records.length - 1)
                                  .toDouble()
                                  .clamp(1, double.infinity),
                              gridData: FlGridData(
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (v) => FlLine(
                                  color: theme.colorScheme.outlineVariant,
                                  strokeWidth: 0.6,
                                  dashArray: [4, 4],
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(),
                                rightTitles: const AxisTitles(),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 1,
                                    reservedSize: 52,
                                    getTitlesWidget: (v, meta) =>
                                        switch (v.toInt()) {
                                      3 => const Text('High',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFD32F2F),
                                              fontWeight: FontWeight.bold)),
                                      2 => const Text('Watch',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFF57C00))),
                                      1 => const Text('Well',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF2E7D32))),
                                      _ => const SizedBox.shrink(),
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: (records.length / 4)
                                        .ceilToDouble()
                                        .clamp(1, 100),
                                    getTitlesWidget: (v, meta) {
                                      final i = v.toInt();
                                      if (i < 0 || i >= records.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          DateFormat('d MMM').format(
                                              records[i].completedAt),
                                          style:
                                              const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var i = 0; i < records.length; i++)
                                      FlSpot(i.toDouble(),
                                          _riskY(records[i].riskLevel)),
                                  ],
                                  isCurved: true,
                                  preventCurveOverShooting: true,
                                  barWidth: 3,
                                  color: theme.colorScheme.primary,
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        theme.colorScheme.primary
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, _, _, i) =>
                                        FlDotCirclePainter(
                                      radius: 5,
                                      color: _riskColor(
                                          records[spot.x.toInt()].riskLevel),
                                      strokeWidth: 2,
                                      strokeColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ---- History list ----
                Text('All check-ins & health checks',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final r in records.reversed)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 8,
                        backgroundColor: _riskColor(r.riskLevel),
                      ),
                      title: Text(
                          '${_riskLabel(r.riskLevel)} — ${DateFormat('EEE d MMM, HH:mm').format(r.completedAt)}'),
                      subtitle: Builder(builder: (context) {
                        List<dynamic> signs = const [];
                        try {
                          signs = jsonDecode(r.dangerSignsJson) as List;
                        } catch (_) {}
                        return Text(signs.isEmpty
                            ? 'No signs reported'
                            : signs.join(' · '));
                      }),
                    ),
                  ),
              ],
            ),
    );
  }
}

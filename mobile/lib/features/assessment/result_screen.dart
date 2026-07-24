import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../../domain/triage/triage_engine.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.assessmentId,
    required this.synced,
  });

  final TriageResult result;
  final String assessmentId;
  final bool synced;

  Color _color(BuildContext context) => switch (result.riskLevel) {
        'urgent' => Colors.red.shade700,
        'moderate' => Colors.orange.shade800,
        _ => Colors.green.shade700,
      };

  String _title() => switch (result.riskLevel) {
        'urgent' => 'URGENT — get help now',
        'moderate' => 'Visit a clinic within 24 hours',
        _ => 'No danger signs found',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider).value ?? const [];
    final alert =
        alerts.where((a) => a.assessmentId == assessmentId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (result.riskLevel == 'urgent')
            Lottie.asset('assets/lottie/alert_pulse.json',
                height: 160, repeat: true)
          else if (result.riskLevel == 'low')
            Lottie.asset('assets/lottie/success_check.json',
                height: 160, repeat: false)
          else
            Lottie.asset('assets/lottie/health_check.json',
                height: 160, repeat: false),
          const SizedBox(height: 8),
          Card(
            color: _color(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _title(),
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result.dangerSigns.isNotEmpty) ...[
            Text('Signs found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final sign in result.dangerSigns)
              ListTile(
                dense: true,
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(sign),
              ),
            const SizedBox(height: 16),
          ],
          Text('What to do', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(result.guidance, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (result.riskLevel == 'urgent')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          synced ? Icons.check_circle : Icons.cloud_off,
                          color: synced ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            synced
                                ? 'Alert sent to the nearest volunteer and facility.'
                                : 'No connection right now — the alert will be sent '
                                    'automatically as soon as you are online. '
                                    'Do not wait: start moving to the nearest facility.',
                          ),
                        ),
                      ],
                    ),
                    if (alert != null) ...[
                      const Divider(),
                      if (alert.volunteerName != null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.person_pin_circle),
                          title: Text('Volunteer: ${alert.volunteerName}'),
                          subtitle: Text(alert.volunteerPhone ?? ''),
                        ),
                      if (alert.facilityName != null)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.local_hospital),
                          title: Text('Facility: ${alert.facilityName}'),
                          subtitle: Text(alert.facilityPhone ?? ''),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../../domain/first_aid.dart';
import '../../domain/triage/triage_engine.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({
    super.key,
    required this.result,
    required this.assessmentId,
    required this.synced,
  });

  final TriageResult result;
  final String assessmentId;
  final bool synced;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  TriageResult get result => widget.result;
  String get assessmentId => widget.assessmentId;
  bool get synced => widget.synced;

  @override
  void initState() {
    super.initState();
    // Urgent guidance is ALWAYS spoken — a caregiver who cannot read must
    // still hear what to do. Other levels speak only in voice mode.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final autoVoice = ref.read(autoVoiceProvider).value ?? false;
      if (result.riskLevel == 'urgent' || autoVoice) {
        ref.read(ttsProvider).speak('${_title()}. ${result.guidance}');
      }
    });
  }

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
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Text('What to do', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => ref.read(ttsProvider).speak(result.guidance),
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Listen'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(result.guidance, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (result.riskLevel == 'urgent') ...[
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.healing, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('While help comes — do this now',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          tooltip: 'Read aloud',
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => ref
                              .read(ttsProvider)
                              .speak(firstAidSpeech(result.dangerSigns)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final step in firstAidFor(result.dangerSigns))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.emoji,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(step.text,
                                    style: const TextStyle(height: 1.3))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
          const SizedBox(height: 16),
          // The check is automated and fallible — never let a reassuring
          // result talk a worried caregiver out of seeking care.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 20, color: Colors.blueGrey.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This result comes from the app\'s automated health check, '
                    'which can make mistakes. It does not replace a health '
                    'worker. If you are worried, go to a clinic — even if the '
                    'result looks fine.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.blueGrey.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

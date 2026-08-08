import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/model_service.dart';
import '../../core/offline_cache.dart';
import 'assess_vitals_screen.dart';

/// Live case view: danger signs, patient contact, risk report, and the big
/// action flow Accept → En route → At facility → Close. Accepting an
/// unassigned case claims it (the mother gets a "help is coming" SMS).
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({super.key, required this.alertId, this.myPosition});

  final String alertId;
  final Position? myPosition;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  Map<String, dynamic>? _alert;
  String? _error;
  bool _acting = false;
  // True when showing the last saved copy because we are offline.
  bool _fromCache = false;

  // The next step for each status, in referral-loop order.
  static const _next = {
    'pending': ('acknowledged', 'Accept this case', Icons.check_circle),
    'notified': ('acknowledged', 'Accept this case', Icons.check_circle),
    'unassigned': ('acknowledged', 'Accept this case', Icons.check_circle),
    'acknowledged': ('en_route', 'I am on my way', Icons.directions_run),
    'en_route': ('at_facility', 'We reached the facility', Icons.local_hospital),
    'at_facility': ('closed', 'Close the case', Icons.task_alt),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api.I.dio.get('/alerts/${widget.alertId}');
      if (!mounted) return;
      setState(() {
        _alert = res.data['alert'] as Map<String, dynamic>;
        _error = null;
        _fromCache = false;
      });
      OfflineCache.put('alert_${widget.alertId}', _alert!);
    } catch (_) {
      // Offline: show the last saved version of this case so the responder
      // keeps the address, phone number and danger signs in the field.
      final cached = await OfflineCache.get('alert_${widget.alertId}')
          as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        if (cached != null) {
          _alert = cached;
          _fromCache = true;
          _error = null;
        } else {
          _error =
              'Could not load this case. It may have been closed, or you are offline.';
        }
      });
    }
  }

  Future<void> _advance(String status) async {
    setState(() => _acting = true);
    try {
      await Api.I.dio
          .patch('/alerts/${widget.alertId}/status', data: {'status': status});
      // The PATCH response carries unpopulated references (plain IDs) —
      // refetch so caregiver/facility/assessment stay full objects.
      await _load();
      if (!mounted) return;
      if (status == 'acknowledged') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Case accepted. The caregiver was told help is coming.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update the case. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _navigate(List coords) async {
    // Turn-by-turn happens in the Google Maps app via a free deep link.
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alert = _alert;
    return Scaffold(
      appBar: AppBar(title: const Text('Urgent case')),
      body: alert == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          OutlinedButton(
                              onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_fromCache)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_off,
                              size: 16, color: Colors.orange.shade900),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline — showing the last saved copy. Status '
                              'updates will work once you are back online.',
                              style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ..._buildBody(theme, alert),
                ],
              ),
            ),
      bottomNavigationBar: alert == null ? null : _buildActionBar(alert),
    );
  }

  /// Populated references are Maps; unpopulated ones are plain ID strings —
  /// treat anything that isn't a Map as absent instead of crashing.
  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  List<Widget> _buildBody(ThemeData theme, Map<String, dynamic> alert) {
    final caregiver = _asMap(alert['caregiver']);
    final assessment = _asMap(alert['assessment']);
    final dangerSigns =
        ((assessment?['dangerSigns'] as List?) ?? []).cast<String>();
    final coords = (alert['location'] as Map?)?['coordinates'] as List?;
    final reportUrl = alert['reportUrl'] as String?;
    final status = alert['status'] as String? ?? 'pending';
    final timeline =
        ((alert['timeline'] as List?) ?? []).cast<Map<String, dynamic>>();

    String? distanceText;
    if (coords != null && coords.length == 2 && widget.myPosition != null) {
      final meters = Geolocator.distanceBetween(
          widget.myPosition!.latitude,
          widget.myPosition!.longitude,
          (coords[1] as num).toDouble(),
          (coords[0] as num).toDouble());
      distanceText = meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km away'
          : '${meters.round()} m away';
    }

    return [
      // Status + summary
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text(status.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (distanceText != null)
                  Text(distanceText,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert['summary'] as String? ?? '',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Danger signs from the app's automated screening
      if (dangerSigns.isNotEmpty) ...[
        Text('Danger signs reported',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final sign in dangerSigns)
              Chip(
                label: Text(sign),
                backgroundColor: Colors.red.shade50,
                side: BorderSide(color: Colors.red.shade200),
                labelStyle: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Screened automatically by the GrowWithMe app — it can make '
          'mistakes. Assess the patient yourself and use your own judgment.',
          style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
      ],

      // Patient contact
      if (caregiver != null)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(caregiver['name'] as String? ?? 'Caregiver'),
            subtitle: Text([
              caregiver['phone'],
              caregiver['community'],
            ].whereType<String>().join(' · ')),
            trailing: caregiver['phone'] is String
                ? IconButton.filled(
                    tooltip: 'Call',
                    onPressed: () => _call(caregiver['phone'] as String),
                    icon: const Icon(Icons.call),
                  )
                : null,
          ),
        ),
      const SizedBox(height: 8),

      // Report + navigate
      Row(
        children: [
          if (reportUrl != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => launchUrl(Uri.parse(reportUrl),
                    mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.description),
                label: const Text('Risk report'),
              ),
            ),
          if (reportUrl != null && coords != null) const SizedBox(width: 8),
          if (coords != null && coords.length == 2)
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _navigate(coords),
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate'),
              ),
            ),
        ],
      ),
      // Offline AI vitals assessment — only offered once the on-device model
      // has been downloaded and verified; works with zero connectivity.
      if (ModelService.I.ready) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AssessVitalsScreen(
                  patientName: caregiver?['name'] as String?,
                  alertId: widget.alertId))),
          icon: const Icon(Icons.monitor_heart),
          label: const Text('Assess vitals (offline AI)'),
        ),
      ],
      const SizedBox(height: 18),

      // Timeline
      if (timeline.isNotEmpty) ...[
        Text('Timeline',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        for (final entry in timeline.reversed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${(entry['event'] as String? ?? '').replaceAll('_', ' ')}'
                    '${entry['note'] is String ? ' — ${entry['note']}' : ''}',
                  ),
                ),
                if (entry['at'] is String)
                  Text(
                    _time(entry['at'] as String),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
      ],
      const SizedBox(height: 90),
    ];
  }

  Widget? _buildActionBar(Map<String, dynamic> alert) {
    final status = alert['status'] as String? ?? 'pending';
    final next = _next[status];
    if (next == null) return null; // closed
    final (nextStatus, label, icon) = next;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18)),
          onPressed: _acting ? null : () => _advance(nextStatus),
          icon: _acting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon),
          label: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

String _time(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return '';
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

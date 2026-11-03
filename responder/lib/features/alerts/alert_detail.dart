import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/attention.dart';
import '../../core/model_service.dart';
import '../../core/offline_cache.dart';
import '../../core/pending_actions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/triage.dart';
import '../../core/ui/app_widgets.dart';
import 'assess_vitals_screen.dart';

/// Live case command view: severity, danger signs, patient contact, referral
/// facility and the Accept → En route → At facility → Close loop. Works
/// offline: status changes and notes are queued and replayed automatically.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.alertId,
    this.myPosition,
  });

  final String alertId;
  final Position? myPosition;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  Map<String, dynamic>? _alert;
  String? _error;
  bool _acting = false;
  bool _fromCache = false;
  bool _queued = false;

  static const _flow = ['acknowledged', 'en_route', 'at_facility', 'closed'];

  /// Compact so "Risk report" and "Protocol" stay on one line side by side.
  static final ButtonStyle _referralButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    textStyle: const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
    ),
  );

  // The next step for each status, in referral-loop order.
  static const _next = {
    'pending': ('acknowledged', 'Accept this case', Icons.check_circle_rounded),
    'notified': ('acknowledged', 'Accept this case', Icons.check_circle_rounded),
    'unassigned': ('acknowledged', 'Accept this case', Icons.check_circle_rounded),
    'acknowledged': ('en_route', 'I am on my way', Icons.directions_run_rounded),
    'en_route': ('at_facility', 'We reached the facility', Icons.local_hospital_rounded),
    'at_facility': ('closed', 'Close the case', Icons.task_alt_rounded),
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
        _queued = false;
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
          _error = 'Could not load this case. It may have been closed, or '
              'you are offline.';
        }
      });
    }
  }

  Future<bool> _confirm(String title, String message, String action) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _advance(String status) async {
    if (_acting) return;
    if (status == 'acknowledged') {
      final ok = await _confirm(
        'Accept this case?',
        'The caregiver is told by SMS that help is coming. Only accept if you '
        'can reach the patient.',
        'Accept case',
      );
      if (!ok) return;
    }
    if (status == 'closed') {
      final ok = await _confirm(
        'Close the loop?',
        'Close only when the patient has been handed over or the referral is '
        'complete. This ends the case.',
        'Close case',
      );
      if (!ok) return;
    }
    setState(() => _acting = true);
    try {
      await Api.I.dio
          .patch('/alerts/${widget.alertId}/status', data: {'status': status});
      await _load();
      if (!mounted) return;
      Attention.success();
      if (status == 'acknowledged') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Case accepted. The caregiver was told help is coming.')));
      } else if (status == 'closed') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loop closed. Thank you.')));
      }
    } catch (e) {
      final offline = e is DioException && e.response == null;
      if (offline) {
        await PendingActions.add(PendingAction(
          alertId: widget.alertId,
          status: status,
          queuedAt: DateTime.now(),
        ));
        if (!mounted) return;
        setState(() {
          _queued = true;
          _alert?['status'] = status;
          final timeline = _alert?['timeline'];
          if (timeline is List) {
            timeline.add({
              'event': status,
              'at': DateTime.now().toUtc().toIso8601String(),
              'note': 'Saved offline — queued for sync',
            });
          }
        });
        Attention.warning();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saved on this phone. It will sync when you have '
              'signal — keep moving.'),
          duration: Duration(seconds: 4),
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update the case. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _addNote() async {
    final status = _alert?['status'] as String? ?? 'pending';
    if (!_flow.contains(status)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Accept the case before adding clinical notes.')));
      return;
    }
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Case note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              maxLength: 280,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g. BP 90/60, heavy bleeding, arranged taxi',
              ),
            ),
            const Text(
              'Do not record names or phone numbers — the case already holds '
              'them. Notes are visible to the care team.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                height: 1.35,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
                context, controller.text.trim()),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.isEmpty) return;
    if (!mounted) return;
    setState(() => _acting = true);
    try {
      await Api.I.dio.patch('/alerts/${widget.alertId}/status',
          data: {'status': status, 'note': note});
      await _load();
      if (!mounted) return;
      Attention.success();
    } catch (e) {
      final offline = e is DioException && e.response == null;
      if (offline) {
        await PendingActions.add(PendingAction(
          alertId: widget.alertId,
          status: status,
          note: note,
          queuedAt: DateTime.now(),
        ));
        if (!mounted) return;
        setState(() {
          _queued = true;
          final timeline = _alert?['timeline'];
          if (timeline is List) {
            timeline.add({
              'event': status,
              'at': DateTime.now().toUtc().toIso8601String(),
              'note': '$note (queued)',
            });
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Note saved on this phone and queued for sync.')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save the note.')));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _navigate(dynamic coords) async {
    if (coords is! List || coords.length != 2) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${coords[1]},${coords[0]}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showProtocol() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      builder: (context) => const _ProtocolSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    final status = alert?['status'] as String? ?? 'pending';
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status == 'closed' ? 'Case record' : 'Live case'),
            Text(
              status == 'closed' ? 'Closed referral' : 'Open referral loop',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh case',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: alert == null
          ? _ErrorBody(error: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  if (_fromCache || _queued) ...[
                    NoticeBanner(
                      icon: _queued
                          ? Icons.cloud_upload_rounded
                          : Icons.cloud_off_rounded,
                      message: _queued
                          ? 'Action saved on this phone. It will sync when you '
                              'have signal.'
                          : 'Offline — showing the last saved copy. Status '
                              'changes will be queued.',
                      color: _queued
                          ? const Color(0xFF1F5F7D)
                          : const Color(0xFF8A4A00),
                      background:
                          _queued ? AppColors.skySoft : AppColors.amberSoft,
                      action: TextButton(
                        onPressed: () async {
                          await PendingActions.flush();
                          await _load();
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ..._buildBody(context, alert),
                ],
              ),
            ),
      bottomNavigationBar:
          alert == null ? null : _buildActionBar(alert),
    );
  }

  /// Populated references are Maps; unpopulated ones are plain ID strings —
  /// treat anything that isn't a Map as absent instead of crashing.
  static Map<String, dynamic>? _asMap(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : null;

  List<Widget> _buildBody(BuildContext context, Map<String, dynamic> alert) {
    final t = Theme.of(context).textTheme;
    final caregiver = _asMap(alert['caregiver']);
    final facility = _asMap(alert['facility']);
    final assessment = _asMap(alert['assessment']);
    final assessmentSigns =
        ((assessment?['dangerSigns'] as List?) ?? const []).cast<String>();
    final dangerSigns =
        assessmentSigns.isNotEmpty ? assessmentSigns : dangerSignsOf(alert);
    final coords = (alert['location'] as Map?)?['coordinates'];
    final reportUrl = alert['reportUrl'] as String?;
    final status = alert['status'] as String? ?? 'pending';
    final timeline =
        ((alert['timeline'] as List?) ?? []).cast<Map<String, dynamic>>();
    // The backend's own 'created' event duplicates the "Alert raised" header.
    final events =
        timeline.where((e) => e['event'] != 'created').toList(growable: false);
    final triage = triageOf(alert);
    final created = DateTime.tryParse(alert['createdAt'] as String? ?? '');

    double? meters;
    if (coords is List && coords.length == 2 && widget.myPosition != null) {
      meters = Geolocator.distanceBetween(
          widget.myPosition!.latitude,
          widget.myPosition!.longitude,
          (coords[1] as num).toDouble(),
          (coords[0] as num).toDouble());
    }

    return [
      _CaseHero(
        triage: triage,
        status: status,
        caregiver: caregiver,
        created: created,
        distance: meters,
        subject: _subject(alert),
      ),
      const SizedBox(height: 14),

      if (dangerSigns.isNotEmpty) ...[
        _SectionLabel(
          title: 'Danger signs reported',
          trailing: '${dangerSigns.length} flagged',
        ),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final sign in dangerSigns)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: triage.background,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                            color: triage.foreground.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        sign,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: triage.foreground,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.muted),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Screened automatically by the GrowWithMe app — it can '
                      'make mistakes. Assess the patient yourself and use your '
                      'own clinical judgement.',
                      style: t.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      if (caregiver != null) ...[
        _SectionLabel(title: 'Patient'),
        const SizedBox(height: 8),
        SurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.limeGradient,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(caregiver['name'] as String?),
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          caregiver['name'] as String? ?? 'Caregiver',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.titleSmall?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            caregiver['phone'],
                            caregiver['community'],
                          ].whereType<String>().join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall
                              ?.copyWith(color: AppColors.muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  if (caregiver['phone'] is String)
                    IconButton.filled(
                      tooltip: 'Call caregiver',
                      onPressed: () => _call(caregiver['phone'] as String),
                      icon: const Icon(Icons.call_rounded, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (caregiver['phone'] is String)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _call(caregiver['phone'] as String),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                  if (caregiver['phone'] is String && coords is List)
                    const SizedBox(width: 8),
                  if (coords is List && coords.length == 2)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _navigate(coords),
                        icon: const Icon(Icons.navigation_rounded, size: 18),
                        label: const Text('Navigate'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      _SectionLabel(title: 'Referral'),
      const SizedBox(height: 8),
      SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const IconBubble(
                  icon: Icons.local_hospital_rounded,
                  color: AppColors.teal,
                  size: 42,
                  iconSize: 21,
                  background: AppColors.tealSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility?['name'] as String? ?? 'No facility assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        facility == null
                            ? 'Use your judgement and nearest facility'
                            : [
                                facility['type'],
                                facility['phone'],
                              ].whereType<String>().join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                            color: AppColors.muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (reportUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(reportUrl),
                          mode: LaunchMode.externalApplication),
                      style: _referralButtonStyle,
                      icon: const Icon(Icons.description_rounded, size: 18),
                      label: const Text('Risk report', maxLines: 1),
                    ),
                  ),
                if (reportUrl != null) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showProtocol,
                    style: _referralButtonStyle,
                    icon: const Icon(Icons.checklist_rounded, size: 18),
                    label: const Text('Protocol', maxLines: 1),
                  ),
                ),
              ],
            ),
            if (facility?['phone'] is String) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _call(facility!['phone'] as String),
                  icon: const Icon(Icons.call_rounded, size: 17),
                  label: Text('Call ${facility?['name'] ?? 'facility'}'),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),

      if (ModelService.I.ready) ...[
        SurfaceCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AssessVitalsScreen(
                  patientName: caregiver?['name'] as String?,
                  alertId: widget.alertId))),
          child: Row(
            children: [
              const IconBubble(
                icon: Icons.monitor_heart_rounded,
                color: AppColors.violet,
                size: 42,
                iconSize: 21,
                background: AppColors.violetSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assess vitals', style: t.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'On-device risk estimate · works offline',
                      style: t.bodySmall?.copyWith(
                          color: AppColors.muted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],

      _SectionLabel(
        title: 'Timeline',
        trailing: _flow.contains(status) ? 'Add note' : null,
        onTrailingTap: _flow.contains(status) ? _addNote : null,
      ),
      const SizedBox(height: 8),
      SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (created != null)
              _TimelineTile(
                icon: Icons.notifications_active_rounded,
                color: AppColors.coral,
                title: 'Alert raised',
                note: '${dayLabel(alert['createdAt'])} · '
                    '${clockOf(alert['createdAt'])}',
              ),
            // Oldest first, so the story reads top-to-bottom and lines up
            // with the "Alert raised" entry above. The backend's own
            // 'created' event duplicates that header, so it is dropped.
            for (var i = 0; i < events.length; i++)
              _TimelineTile(
                icon: _eventIcon(events[i]['event'] as String?),
                color: _eventColor(events[i]['event'] as String?),
                title: _eventTitle(events[i]['event'] as String?),
                note: [
                  dayLabel(events[i]['at']),
                  clockOf(events[i]['at']),
                  if (events[i]['note'] is String) events[i]['note'] as String,
                ].whereType<String>().join(' · '),
                last: i == events.length - 1,
              ),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No responder action yet.',
                    style: t.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _buildActionBar(Map<String, dynamic> alert) {
    final status = alert['status'] as String? ?? 'pending';
    final next = _next[status];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: next == null
              ? Row(
                  children: [
                    const Icon(Icons.task_alt_rounded,
                        color: AppColors.teal, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'This loop is closed. Thank you for showing up.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    if (status == 'acknowledged' ||
                        status == 'en_route' ||
                        status == 'at_facility') ...[
                      _NoteButton(onTap: _acting ? null : _addNote),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: LimeButton(
                        label: next.$2,
                        icon: next.$3,
                        busy: _acting,
                        onPressed: _acting ? null : () => _advance(next.$1),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  static String? _subject(Map<String, dynamic> alert) {
    final summary = (alert['summary'] as String?) ?? '';
    if (summary.contains('child under 5')) return 'Child under 5';
    if (summary.contains('pregnant mother')) return 'Pregnant mother';
    if (summary.contains('mother')) return 'Mother';
    return null;
  }

  static IconData _eventIcon(String? event) => switch (event) {
        'notified' => Icons.send_rounded,
        'pending' || 'unassigned' => Icons.hourglass_top_rounded,
        'acknowledged' => Icons.check_circle_rounded,
        'en_route' => Icons.directions_run_rounded,
        'at_facility' => Icons.local_hospital_rounded,
        'closed' => Icons.task_alt_rounded,
        _ => Icons.circle_rounded,
      };

  static Color _eventColor(String? event) => switch (event) {
        'acknowledged' => AppColors.forest,
        'en_route' => AppColors.sky,
        'at_facility' => AppColors.teal,
        'closed' => AppColors.limeInk,
        _ => AppColors.muted,
      };

  static String _eventTitle(String? event) => switch (event) {
        'notified' => 'Responders notified',
        'pending' || 'unassigned' => 'Waiting for a responder',
        'acknowledged' => 'Case accepted',
        'en_route' => 'On the way',
        'at_facility' => 'Reached the facility',
        'closed' => 'Loop closed',
        _ => (event ?? '').replaceAll('_', ' '),
      };
}

class _CaseHero extends StatelessWidget {
  const _CaseHero({
    required this.triage,
    required this.status,
    required this.caregiver,
    required this.created,
    required this.distance,
    required this.subject,
  });

  final Triage triage;
  final String status;
  final Map<String, dynamic>? caregiver;
  final DateTime? created;
  final double? distance;
  final String? subject;

  @override
  Widget build(BuildContext context) {
    final waiting = created == null
        ? null
        : DateTime.now().difference(created!.toLocal());
    final closed = status == 'closed';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.forestDeep),
        boxShadow: AppShadows.raised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TriagePill(
                label: triage.label,
                foreground: triage.foreground,
                background: triage.background,
                icon: triage.level == TriageLevel.critical
                    ? Icons.priority_high_rounded
                    : null,
                dense: true,
              ),
              const SizedBox(width: 6),
              StatusPill(status: status, dense: true),
              const Spacer(),
              if (waiting != null && !closed)
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13,
                        color: AppColors.cream.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      '${waiting.inMinutes} min waiting',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cream.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            caregiver?['name'] as String? ?? 'Urgent case',
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 29,
              height: 1.06,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              ?subject,
              if (caregiver?['community'] is String) caregiver!['community'] as String,
              if (distance != null) '${distanceLabel(distance)} away',
            ].join('  ·  '),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.cream.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            closed
                ? 'This referral loop is complete.'
                : triage.hint,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.cream.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    this.trailing,
    this.onTrailingTap,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        if (trailing != null)
          onTrailingTap == null
              ? Text(
                  trailing!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.muted,
                  ),
                )
              : TextButton.icon(
                  onPressed: onTrailingTap,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(trailing!),
                ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.note,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 1.4, color: AppColors.line),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteButton extends StatelessWidget {
  const _NoteButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: const BorderSide(color: AppColors.lineStrong, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.edit_note_rounded,
              size: 24, color: AppColors.forest),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 42, color: AppColors.faint),
            const SizedBox(height: 12),
            Text(
              error ?? 'Could not load this case.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ProtocolSheet extends StatelessWidget {
  const _ProtocolSheet();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      maxChildSize: 0.94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.checklist_rounded,
                color: AppColors.forest,
                size: 42,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danger-sign protocol', style: t.titleMedium),
                    Text(
                      'A field prompt — not a diagnosis',
                      style: t.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const NoticeBanner(
            icon: Icons.info_outline_rounded,
            message: 'Follow your national protocol and clinical training. '
                'This checklist only helps you remember the steps.',
            color: Color(0xFF8A4A00),
          ),
          const SizedBox(height: 18),
          for (final section in const [
            (
              '1 · Check and stabilise',
              [
                'Make sure the scene is safe and you have help nearby.',
                'Check bleeding, breathing, consciousness and temperature.',
                'If convulsing: protect the head, do not restrain, do not put anything in the mouth.',
                'Keep the mother warm and do not leave her alone.',
              ],
            ),
            (
              '2 · Call ahead',
              [
                'Call the referral facility and say a woman or child is coming.',
                'State the danger signs and their time of onset.',
                'Ask what to do while transport is arranged.',
              ],
            ),
            (
              '3 · Arrange transport',
              [
                'Reach the nearest facility, not the most distant “better” one.',
                'Ask the family to travel with the mother.',
                'Take the phone, the referral note and any health records.',
              ],
            ),
            (
              '4 · Hand over clearly',
              [
                'Give the facility the danger signs, time of onset and measurements taken.',
                'Report the actions you took and the time you arrived.',
                'Close the case in the app only after the handover.',
              ],
            ),
          ]) ...[
            Text(
              section.$1,
              style: t.titleSmall?.copyWith(color: AppColors.forestDeep),
            ),
            const SizedBox(height: 8),
            for (final line in section.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(Icons.circle,
                          size: 5, color: AppColors.forest),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        line,
                        style: t.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close protocol'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_client.dart';
import '../../core/model_service.dart';
import '../alerts/alert_detail.dart';
import '../auth/login_screen.dart';

/// Home: on/off-duty switch + alert list (mine first, then nearby unassigned)
/// and an OpenStreetMap tab with alert and facility pins. Polls every 30 s and
/// heartbeats the responder's location so routing stays fresh.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late final Map<String, dynamic> _user = widget.user;
  bool get _available => _user['available'] != false;

  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _unassigned = [];
  List<Map<String, dynamic>> _facilities = [];
  Position? _position;
  bool _loading = true;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    // Background-fetch the offline risk model; silent no-op when offline or
    // already current. The Assess Vitals feature hides until this succeeds.
    ModelService.I.ensureLatest();
    await _heartbeat();
    await _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _heartbeatTimer =
        Timer.periodic(const Duration(minutes: 3), (_) => _heartbeat());
  }

  /// Get the phone's location and push it to the backend. Routing only works
  /// for responders whose location is known.
  Future<void> _heartbeat() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) setState(() => _position = pos);
      await Api.I.dio.post('/responder/location',
          data: {'lng': pos.longitude, 'lat': pos.latitude});
      _loadFacilities(pos);
    } catch (_) {}
  }

  Future<void> _loadFacilities(Position pos) async {
    try {
      final res = await Api.I.dio.get('/facilities/nearby',
          queryParameters: {'lng': pos.longitude, 'lat': pos.latitude});
      if (!mounted) return;
      setState(() => _facilities =
          (res.data['facilities'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _refresh() async {
    try {
      final res = await Api.I.dio.get('/responder/alerts');
      if (!mounted) return;
      setState(() {
        _mine = (res.data['mine'] as List).cast<Map<String, dynamic>>();
        _unassigned =
            (res.data['unassigned'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setAvailability(bool value) async {
    setState(() => _user['available'] = value);
    try {
      await Api.I.dio.post('/responder/availability', data: {'available': value});
    } catch (_) {
      if (mounted) setState(() => _user['available'] = !value);
    }
  }

  Future<void> _logout() async {
    await Api.I.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _openAlert(Map<String, dynamic> alert) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => AlertDetailScreen(
                alertId: alert['_id'] as String, myPosition: _position)))
        .then((_) => _refresh());
  }

  String? _verificationStatus() =>
      _user['credentials']?['status'] as String?;

  @override
  Widget build(BuildContext context) {
    final verified = _verificationStatus() == 'verified';
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(_user['name'] as String? ?? 'Responder',
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            if (verified)
              Tooltip(
                message: 'Verified responder',
                child: Icon(Icons.verified, color: Colors.green.shade600, size: 20),
              )
            else
              Tooltip(
                message: 'Verification pending',
                child: Icon(Icons.hourglass_top,
                    color: Colors.orange.shade600, size: 20),
              ),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'Log out',
              onPressed: _logout,
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          _DutyBanner(available: _available, onChanged: _setAvailability),
          Expanded(
            child: _tab == 0 ? _buildAlertList() : _buildMap(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.notifications_active_outlined),
              selectedIcon: Icon(Icons.notifications_active),
              label: 'Alerts'),
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Map'),
        ],
      ),
    );
  }

  Widget _buildAlertList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_mine.isEmpty && _unassigned.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
            SizedBox(height: 12),
            Text('No urgent cases right now.', textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text('You will get an SMS when a case is routed to you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_mine.isNotEmpty) ...[
            const _SectionHeader('My cases'),
            for (final a in _mine)
              _AlertCard(alert: a, position: _position, onTap: () => _openAlert(a)),
          ],
          if (_unassigned.isNotEmpty) ...[
            const _SectionHeader('Nearby — nobody assigned yet'),
            for (final a in _unassigned)
              _AlertCard(alert: a, position: _position, onTap: () => _openAlert(a)),
          ],
        ],
      ),
    );
  }

  Widget _buildMap() {
    final me = _position;
    final center = me != null
        ? LatLng(me.latitude, me.longitude)
        : const LatLng(5.6037, -0.1870); // Accra fallback until GPS answers
    final alerts = [..._mine, ..._unassigned];
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 12),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.growwithme.responder',
        ),
        MarkerLayer(
          markers: [
            if (me != null)
              Marker(
                point: LatLng(me.latitude, me.longitude),
                width: 44,
                height: 44,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
              ),
            for (final f in _facilities)
              if (_coords(f['location']) != null)
                Marker(
                  point: _coords(f['location'])!,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showFacility(f),
                    child: Icon(Icons.local_hospital,
                        color: Colors.green.shade700, size: 32),
                  ),
                ),
            for (final a in alerts)
              if (_coords(a['location']) != null)
                Marker(
                  point: _coords(a['location'])!,
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _openAlert(a),
                    child: const Icon(Icons.warning_rounded,
                        color: Colors.red, size: 36),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  void _showFacility(Map<String, dynamic> facility) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: Icon(Icons.local_hospital, color: Colors.green.shade700),
          title: Text(facility['name'] as String? ?? 'Facility'),
          subtitle: Text([
            facility['type'],
            facility['phone'],
          ].whereType<String>().join(' · ')),
        ),
      ),
    );
  }
}

LatLng? _coords(dynamic location) {
  final coords = (location is Map) ? location['coordinates'] : null;
  if (coords is List && coords.length == 2) {
    return LatLng((coords[1] as num).toDouble(), (coords[0] as num).toDouble());
  }
  return null;
}

class _DutyBanner extends StatelessWidget {
  const _DutyBanner({required this.available, required this.onChanged});

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: available ? Colors.green.shade50 : Colors.grey.shade200,
      child: SwitchListTile(
        value: available,
        onChanged: onChanged,
        title: Text(available ? 'On duty' : 'Off duty',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(available
            ? 'Urgent cases nearby can be routed to you'
            : 'You will not receive new cases'),
        secondary: Icon(
          available ? Icons.health_and_safety : Icons.do_not_disturb_on,
          color: available ? Colors.green.shade700 : Colors.grey,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard(
      {required this.alert, required this.position, required this.onTap});

  final Map<String, dynamic> alert;
  final Position? position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caregiver = alert['caregiver'] as Map<String, dynamic>?;
    final status = (alert['status'] as String? ?? 'pending').replaceAll('_', ' ');
    final created = DateTime.tryParse(alert['createdAt'] as String? ?? '');

    String? distanceText;
    final point = _coords(alert['location']);
    if (point != null && position != null) {
      final meters = Geolocator.distanceBetween(position!.latitude,
          position!.longitude, point.latitude, point.longitude);
      distanceText = meters >= 1000
          ? '${(meters / 1000).toStringAsFixed(1)} km'
          : '${meters.round()} m';
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      caregiver?['name'] as String? ?? 'Urgent case',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(status,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                alert['summary'] as String? ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (distanceText != null) '$distanceText away',
                  if (created != null) _ago(created),
                  if (caregiver?['community'] is String)
                    caregiver!['community'] as String,
                ].join(' · '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _ago(DateTime time) {
  final d = DateTime.now().difference(time.toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

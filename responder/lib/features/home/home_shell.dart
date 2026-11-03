import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api_client.dart';
import '../../core/attention.dart';
import '../../core/model_service.dart';
import '../../core/offline_cache.dart';
import '../../core/pending_actions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/triage.dart';
import '../../core/ui/app_widgets.dart';
import '../../main.dart' show takePendingAlertId;
import '../alerts/alert_detail.dart';
import '../auth/login_screen.dart';
import '../impact/impact_tab.dart';
import '../profile/profile_tab.dart';
import 'map_tab.dart';
import 'widgets/case_card.dart';
import 'widgets/duty_hero.dart';

/// Responder home. Four surfaces:
///  • Alerts  — duty state, live queue, nearby unassigned cases
///  • Map     — coverage, my cases, facilities
///  • Impact  — outcomes and response times from real history
///  • Profile — credentials, tools, privacy and sign out
///
/// Polls every 30 s, heartbeats location every 3 min, pings with sound and
/// vibration when a brand-new urgent case appears, and replays any status
/// updates queued while offline.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final Map<String, dynamic> user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  late Map<String, dynamic> _user = widget.user;
  bool get _available => _user['available'] != false;

  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _unassigned = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _facilities = [];
  Position? _position;
  bool _loading = true;
  bool _fromCache = false;
  bool _locationKnown = true;
  bool _modelReady = false;
  int? _modelVersion;
  int _pendingUpdates = 0;
  Map<String, dynamic>? _newCase;
  Set<String>? _knownIds;
  Timer? _pollTimer;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PendingActions.count.addListener(_onPendingChanged);
    PendingActions.refreshCount();
    _refreshModel();
    _start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = takePendingAlertId();
      if (id != null) _openAlertById(id);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PendingActions.count.removeListener(_onPendingChanged);
    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _heartbeat();
    }
  }

  void _onPendingChanged() {
    if (!mounted) return;
    setState(() => _pendingUpdates = PendingActions.count.value);
  }

  Future<void> _refreshModel() async {
    await ModelService.I.ensureLatest();
    if (!mounted) return;
    setState(() {
      _modelReady = ModelService.I.ready;
      _modelVersion = ModelService.I.version;
    });
  }

  Future<void> _start() async {
    // Refresh credentials in the background so a newly verified responder
    // stops seeing "in review" without having to reinstall.
    _loadUserQuietly();
    // Cases must not wait on a GPS fix: a first fix indoors can take half a
    // minute, and the queue has to be usable the moment the app opens.
    _heartbeat();
    await _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    _heartbeatTimer =
        Timer.periodic(const Duration(minutes: 3), (_) => _heartbeat());
  }

  Future<void> _loadUserQuietly() async {
    try {
      final res = await Api.I.dio.get('/users/me');
      final user = Map<String, dynamic>.from(res.data['user'] as Map);
      await OfflineCache.put('me', user);
      if (!mounted) return;
      setState(() => _user = user);
    } catch (_) {
      // Offline — keep the cached profile already on screen.
    }
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
        if (mounted) setState(() => _locationKnown = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (mounted) {
        setState(() {
          _position = pos;
          _locationKnown = true;
        });
      }
      await Api.I.dio.post('/responder/location',
          data: {'lng': pos.longitude, 'lat': pos.latitude});
      _loadFacilities(pos);
    } catch (_) {
      if (mounted) setState(() => _locationKnown = _position != null);
    }
  }

  Future<void> _loadFacilities(Position pos) async {
    try {
      final res = await Api.I.dio.get('/facilities/nearby',
          queryParameters: {'lng': pos.longitude, 'lat': pos.latitude});
      if (!mounted) return;
      setState(() => _facilities =
          (res.data['facilities'] as List).cast<Map<String, dynamic>>());
      OfflineCache.put('facilities', _facilities);
    } catch (_) {
      final cached = await OfflineCache.get('facilities') as List?;
      if (cached != null && mounted) {
        setState(() => _facilities = cached.cast<Map<String, dynamic>>());
      }
    }
  }

  Future<void> _refresh() async {
    // Replay anything taken while off the grid, then pull fresh state.
    try {
      await PendingActions.flush();
    } catch (_) {}

    try {
      final results = await Future.wait([
        Api.I.dio.get('/responder/alerts'),
        Api.I.dio.get('/alerts'),
      ]);
      if (!mounted) return;
      final newMine =
          (results[0].data['mine'] as List).cast<Map<String, dynamic>>();
      final newNearby =
          (results[0].data['unassigned'] as List).cast<Map<String, dynamic>>();
      final history =
          ((results[1].data['alerts'] as List?) ?? []).cast<Map<String, dynamic>>();
      _detectNewCases(newMine, newNearby);
      setState(() {
        _mine = newMine;
        _unassigned = newNearby;
        _history = history;
        _loading = false;
        _fromCache = false;
      });
      OfflineCache.put('alerts', {
        'mine': _mine,
        'unassigned': _unassigned,
        'history': _history,
      });
    } catch (_) {
      // Offline: fall back to the last successful fetch so cases stay
      // accessible in the field.
      final cached = await OfflineCache.get('alerts') as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        if (cached != null) {
          _mine = ((cached['mine'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          _unassigned = ((cached['unassigned'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          _history = ((cached['history'] as List?) ?? [])
              .cast<Map<String, dynamic>>();
          _fromCache = true;
        }
        _loading = false;
      });
    }
  }

  /// Fires the field alert only for genuinely new, still-open cases. The first
  /// successful load seeds the set so opening the app is quiet.
  void _detectNewCases(
    List<Map<String, dynamic>> mine,
    List<Map<String, dynamic>> nearby,
  ) {
    final all = [...mine, ...nearby];
    final ids = all.map((a) => a['_id'] as String? ?? '').toSet();
    final known = _knownIds;
    _knownIds = ids;
    if (known == null) return;
    final fresh = all
        .where((a) =>
            !known.contains(a['_id']) && statusRank(a['status'] as String?) == 0)
        .toList()
      ..sort((a, b) => triageOf(a).level.index.compareTo(triageOf(b).level.index));
    if (fresh.isEmpty) return;
    Attention.newCase();
    setState(() => _newCase = fresh.first);
  }

  Future<void> _setAvailability(bool value) async {
    setState(() => _user['available'] = value);
    try {
      await Api.I.dio.post('/responder/availability', data: {'available': value});
      if (mounted && value) _refresh();
    } catch (_) {
      if (!mounted) return;
      setState(() => _user['available'] = !value);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not change duty status. Check your connection.')));
    }
  }

  Future<void> _loadUser() async {
    try {
      final res = await Api.I.dio.get('/users/me');
      final user = Map<String, dynamic>.from(res.data['user'] as Map);
      await OfflineCache.put('me', user);
      if (!mounted) return;
      setState(() => _user = user);
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not refresh your profile. Check your connection.')));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'Queued status updates that have not reached the server will be '
            'discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PendingActions.clear();
    await Api.I.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _openAlert(Map<String, dynamic> alert) {
    _openAlertById(alert['_id'] as String);
  }

  void _openAlertById(String id) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => AlertDetailScreen(
                alertId: id, myPosition: _position)))
        .then((_) {
      _refresh();
      _loadFacilitiesIfPossible();
    });
  }

  void _loadFacilitiesIfPossible() {
    final pos = _position;
    if (pos != null) _loadFacilities(pos);
  }

  List<Map<String, dynamic>> get _openMine => sortCases(_mine
      .where((a) => (a['status'] as String? ?? '') != 'closed')
      .toList());

  List<Map<String, dynamic>> get _nearby => sortCases(_unassigned);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: switch (_tab) {
            1 => MapTab(
                position: _position,
                alerts: [..._mine, ..._unassigned],
                mine: _mine,
                facilities: _facilities,
                onOpenAlert: _openAlert,
                locationKnown: _locationKnown,
              ),
            2 => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ImpactTab(
                  alerts: _history,
                  onOpenAlert: _openAlert,
                  onRefresh: _refresh,
                  loading: _loading,
                  fromCache: _fromCache,
                ),
              ),
            3 => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ProfileTab(
                  user: _user,
                  available: _available,
                  onAvailabilityChanged: _setAvailability,
                  onRefreshUser: _loadUser,
                  onLogout: _logout,
                  pendingUpdates: _pendingUpdates,
                  modelReady: _modelReady,
                  modelVersion: _modelVersion,
                ),
              ),
            _ => _buildQueue(),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i == 2 || i == 3) _refresh();
        },
        destinations: [
          NavigationDestination(
            icon: _iconWithBadge(
              Icons.notifications_active_outlined,
              count: _openMine.length,
            ),
            selectedIcon: _iconWithBadge(
              Icons.notifications_active_rounded,
              count: _openMine.length,
            ),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Impact',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _iconWithBadge(IconData icon, {required int count}) {
    if (count == 0) return Icon(icon);
    return Badge(
      backgroundColor: AppColors.coral,
      textColor: AppColors.white,
      label: Text('$count'),
      child: Icon(icon),
    );
  }

  Widget _buildQueue() {
    final t = Theme.of(context).textTheme;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final mine = _openMine;
    final nearby = _nearby;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
        children: [
          Row(
            children: [
              const ResponderMark(size: 30, showShadow: false),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Care queue',
                      style: t.titleMedium?.copyWith(
                        fontSize: 15,
                        color: AppColors.forestDeep,
                      )),
                  Text(
                    _available
                        ? 'Watching ${nearby.length + mine.length} open case${nearby.length + mine.length == 1 ? '' : 's'}'
                        : 'Off duty · your own cases stay visible',
                    style: t.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _LiveDot(active: _available && !_fromCache),
            ],
          ),
          const SizedBox(height: 14),
          DutyHero(
            user: _user,
            available: _available,
            onChanged: _setAvailability,
            activeCases: mine.length,
            nearbyCases: nearby.length,
            closedThisWeek: _closedThisWeek(),
            locationKnown: _locationKnown,
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: AppMotion.base,
            curve: AppMotion.enter,
            child: _newCase == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NewCaseBanner(
                      alert: _newCase!,
                      onOpen: () {
                        final alert = _newCase!;
                        setState(() => _newCase = null);
                        _openAlert(alert);
                      },
                      onDismiss: () => setState(() => _newCase = null),
                    ),
                  ),
          ),
          if (_fromCache) ...[
            const NoticeBanner(
              icon: Icons.cloud_off_rounded,
              message:
                  'Offline — showing your last saved cases. Pull to retry.',
            ),
            const SizedBox(height: 10),
          ],
          if (_pendingUpdates > 0) ...[
            NoticeBanner(
              icon: Icons.cloud_upload_rounded,
              message:
                  '$_pendingUpdates update${_pendingUpdates == 1 ? '' : 's'} waiting to sync.',
              color: const Color(0xFF1F5F7D),
              background: AppColors.skySoft,
              action: TextButton(
                onPressed: _refresh,
                child: const Text('Sync'),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (mine.isEmpty && nearby.isEmpty)
            SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.check_circle_rounded,
                title: 'All quiet right now.',
                message: _available
                    ? 'You are on duty. We will ring this phone the moment a '
                        'mother or child nearby needs help.'
                    : 'You are off duty. Turn on duty to be routed nearby '
                        'urgent cases.',
                action: _available
                    ? null
                    : Pill(
                        label: 'ON DUTY PAUSED',
                        icon: Icons.pause_circle_filled_rounded,
                        foreground: AppColors.muted,
                        background: AppColors.creamDeep,
                      ),
              ),
            )
          else ...[
            if (mine.isNotEmpty) ...[
              SectionHeader(
                title: 'Needs you',
                subtitle: 'Cases assigned to you',
                actionLabel: 'Refresh',
                onAction: _refresh,
              ),
              for (final alert in mine) ...[
                CaseCard(
                  alert: alert,
                  assigned: true,
                  distance: distanceMeters(alert, _position?.latitude,
                      _position?.longitude),
                  onTap: () => _openAlert(alert),
                ),
                const SizedBox(height: 10),
              ],
            ],
            if (nearby.isNotEmpty) ...[
              SectionHeader(
                title: 'Nearby',
                subtitle: 'Nobody assigned yet — step in',
                padding: EdgeInsets.only(
                  top: mine.isEmpty ? 8 : 12,
                  bottom: 10,
                ),
              ),
              for (final alert in nearby) ...[
                CaseCard(
                  alert: alert,
                  distance: distanceMeters(alert, _position?.latitude,
                      _position?.longitude),
                  onTap: () => _openAlert(alert),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Auto-refreshes every 30 seconds · pull to refresh',
              style: t.bodySmall?.copyWith(
                color: AppColors.faint,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _closedThisWeek() {
    final start = DateTime.now().subtract(const Duration(days: 7));
    return _history.where((a) {
      if (a['status'] != 'closed') return false;
      final timeline = a['timeline'];
      if (timeline is! List) return false;
      return timeline.any((e) =>
          e is Map &&
          e['event'] == 'closed' &&
          (DateTime.tryParse(e['at'] as String? ?? '')?.isAfter(start) ?? false));
    }).length;
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.limeSoft : AppColors.creamDeep,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(
            color: active ? AppColors.lime : AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.forest : AppColors.faint,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'LIVE' : 'PAUSED',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: active ? AppColors.forest : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCaseBanner extends StatelessWidget {
  const _NewCaseBanner({
    required this.alert,
    required this.onOpen,
    required this.onDismiss,
  });

  final Map<String, dynamic> alert;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final caregiver = alert['caregiver'] is Map
        ? (alert['caregiver'] as Map).cast<String, dynamic>()
        : null;
    final name = caregiver?['name'] as String? ?? 'A nearby case';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded,
              color: AppColors.coral, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEW URGENT CASE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onOpen,
            child: const Text('Open'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

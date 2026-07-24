import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../assessment/assessment_screen.dart';
import '../calendar/calendar_tab.dart';
import '../children/add_child_screen.dart';
import '../pregnancy/add_pregnancy_screen.dart';
import '../pregnancy/pregnancy_card.dart';
import '../tips/tips_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    // Sync on open (also refreshes the home-screen widget), and again
    // whenever connectivity comes back.
    Future.microtask(() {
      ref.read(syncControllerProvider.notifier).sync();
      ref.read(widgetServiceProvider).refresh();
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        ref.read(syncControllerProvider.notifier).sync();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _startAssessment() {
    final children = ref.read(childrenProvider).value ?? const [];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Who is this check for?')),
            for (final child in children)
              ListTile(
                leading: const Icon(Icons.child_care),
                title: Text(child.name),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AssessmentScreen(
                          subjectType: 'child', childId: child.id)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.pregnant_woman),
              title: const Text('My pregnancy / myself'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        const AssessmentScreen(subjectType: 'pregnancy')));
              },
            ),
          ],
        ),
      ),
    );
  }

  static const _titles = ['GrowWithMe', 'Care calendar', 'Feeding tips', 'Alerts'];

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: syncState.isLoading
                ? null
                : () => ref.read(syncControllerProvider.notifier).sync(),
            icon: syncState.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(syncState.hasError ? Icons.cloud_off : Icons.cloud_done),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: switch (_tab) {
        0 => const _HomeTab(),
        1 => const CalendarTab(),
        2 => const TipsTab(),
        _ => const _AlertsTab(),
      },
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startAssessment,
        icon: const Icon(Icons.health_and_safety),
        label: const Text('Health check'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Tips'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.animation,
    required this.message,
    this.repeat = true,
  });

  final String animation;
  final String message;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Lottie.asset(animation, height: 170, repeat: repeat),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  String _age(DateTime dob) {
    final months = DateTime.now().difference(dob).inDays ~/ 30;
    if (months < 1) return 'Newborn';
    if (months < 24) return '$months months';
    return '${months ~/ 12} years';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const [];
    final activePregnancies = (ref.watch(pregnanciesProvider).value ?? const [])
        .where((p) => p.status == 'active')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final pregnancy in activePregnancies)
          PregnancyCard(pregnancy: pregnancy),
        if (activePregnancies.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.pregnant_woman),
              title: const Text('Expecting? Track your pregnancy'),
              subtitle: const Text('ANC visit calendar and weekly guidance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AddPregnancyScreen())),
            ),
          ),
        const SizedBox(height: 8),
        Text('My children', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final child in children)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text(child.name.characters.first)),
              title: Text(child.name),
              subtitle: Text(_age(child.dateOfBirth)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AssessmentScreen(
                      subjectType: 'child', childId: child.id))),
            ),
          ),
        if (children.isEmpty)
          _EmptyState(
            animation: 'assets/lottie/welcome_heart.json',
            message: 'Add your first child to create their care calendar',
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddChildScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Add child'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _AlertsTab extends ConsumerWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (alerts.isEmpty)
          _EmptyState(
            animation: 'assets/lottie/success_check.json',
            message: 'No alerts — all is well. Urgent health checks will appear here.',
            repeat: false,
          ),
        for (final alert in alerts)
          Card(
            child: ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red),
              title: Text(alert.summary),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${alert.status}'),
                  if (alert.volunteerName != null)
                    Text('Volunteer: ${alert.volunteerName} (${alert.volunteerPhone ?? '-'})'),
                  if (alert.facilityName != null)
                    Text('Facility: ${alert.facilityName}'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}

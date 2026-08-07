import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/diet_guide.dart';
import '../assessment/assessment_screen.dart';
import '../calendar/calendar_tab.dart';
import '../children/add_child_screen.dart';
import '../children/child_detail_screen.dart';
import '../diet/diet_screen.dart';
import '../nana/nana_chat_screen.dart';
import '../pregnancy/add_pregnancy_screen.dart';
import '../pregnancy/pregnancies_screen.dart';
import '../pregnancy/pregnancy_card.dart';
import '../pregnancy/pregnancy_records_screen.dart';
import '../tips/tips_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    // Sync on open (also refreshes the home-screen widget), and again
    // whenever connectivity comes back.
    Future.microtask(() async {
      ref.read(syncControllerProvider.notifier).sync();
      ref.read(widgetServiceProvider).refresh();
      // A fresh meal plan and fresh tips wait on the home page every day.
      ref.read(dietPlannerProvider).ensureTodayPlan();
      ref.read(tipsUpdaterProvider).ensureTodayTips();
      // Background-fetch the offline risk model (6 KB) — silent no-op when
      // offline; the optional measurements feature hides until it exists.
      ref.read(modelServiceProvider).ensureLatest();
      // Re-arm phone alerts for upcoming personal reminders (e.g. after a
      // reinstall or on a new device — they ride the sync).
      final custom = await ref.read(dbProvider).upcomingCustomReminders();
      for (final r in custom) {
        ref.read(notificationServiceProvider).schedule(
              reminderId: r.id,
              title: 'GrowWithMe reminder',
              body: r.title,
              when: r.dueDate,
            );
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        // Network changed — the best route to the backend may have too.
        ref.read(apiClientProvider).invalidateBaseUrl();
        ref.read(syncControllerProvider.notifier).sync();
        // Back online: upgrade today's cookbook plan/tips to AI if needed.
        ref.read(dietPlannerProvider).ensureTodayPlan();
        ref.read(tipsUpdaterProvider).ensureTodayTips();
        ref.read(modelServiceProvider).ensureLatest();
      }
    });
    // Nana widget tap → open Nana and speak the day's briefing.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    if (uri.host == 'nana-briefing') {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const NanaChatScreen(speakBriefingOnOpen: true)));
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _widgetClickSub?.cancel();
    super.dispose();
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
      // Voice companion: one tap and you are "on a call" with Nana —
      // ask her anything, hands-free.
      floatingActionButton: FloatingActionButton(
        tooltip: 'Talk to Nana',
        backgroundColor: const Color(0xFFF57C00),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NanaChatScreen(voiceMode: true))),
        child: const Icon(Icons.mic),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Tips'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts'),
        ],
      ),
    );
  }
}

void startAssessmentPicker(BuildContext context, WidgetRef ref) {
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
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Lottie.asset(animation, height: 150, repeat: repeat),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _readDayAloud(WidgetRef ref, List<ReminderRow> dueSoon) {
    final buffer = StringBuffer();
    if (dueSoon.isEmpty) {
      buffer.write('You have no clinic visits due this week. Well done. ');
    } else {
      buffer.write('You have ${dueSoon.length} '
          'visit${dueSoon.length == 1 ? '' : 's'} coming up. ');
      for (final r in dueSoon.take(3)) {
        buffer.write(
            '${DateFormat('EEEE d MMMM').format(r.dueDate)}: ${r.title}. ');
      }
    }
    ref.read(ttsProvider).speak(buffer.toString());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final children = ref.watch(childrenProvider).value ?? const [];
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final activePregnancies = (ref.watch(pregnanciesProvider).value ?? const [])
        .where((p) => p.status == 'active')
        .toList();
    final name = ref.watch(userNameProvider).value;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueSoon = reminders.where((r) {
      final d = DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day);
      return !d.isAfter(today.add(const Duration(days: 7)));
    }).toList();

    ReminderRow? nextVisitFor(String childId) {
      for (final r in reminders) {
        if (r.childId == childId) return r;
      }
      return null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ---- Hero: greeting + this week's visits + read-aloud ----
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, const Color(0xFF1B5E20)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == null || name.isEmpty
                              ? '${_greeting()} 👋'
                              : '${_greeting()}, ${name.split(' ').first} 👋',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM').format(now),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  // Voice-first: the whole day, spoken.
                  Material(
                    color: Colors.white24,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Read my visits aloud',
                      onPressed: () => _readDayAloud(ref, dueSoon),
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text('This week',
                            style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (dueSoon.isEmpty)
                      const Text('No visits due — you are on track! 🎉',
                          style: TextStyle(color: Colors.white))
                    else ...[
                      for (final r in dueSoon.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '• ${DateFormat('EEE d').format(r.dueDate)} — ${r.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      if (dueSoon.length > 3)
                        Text('+${dueSoon.length - 3} more on the calendar',
                            style: const TextStyle(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ---- Quick actions: big, icon-first, low-literacy friendly ----
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.health_and_safety,
                label: 'Health check',
                color: const Color(0xFFD32F2F),
                onTap: () => startAssessmentPicker(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.support_agent,
                label: 'Ask Nana',
                color: const Color(0xFFF57C00),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NanaChatScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.child_friendly,
                label: 'Add child',
                color: const Color(0xFF1E88E5),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AddChildScreen())),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAction(
                icon: Icons.pregnant_woman,
                label: 'Pregnancy',
                color: const Color(0xFFD81B60),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AddPregnancyScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ---- My health at a glance: visual trends ----
        const _GlanceCharts(),
        const SizedBox(height: 16),

        // ---- Today's meals (auto-planned daily) ----
        const _TodayMealsCard(),
        const SizedBox(height: 16),

        // ---- Pregnancy journey: only the CURRENT one lives on Home;
        // history and management sit behind "See all". ----
        Builder(builder: (context) {
          final allPregnancies =
              ref.watch(pregnanciesProvider).value ?? const [];
          final hasMore =
              allPregnancies.length > (activePregnancies.isEmpty ? 0 : 1);
          if (activePregnancies.isEmpty && !hasMore) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('My pregnancy', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (hasMore)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const PregnanciesScreen())),
                      child: const Text('See all'),
                    ),
                ],
              ),
              if (activePregnancies.isNotEmpty)
                PregnancyCard(pregnancy: activePregnancies.first),
              const SizedBox(height: 8),
            ],
          );
        }),

        // ---- Children ----
        Text('My children', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final child in children)
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(child.name.characters.first,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              title: Text(child.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Builder(builder: (context) {
                final next = nextVisitFor(child.id);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_age(child.dateOfBirth)),
                    if (next != null)
                      Text(
                        'Next: ${DateFormat('d MMM').format(next.dueDate)} — ${next.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                  ],
                );
              }),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChildDetailScreen(child: child))),
            ),
          ),
        if (children.isEmpty)
          _EmptyState(
            animation: 'assets/lottie/welcome_heart.json',
            message: 'Add your first child to create their care calendar',
          ),
      ],
    );
  }
}

/// Visual trends at a glance: diet diversity bars and the pregnancy risk
/// wave, right on the home page — tap either to open the full view.
class _GlanceCharts extends ConsumerWidget {
  const _GlanceCharts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(recentDietLogsProvider).value ?? const [];
    final riskRecords =
        ref.watch(pregnancyAssessmentsProvider).value ?? const [];
    if (logs.isEmpty && riskRecords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My health at a glance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Row(
          children: [
            if (logs.isNotEmpty)
              Expanded(
                child: _MiniChartCard(
                  title: '🥗 Diet this week',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const DietScreen())),
                  child: BarChart(
                    BarChartData(
                      maxY: 8,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                      ),
                      barTouchData: BarTouchData(enabled: false),
                      barGroups: [
                        for (var i = 0; i < logs.length; i++)
                          BarChartGroupData(x: i, barRods: [
                            BarChartRodData(
                              toY: logs.reversed
                                  .toList()[i]
                                  .score
                                  .toDouble()
                                  .clamp(0.3, 8),
                              width: 10,
                              borderRadius: BorderRadius.circular(3),
                              color: logs.reversed.toList()[i].score >= 5
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ]),
                      ],
                    ),
                  ),
                ),
              ),
            if (logs.isNotEmpty && riskRecords.isNotEmpty)
              const SizedBox(width: 10),
            if (riskRecords.isNotEmpty)
              Expanded(
                child: _MiniChartCard(
                  title: '❤️ Pregnancy risk',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PregnancyRecordsScreen())),
                  child: LineChart(
                    LineChartData(
                      minY: 0.5,
                      maxY: 3.5,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        bottomTitles: AxisTitles(),
                      ),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < riskRecords.length; i++)
                              FlSpot(
                                  i.toDouble(),
                                  switch (riskRecords[i].riskLevel) {
                                    'urgent' => 3.0,
                                    'moderate' => 2.0,
                                    _ => 1.0,
                                  }),
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 2.5,
                          color: theme.colorScheme.primary,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, _, i) =>
                                FlDotCirclePainter(
                              radius: 3,
                              color: switch (
                                  riskRecords[spot.x.toInt()].riskLevel) {
                                'urgent' => Colors.red,
                                'moderate' => Colors.orange,
                                _ => Colors.green,
                              },
                              strokeWidth: 0,
                              strokeColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MiniChartCard extends StatelessWidget {
  const _MiniChartCard(
      {required this.title, required this.child, required this.onTap});

  final String title;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(height: 72, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayMealsCard extends ConsumerWidget {
  const _TodayMealsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latest = ref.watch(latestDietPlanProvider).value;
    if (latest == null) return const SizedBox.shrink();

    Map<String, dynamic>? plan;
    try {
      plan = jsonDecode(latest.planJson) as Map<String, dynamic>;
    } catch (_) {
      return const SizedBox.shrink();
    }
    final slots = planSlots(plan);

    return Card(
      color: Colors.orange.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DietScreen())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🍲', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Today\'s meals from Nana',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Read aloud',
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: () {
                      final text = StringBuffer(plan!['summary'] ?? '');
                      for (final slot in slots) {
                        final names = (slot['options'] as List)
                            .map((o) => o['name'])
                            .join(', or ');
                        text.write(' ${slot['time']}: $names.');
                      }
                      ref.read(nanaVoiceProvider).speak(text.toString());
                    },
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              for (final slot in slots.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        switch (slot['time']) {
                          'Morning' => '🌅 ',
                          'Midday' => '☀️ ',
                          'Evening' => '🌙 ',
                          _ => '🍌 ',
                        },
                      ),
                      Expanded(
                        child: Text(
                          (slot['options'] as List)
                              .map((o) => o['name'])
                              .join(' / '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
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
            message:
                'No alerts — all is well. Urgent health checks will appear here.',
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
                    Text(
                        'Volunteer: ${alert.volunteerName} (${alert.volunteerPhone ?? '-'})'),
                  if (alert.facilityName != null)
                    Text('Facility: ${alert.facilityName}'),
                ],
              ),
              trailing: IconButton(
                tooltip: 'Read aloud',
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  final parts = [
                    alert.summary,
                    if (alert.volunteerName != null)
                      'Volunteer ${alert.volunteerName} has been notified.',
                    if (alert.facilityName != null)
                      'Facility: ${alert.facilityName}.',
                  ];
                  ref.read(ttsProvider).speak(parts.join(' '));
                },
              ),
            ),
          ),
      ],
    );
  }
}

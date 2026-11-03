import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../../data/db/app_database.dart';
import '../../domain/diet_guide.dart';
import '../assessment/assessment_picker.dart';
import '../calendar/calendar_tab.dart';
import '../children/add_child_screen.dart';
import '../children/child_detail_screen.dart';
import '../companion/nana_companion.dart';
import '../diet/diet_screen.dart';
import '../nana/nana_chat_screen.dart';
import '../plus/plus_controller.dart';
import '../plus/plus_screen.dart';
import '../pregnancy/add_pregnancy_screen.dart';
import '../pregnancy/pregnancy_card.dart';
import '../pregnancy/pregnancies_screen.dart';
import '../pregnancy/pregnancy_records_screen.dart';
import '../report/report_providers.dart';
import '../report/weekly_report_screen.dart';
import '../settings/settings_screen.dart';
import '../tips/tips_tab.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(actionLoggerProvider).flush();
      ref.read(syncControllerProvider.notifier).sync();
      ref.read(widgetServiceProvider).refresh();
      ref.read(dietPlannerProvider).ensureTodayPlan();
      ref.read(tipsUpdaterProvider).ensureTodayTips();
      ref.read(modelServiceProvider).ensureLatest();
      ref.read(nluServiceProvider).ensureLatest();
      ref.read(slmServiceProvider).ensureLatest();
      final custom = await ref.read(dbProvider).upcomingCustomReminders();
      for (final r in custom) {
        ref
            .read(notificationServiceProvider)
            .schedule(
              reminderId: r.id,
              title: 'GrowWithMe reminder',
              body: r.title,
              when: r.dueDate,
            );
      }
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        ref.read(apiClientProvider).invalidateBaseUrl();
        ref.read(syncControllerProvider.notifier).sync();
        ref.read(dietPlannerProvider).ensureTodayPlan();
        ref.read(tipsUpdaterProvider).ensureTodayTips();
        ref.read(modelServiceProvider).ensureLatest();
        ref.read(nluServiceProvider).ensureLatest();
        ref.read(slmServiceProvider).ensureLatest();
      }
    });
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    _widgetClickSub = HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    if (uri.host == 'nana-briefing') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const NanaChatScreen(speakBriefingOnOpen: true),
        ),
      );
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _widgetClickSub?.cancel();
    super.dispose();
  }

  static const _titles = [
    'GrowWithMe',
    'Care calendar',
    'Food & tips',
    'Alerts',
  ];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(homeTabProvider);
    final syncState = ref.watch(syncControllerProvider);
    final alerts = ref.watch(alertsProvider).value ?? const [];
    final openAlerts = alerts.where((a) {
      final s = a.status.toLowerCase();
      return s != 'closed' && s != 'resolved' && s != 'cancelled';
    }).length;

    return Scaffold(
      extendBody: true,
      appBar: tab == 0
          ? null
          : AppBar(
              title: Text(_titles[tab]),
              actions: [
                _SyncAction(syncState: syncState),
                IconButton(
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: NanaCompanionLayer(
        child: switch (tab) {
          0 => _HomeTab(
            onOpenTab: (i) => ref.read(homeTabProvider.notifier).open(i),
          ),
          1 => const CalendarTab(),
          2 => const TipsTab(),
          _ => const _AlertsTab(),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          ref
              .read(actionLoggerProvider)
              .log(
                screen: 'tab:${_titles[i].toLowerCase()}',
                action: 'tab_switch',
                target: 'nav_$i',
              );
          ref.read(homeTabProvider.notifier).open(i);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded),
            label: 'Tips',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: openAlerts > 0,
              label: Text('$openAlerts'),
              backgroundColor: AppColors.coral,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: openAlerts > 0,
              label: Text('$openAlerts'),
              backgroundColor: AppColors.coral,
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

class _SyncAction extends ConsumerWidget {
  const _SyncAction({required this.syncState});

  final AsyncValue<DateTime?> syncState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Sync now',
      onPressed: syncState.isLoading
          ? null
          : () => ref.read(syncControllerProvider.notifier).sync(),
      icon: syncState.isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(switch (syncState) {
              AsyncError() => Icons.cloud_off_rounded,
              AsyncData() => Icons.cloud_done_rounded,
              _ => Icons.cloud_queue_rounded,
            }, color: syncState.hasError ? AppColors.coral : AppColors.forest),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

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

  String _relative(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(due.year, due.month, due.day);
    final days = d.difference(today).inDays;
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return 'In $days days';
    return DateFormat('d MMM').format(due);
  }

  void _readDayAloud(WidgetRef ref, List<ReminderRow> dueSoon) {
    final buffer = StringBuffer();
    if (dueSoon.isEmpty) {
      buffer.write('You have no clinic visits due this week. Well done. ');
    } else {
      buffer.write(
        'You have ${dueSoon.length} '
        'visit${dueSoon.length == 1 ? '' : 's'} coming up. ',
      );
      for (final r in dueSoon.take(3)) {
        buffer.write(
          '${DateFormat('EEEE d MMMM').format(r.dueDate)}: ${r.title}. ',
        );
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
    final firstName = (name ?? '').trim().split(' ').first;
    final syncState = ref.watch(syncControllerProvider);

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

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 118),
        children: [
          // ---- Header ----
          Row(
            children: [
              const BrandMark(size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GrowWithMe',
                      style: theme.textTheme.titleMedium?.copyWith(
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_greeting()}${firstName.isEmpty ? '' : ', $firstName'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _SyncAction(syncState: syncState),
              PressScale(
                borderRadius: 99,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.forest,
                    child: Text(
                      firstName.isEmpty
                          ? 'G'
                          : firstName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.lime,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ---- Nana hero ----
          _NanaHero(
            firstName: firstName,
            dueSoon: dueSoon,
            activePregnancy: activePregnancies.isEmpty
                ? null
                : activePregnancies.first,
            onOpenCalendar: () => onOpenTab(1),
            onSpeak: () => _readDayAloud(ref, dueSoon),
            onAskNana: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NanaChatScreen())),
            relative: _relative,
          ),
          const SizedBox(height: 20),

          // ---- Action grid ----
          const SectionHeader(
            title: 'What would you like to do?',
            padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
          ),
          // Two rows that grow with the content instead of a fixed-ratio grid,
          // so larger accessibility text never clips a tile caption.
          _QuickTileRow(
            children: [
              _QuickTile(
                icon: Icons.health_and_safety_rounded,
                title: 'Health check',
                subtitle: 'Symptoms & danger signs',
                color: AppColors.coral,
                background: AppColors.coralSoft,
                onTap: () {
                  ref
                      .read(actionLoggerProvider)
                      .log(
                        screen: 'home',
                        action: 'open_health_check',
                        target: 'quick_health_check',
                      );
                  startAssessmentPicker(context, ref);
                },
              ),
              _QuickTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Ask Nana',
                subtitle: 'Voice or chat, any time',
                color: AppColors.forest,
                background: AppColors.limeSoft,
                onTap: () {
                  ref
                      .read(actionLoggerProvider)
                      .log(
                        screen: 'home',
                        action: 'open_nana_chat',
                        target: 'quick_ask_nana',
                      );
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NanaChatScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _QuickTileRow(
            children: [
              _QuickTile(
                icon: Icons.calendar_month_rounded,
                title: 'Care calendar',
                subtitle: 'Visits & reminders',
                color: AppColors.sky,
                background: AppColors.skySoft,
                onTap: () {
                  ref
                      .read(actionLoggerProvider)
                      .log(
                        screen: 'home',
                        action: 'open_calendar',
                        target: 'quick_calendar',
                      );
                  onOpenTab(1);
                },
              ),
              _QuickTile(
                icon: Icons.family_restroom_rounded,
                title: 'My family',
                subtitle: 'Children & pregnancy',
                color: AppColors.rose,
                background: AppColors.roseSoft,
                onTap: () {
                  ref
                      .read(actionLoggerProvider)
                      .log(
                        screen: 'home',
                        action: 'open_add_child',
                        target: 'quick_my_family',
                      );
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddChildScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ---- Your week ----
          SectionHeader(
            title: 'Your week',
            subtitle: 'Nana\'s summary of the care you gave',
            actionLabel: 'See report',
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
            ),
          ),
          const _WeekCard(),
          const SizedBox(height: 8),
          const _PlusStrip(),
          const SizedBox(height: 22),

          // ---- Coming up ----
          SectionHeader(
            title: 'Coming up',
            subtitle: dueSoon.isEmpty
                ? 'Nothing due this week'
                : '${dueSoon.length} visit${dueSoon.length == 1 ? '' : 's'} in the next 7 days',
            actionLabel: 'Calendar',
            onAction: () => onOpenTab(1),
          ),
          if (dueSoon.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: Lottie.asset(
                      'assets/lottie/success_check.json',
                      repeat: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are on track',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No clinic visits due this week. Keep up the '
                          'good care.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < dueSoon.length && i < 3; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 76, endIndent: 16),
                    _VisitRow(
                      reminder: dueSoon[i],
                      relative: _relative(dueSoon[i].dueDate),
                      onTap: () => onOpenTab(1),
                    ),
                  ],
                  if (dueSoon.length > 3)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '+${dueSoon.length - 3} more on the calendar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 22),

          // ---- Children ----
          SectionHeader(
            title: 'My children',
            subtitle: children.isEmpty
                ? 'Add your first child to build their care calendar'
                : '${children.length} little one${children.length == 1 ? '' : 's'} growing strong',
            actionLabel: 'Add',
            onAction: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddChildScreen())),
          ),
          if (children.isEmpty)
            SurfaceCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Lottie.asset(
                      'assets/lottie/welcome_heart.json',
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Their care starts here',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Add a child and we will prepare every immunization '
                          'and weighing visit for you.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddChildScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add a child'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final child = children[i];
                  final next = nextVisitFor(child.id);
                  return _ChildCard(
                    child: child,
                    age: _age(child.dateOfBirth),
                    next: next,
                    color: _familyColors[i % _familyColors.length],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChildDetailScreen(child: child),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),

          // ---- Pregnancy journey ----
          if (activePregnancies.isNotEmpty) ...[
            SectionHeader(
              title: 'Pregnancy journey',
              subtitle: 'Weekly guidance and check-ins',
              actionLabel: activePregnancies.length > 1 ? 'See all' : null,
              onAction: activePregnancies.length > 1
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PregnanciesScreen(),
                      ),
                    )
                  : null,
            ),
            PregnancyCard(pregnancy: activePregnancies.first),
            const SizedBox(height: 14),
          ] else ...[
            SurfaceCard(
              gradient: AppColors.warmGradient,
              borderColor: AppColors.sand,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddPregnancyScreen()),
              ),
              child: Row(
                children: [
                  IconBubble(
                    icon: Icons.pregnant_woman_rounded,
                    color: AppColors.rose,
                    size: 46,
                    background: AppColors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expecting a little one?',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          'Track your pregnancy, ANC visits and weekly guidance.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.forest,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ---- Insights ----
          const _GlanceCharts(),
          const SizedBox(height: 16),
          const _TodayMealsCard(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.lock_rounded, size: 12, color: AppColors.faint),
              SizedBox(width: 4),
              Text(
                'Private · works offline · free for families',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.faint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _familyColors = [
  (AppColors.sky, AppColors.skySoft),
  (AppColors.rose, AppColors.roseSoft),
  (AppColors.forest, AppColors.limeSoft),
  (AppColors.violet, AppColors.violetSoft),
];

class _NanaHero extends StatelessWidget {
  const _NanaHero({
    required this.firstName,
    required this.dueSoon,
    required this.activePregnancy,
    required this.onOpenCalendar,
    required this.onSpeak,
    required this.onAskNana,
    required this.relative,
  });

  final String firstName;
  final List<ReminderRow> dueSoon;
  final PregnancyRow? activePregnancy;
  final VoidCallback onOpenCalendar;
  final VoidCallback onSpeak;
  final VoidCallback onAskNana;
  final String Function(DateTime) relative;

  String _message() {
    if (dueSoon.isNotEmpty) {
      final next = dueSoon.first;
      return 'Your next visit is ${next.title}, ${relative(next.dueDate).toLowerCase()}. '
          'I will remind you before then.';
    }
    if (activePregnancy != null) {
      final days = activePregnancy!.expectedDueDate
          .difference(DateTime.now())
          .inDays;
      final weeks = ((280 - days) / 7).round().clamp(1, 42);
      return 'You are about $weeks weeks along. Shall we see what this week '
          'holds for you and your baby?';
    }
    return 'You are all caught up this week. A good moment to log a meal, '
        'record a weight, or just talk.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppShadows.raised,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -70,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lime.withValues(alpha: 0.20),
                      AppColors.lime.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 18,
              top: 22,
              child: Sparkle(size: 14, color: AppColors.lime),
            ),
            Positioned(
              right: 64,
              bottom: 74,
              child: Sparkle(
                size: 8,
                color: AppColors.lime.withValues(alpha: 0.7),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM').format(now).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.lime,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          firstName.isEmpty
                              ? 'Hello, mama'
                              : 'Hello, $firstName',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppColors.cream,
                            fontSize: 33,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onAskNana,
                        child: const NanaPortrait(
                          size: 62,
                          alive: true,
                          asset: 'assets/illustrations/nana_happy.webp',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onAskNana,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.forestDeep,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nana',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.lime,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _message(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.cream,
                                    height: 1.42,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LimeButton(
                          label: 'See calendar',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: onOpenCalendar,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        label: 'Read today aloud',
                        button: true,
                        child: GestureDetector(
                          onTap: onSpeak,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: const Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.cream,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTileRow extends StatelessWidget {
  const _QuickTileRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconBubble(
                icon: icon,
                color: color,
                size: 36,
                iconSize: 18,
                background: background,
              ),
              const Spacer(),
              const Icon(
                Icons.north_east_rounded,
                size: 14,
                color: AppColors.faint,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({
    required this.reminder,
    required this.relative,
    required this.onTap,
  });

  final ReminderRow reminder;
  final String relative;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = relative == 'Today';
    return PressScale(
      borderRadius: AppRadii.lg,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 54,
              decoration: BoxDecoration(
                color: isToday ? AppColors.limeSoft : AppColors.creamDeep,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday ? AppColors.lime : AppColors.line,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM').format(reminder.dueDate).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isToday ? AppColors.limeInk : AppColors.muted,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(reminder.dueDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 19,
                      height: 1.05,
                      color: isToday ? AppColors.limeInk : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isToday ? AppColors.coral : AppColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        relative,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isToday ? AppColors.coral : AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.age,
    required this.next,
    required this.color,
    required this.onTap,
  });

  final ChildRow child;
  final String age;
  final ReminderRow? next;
  final (Color, Color) color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (accent, tint) = color;
    return SizedBox(
      width: 152,
      child: SurfaceCard(
        padding: const EdgeInsets.all(13),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    child.name.characters.first.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontSize: 17,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, size: 18, color: accent),
              ],
            ),
            const Spacer(),
            Text(
              child.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 1),
            Text(
              age,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                next == null
                    ? 'All visits on track'
                    : 'Next: ${DateFormat('d MMM').format(next!.dueDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontSize: 9.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual trends at a glance: diet diversity bars and the pregnancy risk wave.
class _GlanceCharts extends ConsumerWidget {
  const _GlanceCharts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logs = ref.watch(recentDietLogsProvider).value ?? const [];
    final riskRecords =
        ref.watch(pregnancyAssessmentsProvider).value ?? const [];
    if (logs.isEmpty && riskRecords.isEmpty) {
      return SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            IconBubble(
              icon: Icons.insights_rounded,
              color: AppColors.forest,
              size: 40,
              iconSize: 19,
              background: AppColors.limeSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your health charts will appear here after your first '
                'check-in or meal log.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Your health at a glance',
          subtitle: 'Small steps, visible progress',
        ),
        Row(
          children: [
            if (logs.isNotEmpty)
              Expanded(
                child: _MiniChartCard(
                  title: 'Diet this week',
                  emoji: '🥗',
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const DietScreen())),
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
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: logs.reversed
                                    .toList()[i]
                                    .score
                                    .toDouble()
                                    .clamp(0.3, 8),
                                width: 9,
                                borderRadius: BorderRadius.circular(3),
                                color: logs.reversed.toList()[i].score >= 5
                                    ? AppColors.forest
                                    : AppColors.amber,
                              ),
                            ],
                          ),
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
                  title: 'Pregnancy risk',
                  emoji: '❤️',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PregnancyRecordsScreen(),
                    ),
                  ),
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
                                },
                              ),
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 2.6,
                          color: AppColors.forest,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, _, i) =>
                                FlDotCirclePainter(
                                  radius: 3,
                                  color: switch (riskRecords[spot.x.toInt()]
                                      .riskLevel) {
                                    'urgent' => AppColors.coral,
                                    'moderate' => AppColors.amber,
                                    _ => AppColors.teal,
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
  const _MiniChartCard({
    required this.title,
    required this.emoji,
    required this.child,
    required this.onTap,
  });

  final String title;
  final String emoji;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.faint,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(height: 64, child: child),
        ],
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

    return SurfaceCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8E9), Color(0xFFF9EDD5)],
      ),
      borderColor: const Color(0xFFF0E0BF),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const DietScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🍲', style: TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s meals from Nana',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Balanced for you and your family',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Read aloud',
                icon: const Icon(Icons.volume_up_rounded, size: 19),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkSoft,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final slot in slots.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (slot['time']) {
                    'Morning' => '🌅 ',
                    'Midday' => '☀️ ',
                    'Evening' => '🌙 ',
                    _ => '🍌 ',
                  }, style: const TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      (slot['options'] as List)
                          .map((o) => o['name'])
                          .join(' / '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertsTab extends ConsumerWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alerts = ref.watch(alertsProvider).value ?? const [];
    final active = alerts.where((a) {
      final s = a.status.toLowerCase();
      return s != 'closed' && s != 'resolved' && s != 'cancelled';
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        if (alerts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    'assets/lottie/success_check.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 10),
                Text('All is well', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'Urgent health checks and referral updates will appear here. '
                  'When something needs attention, help is already moving.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else ...[
          SurfaceCard(
            gradient: AppColors.heroGradient,
            borderColor: AppColors.forest,
            child: Row(
              children: [
                const IconBubble(
                  icon: Icons.emergency_rounded,
                  color: AppColors.lime,
                  size: 44,
                  background: Color(0x22FFFFFF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.isEmpty
                            ? 'No open alerts'
                            : '${active.length} open alert${active.length == 1 ? '' : 's'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.cream,
                        ),
                      ),
                      Text(
                        active.isEmpty
                            ? 'Every referral has been closed'
                            : 'Your care team is following up',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.cream.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final alert in alerts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconBubble(
                      icon: Icons.health_and_safety_rounded,
                      color: AppColors.coral,
                      size: 40,
                      iconSize: 19,
                      background: AppColors.coralSoft,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  alert.summary,
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              Pill(
                                label: alert.status.toUpperCase(),
                                dense: true,
                                foreground: AppColors.forest,
                                background: AppColors.limeSoft,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (alert.volunteerName != null)
                            _AlertLine(
                              icon: Icons.volunteer_activism_rounded,
                              text:
                                  '${alert.volunteerName} · ${alert.volunteerPhone ?? ''}',
                            ),
                          if (alert.facilityName != null)
                            _AlertLine(
                              icon: Icons.local_hospital_rounded,
                              text: alert.facilityName!,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Read aloud',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
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
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// A compact glimpse of the weekly report, so the feature is discoverable
/// without opening Settings.
class _WeekCard extends ConsumerWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final report = ref.watch(weeklyReportProvider(0));
    final score = report?.careScore;

    final parts = <String>[];
    if (report != null) {
      if (report.visitsDue > 0) {
        parts.add('${report.visitsDone}/${report.visitsDue} visits');
      }
      parts.add(
        '${report.healthChecks} check${report.healthChecks == 1 ? '' : 's'}',
      );
      parts.add('${report.mealDays}/7 meal days');
    }

    final summary = report == null
        ? 'Gathering this week…'
        : !report.hasActivity
        ? 'A gentle start. One small step today is enough.'
        : parts.join(' · ');

    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      onTap: () {
        ref
            .read(actionLoggerProvider)
            .log(screen: 'home', action: 'open_report', target: 'week_card');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WeeklyReportScreen()));
      },
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: score == null ? null : AppColors.heroGradient,
              color: score == null ? AppColors.creamDeep : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: score == null ? AppColors.line : AppColors.forest,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (score == null)
                  const Icon(
                    Icons.spa_rounded,
                    size: 22,
                    color: AppColors.forest,
                  )
                else
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 23,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  score == null ? 'WEEK' : 'SCORE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: score == null ? AppColors.muted : AppColors.lime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report?.scoreLabel ?? 'Your week',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                if (report != null && report.activeDays > 0) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Showed up ${report.activeDays} of 7 days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.teal,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
        ],
      ),
    );
  }
}

/// A slim, honest upsell. It disappears the moment Plus is active.
class _PlusStrip extends ConsumerWidget {
  const _PlusStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlus = ref.watch(isPlusProvider);
    if (isPlus) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return SurfaceCard(
      gradient: AppColors.heroGradient,
      borderColor: AppColors.forest,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      onTap: () {
        ref
            .read(actionLoggerProvider)
            .log(screen: 'home', action: 'open_plus', target: 'plus_strip');
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PlusScreen()));
      },
      child: Row(
        children: [
          const NanaPortrait(
            size: 38,
            glow: false,
            showRing: true,
            asset: 'assets/illustrations/nana_happy.webp',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nana Plus',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.cream,
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Pill(
                      label: 'NEW',
                      dense: true,
                      foreground: AppColors.limeInk,
                      background: AppColors.lime,
                    ),
                  ],
                ),
                Text(
                  '12 weeks of reports · every insight · card styles',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.72),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.lime,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

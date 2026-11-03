import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../../domain/weekly_report.dart';
import '../children/add_child_screen.dart';
import '../plus/plus_controller.dart';
import '../plus/plus_screen.dart';
import 'report_providers.dart';

/// The family's week, told back to them warmly — and ready to share.
///
/// The report itself is free and always on-device. Nana Plus keeps twelve
/// weeks of history and unlocks every card style and the full insight list.
class WeeklyReportScreen extends ConsumerStatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  ConsumerState<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends ConsumerState<WeeklyReportScreen> {
  final GlobalKey _cardKey = GlobalKey();

  int _weekOffset = 0;
  int _themeIndex = 0;
  bool _sharing = false;

  DateTime get _anchor =>
      dayStart(DateTime.now()).subtract(Duration(days: 7 * _weekOffset));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = ref.watch(weeklyReportProvider(_weekOffset));
    final plus = ref.watch(plusProvider).value ?? const PlusState.free();
    final isPlus = plus.isActive;
    final limit = reportHistoryLimit(isPlus);
    // Prefer the report's own window so a midnight rollover can never leave
    // the date label a day behind the numbers underneath it. `end` is the
    // inclusive last day of the window.
    final windowEnd = report?.end ?? _anchor;
    final windowStart = windowEnd.subtract(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly report'),
        actions: [
          IconButton(
            tooltip: 'Share this week',
            onPressed: report == null || _sharing
                ? null
                : () => _share(report, plus),
            icon: _sharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 44),
          children: [
            _WeekSwitcher(
              title: _weekTitle(_weekOffset),
              range:
                  '${DateFormat('d MMM').format(windowStart)} – '
                  '${DateFormat('d MMM yyyy').format(windowEnd)}',
              canGoForward: _weekOffset > 0,
              canGoBack: _weekOffset < limit - 1 || !isPlus,
              onPrevious: () => _goToWeek(_weekOffset + 1, isPlus),
              onNext: () => _goToWeek(_weekOffset - 1, isPlus),
            ),
            const SizedBox(height: 14),
            if (report == null)
              const _ReportLoading()
            else ...[
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ReportShareCard(
                      report: report,
                      cardTheme: _cardThemes[_themeIndex],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _ThemePicker(
                selected: _themeIndex,
                isPlus: isPlus,
                onSelect: (index) {
                  if (index > 0 && !isPlus) {
                    _askForPlus(
                      'Every card style',
                      'Nana Plus unlocks the Sunrise and Heritage cards, '
                          'along with twelve weeks of reports.',
                    );
                    return;
                  }
                  setState(() => _themeIndex = index);
                },
              ),
              const SizedBox(height: 20),
              const SectionHeader(
                title: 'This week in numbers',
                subtitle: 'Only what you recorded — nothing more',
                padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
              ),
              _MetricGrid(report: report),
              const SizedBox(height: 16),
              _ScoreBreakdown(report: report),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Nana\'s insights',
                subtitle: isPlus
                    ? 'Every pattern she noticed this week'
                    : '${report.insights.take(3).length} of ${report.insights.length} insights · rest with Nana Plus',
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              ),
              _InsightsCard(
                report: report,
                isPlus: isPlus,
                onUnlock: () => _askForPlus(
                  'All of Nana\'s insights',
                  'Nana Plus reveals every weekly insight, not just the '
                      'first three.',
                ),
              ),
              if (report.children.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Your children',
                  subtitle: 'Growing, measured, and remembered',
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
                ),
                _ChildrenCard(children: report.children),
              ],
              if (report.activePregnancies > 0) ...[
                const SizedBox(height: 14),
                _PregnancyWeekCard(report: report),
              ],
              if (!report.hasFamily) ...[
                const SizedBox(height: 14),
                _EmptyFamilyCard(
                  onAdd: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddChildScreen()),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (isPlus)
                _PlusActiveCard(
                  plus: plus,
                  onManage: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const PlusScreen())),
                )
              else
                _PlusInvite(
                  onOpen: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const PlusScreen())),
                ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: AppColors.faint,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Built on this phone · never uploaded to make a report',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.faint,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _weekTitle(int offset) {
    if (offset == 0) return 'This week';
    if (offset == 1) return 'Last week';
    final start = dayStart(
      DateTime.now(),
    ).subtract(Duration(days: 6 + 7 * offset));
    return 'Week of ${DateFormat('d MMM').format(start)}';
  }

  void _goToWeek(int offset, bool isPlus) {
    if (_sharing) return;
    if (offset > 0 && !isPlus) {
      _askForPlus(
        'Keep every week',
        'Your current week is always free. Nana Plus keeps the last twelve '
            'weeks ready to revisit and share.',
      );
      return;
    }
    if (offset < 0 || offset >= kPlusReportWeeks) return;
    setState(() => _weekOffset = offset);
    ref
        .read(actionLoggerProvider)
        .log(
          screen: 'report',
          action: 'week_switch',
          target: 'report_week',
          params: {'step': offset},
        );
  }

  Future<void> _askForPlus(String title, String body) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('See Nana Plus'),
          ),
        ],
      ),
    );
    if (go == true && mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PlusScreen()));
    }
  }

  String _shareText(WeeklyReport report) {
    final score = report.careScore;
    final lines = <String>[
      report.firstName == null
          ? 'Our week with GrowWithMe'
          : '${report.firstName}\'s week with GrowWithMe',
      if (score != null) 'Care score: $score/100 · ${report.scoreLabel}',
      if (report.visitsDue > 0)
        'Care visits: ${report.visitsDone} of ${report.visitsDue}',
      'Health checks: ${report.healthChecks}',
      'Meal days: ${report.mealDays} of 7',
      if (report.children.isNotEmpty)
        'Growing: ${report.children.map((c) => '${c.firstName} (${c.ageLabel})').join(', ')}',
      'Tracked privately on my phone with GrowWithMe.',
    ];
    return lines.join('\n');
  }

  Future<void> _share(WeeklyReport report, PlusState plus) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final watch = Stopwatch()..start();
    final text = _shareText(report);
    // Resolved up front so the async share never touches [ref] after the
    // screen could have been popped.
    final logger = ref.read(actionLoggerProvider);
    final weekOffset = _weekOffset;

    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }

    var logged = false;
    try {
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError('Report card is not ready');
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode the card');
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/growwithme-week-${dayKey(report.end)}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await logger.log(
        screen: 'report',
        action: 'share_report',
        target: 'weekly_card',
        params: {'step': weekOffset, 'source': 'image'},
        success: true,
        durationMs: watch.elapsedMilliseconds,
      );
      logged = true;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: text,
          subject: 'My week of care with GrowWithMe',
          sharePositionOrigin: origin,
        ),
      );
      await logger.log(
        screen: 'report',
        action: 'share_completed',
        target: 'weekly_card',
        params: {'step': weekOffset, 'source': 'image'},
      );
    } catch (_) {
      if (!logged) {
        await logger.log(
          screen: 'report',
          action: 'share_report',
          target: 'weekly_card',
          params: {'step': weekOffset, 'source': 'image'},
          success: false,
          durationMs: watch.elapsedMilliseconds,
        );
      }
      // Text-only fallback keeps the moment useful even if the image could
      // not be rendered or a share target rejects files.
      var fellBack = false;
      try {
        await SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: 'My week of care with GrowWithMe',
            sharePositionOrigin: origin,
          ),
        );
        fellBack = true;
      } catch (_) {}
      if (!fellBack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sharing is not available right now. '
              'Your report is still saved on this phone.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Share card
// ---------------------------------------------------------------------------

class ReportCardTheme {
  const ReportCardTheme({
    required this.name,
    required this.colors,
    required this.ink,
    required this.subtle,
    required this.accent,
    required this.chip,
    required this.chipInk,
    required this.line,
  });

  final String name;
  final List<Color> colors;
  final Color ink;
  final Color subtle;
  final Color accent;
  final Color chip;
  final Color chipInk;
  final Color line;
}

const _cardThemes = [
  ReportCardTheme(
    name: 'Forest',
    colors: [Color(0xFF124C3A), Color(0xFF06241B)],
    ink: AppColors.cream,
    subtle: Color(0xCCFBF7EC),
    accent: AppColors.lime,
    chip: Color(0x14FFFFFF),
    chipInk: AppColors.cream,
    line: Color(0x20FFFFFF),
  ),
  ReportCardTheme(
    name: 'Sunrise',
    colors: [Color(0xFFFF8A63), Color(0xFFD94722)],
    ink: AppColors.white,
    subtle: Color(0xD9FFFFFF),
    accent: Color(0xFFFFE9A8),
    chip: Color(0x26FFFFFF),
    chipInk: AppColors.white,
    line: Color(0x33FFFFFF),
  ),
  ReportCardTheme(
    name: 'Heritage',
    colors: [Color(0xFFF9F0DC), Color(0xFFEADCC0)],
    ink: AppColors.forestDeep,
    subtle: Color(0xCC3C4D45),
    accent: AppColors.coral,
    chip: Color(0xEFFFFFFF),
    chipInk: AppColors.forestDeep,
    line: Color(0xFFDCCBA8),
  ),
];

/// A 4:5 poster, sized for WhatsApp status and Instagram. Captured at 3x,
/// so the exported PNG is 1080 x 1350.
class ReportShareCard extends StatelessWidget {
  const ReportShareCard({
    super.key,
    required this.report,
    required this.cardTheme,
  });

  final WeeklyReport report;
  final ReportCardTheme cardTheme;

  @override
  Widget build(BuildContext context) {
    final score = report.careScore;
    final names = report.children.take(2).map((c) => c.firstName).join(' & ');
    final title = report.firstName == null
        ? 'A week of care'
        : '${report.firstName}\'s week';

    // The poster is a graphic, so it keeps its designed type scale instead of
    // inheriting a large accessibility text size that would break the layout.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: 360,
        height: 450,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardTheme.colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                top: -90,
                child: _CardGlow(color: cardTheme.accent, size: 250),
              ),
              Positioned(
                left: -60,
                bottom: -100,
                child: _CardGlow(
                  color: cardTheme.accent.withValues(alpha: 0.5),
                  size: 240,
                ),
              ),
              Positioned(
                right: 26,
                top: 66,
                child: Sparkle(
                  size: 12,
                  color: cardTheme.accent.withValues(alpha: 0.9),
                ),
              ),
              Positioned(
                left: 28,
                bottom: 116,
                child: Sparkle(
                  size: 7,
                  color: cardTheme.accent.withValues(alpha: 0.55),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BrandMark(size: 26, showShadow: false),
                        const SizedBox(width: 9),
                        Text(
                          'GrowWithMe',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: cardTheme.ink,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cardTheme.chip,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: cardTheme.line),
                          ),
                          child: Text(
                            'WEEK OF ${DateFormat('d MMM').format(report.start).toUpperCase()}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                              color: cardTheme.chipInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 27,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: cardTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.scoreLabel.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: cardTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (score != null) ...[
                          Text(
                            score.toString(),
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 78,
                              height: 0.94,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                              color: cardTheme.ink,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 7, bottom: 10),
                            child: Text(
                              '/100\nCARE SCORE',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 8.5,
                                height: 1.35,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                                color: cardTheme.subtle,
                              ),
                            ),
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nothing logged',
                                  style: TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 30,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: cardTheme.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ADD ONE SMALL STEP',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.4,
                                    color: cardTheme.subtle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        NanaPortrait(
                          size: 56,
                          glow: false,
                          showRing: true,
                          asset: 'assets/illustrations/nana_happy.webp',
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardTheme.chip,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cardTheme.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: cardTheme.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              report.closingLine,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: cardTheme.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ShareStat(
                            value: report.visitsDue == 0
                                ? '—'
                                : '${report.visitsDone}/${report.visitsDue}',
                            label: 'VISITS',
                            theme: cardTheme,
                          ),
                        ),
                        _StatDivider(color: cardTheme.line),
                        Expanded(
                          child: _ShareStat(
                            value: '${report.healthChecks}',
                            label: 'CHECKS',
                            theme: cardTheme,
                          ),
                        ),
                        _StatDivider(color: cardTheme.line),
                        Expanded(
                          child: _ShareStat(
                            value: '${report.mealDays}/7',
                            label: 'MEAL DAYS',
                            theme: cardTheme,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            names.isEmpty
                                ? 'Tracked privately on this phone'
                                : names,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: cardTheme.subtle,
                            ),
                          ),
                        ),
                        Text(
                          'TOVO LABs',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: cardTheme.subtle,
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
      ),
    );
  }
}

class _CardGlow extends StatelessWidget {
  const _CardGlow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({
    required this.value,
    required this.label,
    required this.theme,
  });

  final String value;
  final String label;
  final ReportCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: theme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: theme.subtle,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: color,
    );
  }
}

// ---------------------------------------------------------------------------
// Screen sections
// ---------------------------------------------------------------------------

class _WeekSwitcher extends StatelessWidget {
  const _WeekSwitcher({
    required this.title,
    required this.range,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String range;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous week',
            onPressed: canGoBack ? onPrevious : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  range,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Next week',
            onPressed: canGoForward ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReportLoading extends StatelessWidget {
  const _ReportLoading();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 14),
          Text(
            'Gathering your week…',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 3),
          Text(
            'Reading only what is stored on this phone.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({
    required this.selected,
    required this.isPlus,
    required this.onSelect,
  });

  final int selected;
  final bool isPlus;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          'Card style',
          style: theme.textTheme.labelMedium?.copyWith(color: AppColors.muted),
        ),
        const Spacer(),
        for (var i = 0; i < _cardThemes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _ThemeSwatch(
            theme: _cardThemes[i],
            selected: selected == i,
            locked: i > 0 && !isPlus,
            onTap: () => onSelect(i),
          ),
        ],
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final ReportCardTheme theme;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${theme.name} card${locked ? ', Nana Plus' : ''}',
      button: true,
      selected: selected,
      child: PressScale(
        borderRadius: 99,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: theme.colors),
            ),
            child: selected
                ? const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: AppColors.white,
                  )
                : locked
                ? const Icon(
                    Icons.lock_rounded,
                    size: 12,
                    color: AppColors.white,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final visitCaption = report.visitsDue == 0
        ? 'No visits due'
        : report.visitsMissed > 0
        ? '${report.visitsMissed} missed · ${report.visitsUpcoming} ahead'
        : report.visitsUpcoming > 0
        ? '${report.visitsUpcoming} still ahead'
        : 'Every visit done';

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.event_available_rounded,
                  accent: AppColors.forest,
                  tint: AppColors.limeSoft,
                  value: report.visitsDue == 0 ? '—' : '${report.visitsDone}',
                  suffix: report.visitsDue == 0 ? null : '/${report.visitsDue}',
                  label: 'Care visits',
                  caption: visitCaption,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.health_and_safety_rounded,
                  accent: AppColors.coral,
                  tint: AppColors.coralSoft,
                  value: '${report.healthChecks}',
                  label: 'Health checks',
                  caption: report.urgentChecks > 0
                      ? '${report.urgentChecks} needs follow-up'
                      : report.healthChecks > 0
                      ? 'Checked with Nana'
                      : 'No checks yet',
                  captionColor: report.urgentChecks > 0
                      ? AppColors.coral
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.restaurant_rounded,
                  accent: AppColors.amber,
                  tint: AppColors.amberSoft,
                  value: '${report.mealDays}',
                  suffix: '/7',
                  label: 'Meal days',
                  caption: report.mealDays > 0
                      ? '${report.avgPlateScore}/10 plate variety'
                      : 'Log a plate in Nana\'s Kitchen',
                  extra: _MealDots(
                    pattern: report.mealPattern,
                    start: report.start,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: Icons.monitor_weight_rounded,
                  accent: AppColors.violet,
                  tint: AppColors.violetSoft,
                  value: '${report.growthChecks}',
                  label: 'Growth checks',
                  caption: report.children.isEmpty
                      ? 'Add a child to track'
                      : report.growthChecks > 0
                      ? 'Measured this week'
                      : 'No weighing yet',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.accent,
    required this.tint,
    required this.value,
    this.suffix,
    required this.label,
    required this.caption,
    this.captionColor,
    this.extra,
  });

  final IconData icon;
  final Color accent;
  final Color tint;
  final String value;
  final String? suffix;
  final String label;
  final String caption;
  final Color? captionColor;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            color: accent,
            size: 34,
            iconSize: 17,
            background: tint,
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  height: 1,
                  color: AppColors.ink,
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 1),
                  child: Text(
                    suffix!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.faint,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: captionColor ?? AppColors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          if (extra != null) ...[const SizedBox(height: 9), extra!],
        ],
      ),
    );
  }
}

class _MealDots extends StatelessWidget {
  const _MealDots({required this.pattern, required this.start});

  final List<bool> pattern;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < pattern.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == pattern.length - 1 ? 0 : 3),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: pattern[i] ? AppColors.amber : AppColors.creamDeep,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('E')
                        .format(start.add(Duration(days: i)))
                        .characters
                        .first
                        .toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.faint,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visits = report.visitsDue == 0
        ? null
        : (report.visitsDone / report.visitsDue).clamp(0.0, 1.0);
    final checks = !report.hasFamily
        ? null
        : (report.healthChecks / 2).clamp(0.0, 1.0);
    final meals = !report.hasFamily
        ? null
        : ((report.mealDays / 7) * 0.6 + (report.avgPlateScore / 10) * 0.4)
              .clamp(0.0, 1.0);
    final growth = report.children.isEmpty
        ? null
        : (report.growthChecks > 0 ? 1.0 : 0.0);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBubble(
                icon: Icons.insights_rounded,
                color: AppColors.forest,
                size: 38,
                iconSize: 18,
                background: AppColors.limeSoft,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How your score is built',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      'Only the care you recorded is counted — no penalty for '
                      'a quiet week.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FactorBar(
            label: 'Care visits',
            weight: '40%',
            value: visits,
            color: AppColors.sky,
          ),
          const SizedBox(height: 11),
          _FactorBar(
            label: 'Health checks',
            weight: '25%',
            value: checks,
            color: AppColors.coral,
          ),
          const SizedBox(height: 11),
          _FactorBar(
            label: 'Meals & variety',
            weight: '20%',
            value: meals,
            color: AppColors.amber,
          ),
          const SizedBox(height: 11),
          _FactorBar(
            label: 'Growth checks',
            weight: '15%',
            value: growth,
            color: AppColors.violet,
          ),
        ],
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({
    required this.label,
    required this.weight,
    required this.value,
    required this.color,
  });

  final String label;
  final String weight;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              v == null ? 'Not enough data' : '${(v * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: v == null ? AppColors.faint : AppColors.ink,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              weight,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.faint,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: v ?? 0,
            minHeight: 6,
            backgroundColor: AppColors.creamDeep,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.report,
    required this.isPlus,
    required this.onUnlock,
  });

  final WeeklyReport report;
  final bool isPlus;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final visible = isPlus ? report.insights : report.insights.take(3).toList();
    final hidden = report.insights.length - visible.length;
    final theme = Theme.of(context);

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56, endIndent: 16),
            _InsightRow(insight: visible[i]),
          ],
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Nana is still reading this week. Log a meal or a check-in '
                'and her notes will appear here.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ),
          if (hidden > 0)
            PressScale(
              borderRadius: AppRadii.lg,
              onTap: onUnlock,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$hidden more insight${hidden == 1 ? '' : 's'} this '
                        'week with Nana Plus',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.forest,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final ReportInsight insight;

  @override
  Widget build(BuildContext context) {
    final (icon, color, tint) = switch (insight.tone) {
      ReportTone.win => (
        Icons.check_circle_rounded,
        AppColors.teal,
        AppColors.tealSoft,
      ),
      ReportTone.nudge => (
        Icons.lightbulb_rounded,
        AppColors.amber,
        AppColors.amberSoft,
      ),
      ReportTone.alert => (
        Icons.emergency_rounded,
        AppColors.coral,
        AppColors.coralSoft,
      ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              insight.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildrenCard extends StatelessWidget {
  const _ChildrenCard({required this.children});

  final List<ChildWeekSnapshot> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.limeSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      children[i].firstName.characters.first.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.forest,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          children[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          children[i].ageLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        children[i].latestWeightKg == null
                            ? 'Not weighed'
                            : '${children[i].latestWeightKg!.toStringAsFixed(1)} kg',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: children[i].latestWeightKg == null
                              ? AppColors.faint
                              : AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Pill(
                        label: children[i].measuredThisWeek
                            ? 'THIS WEEK'
                            : 'EARLIER',
                        dense: true,
                        foreground: children[i].measuredThisWeek
                            ? AppColors.teal
                            : AppColors.muted,
                        background: children[i].measuredThisWeek
                            ? AppColors.tealSoft
                            : AppColors.creamDeep,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PregnancyWeekCard extends StatelessWidget {
  const _PregnancyWeekCard({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      gradient: AppColors.warmGradient,
      borderColor: AppColors.sand,
      child: Row(
        children: [
          const IconBubble(
            icon: Icons.pregnant_woman_rounded,
            color: AppColors.rose,
            size: 42,
            background: AppColors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.pregnancyWeek == null
                      ? 'Pregnancy journey'
                      : 'Pregnancy · week ${report.pregnancyWeek}',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  report.activePregnancies == 1
                      ? 'One active journey on this phone'
                      : '${report.activePregnancies} active journeys on this phone',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
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

class _EmptyFamilyCard extends StatelessWidget {
  const _EmptyFamilyCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      gradient: AppColors.warmGradient,
      borderColor: AppColors.sand,
      child: Row(
        children: [
          const IconBubble(
            icon: Icons.child_care_rounded,
            color: AppColors.rose,
            size: 42,
            background: AppColors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add your first child', style: theme.textTheme.titleSmall),
                Text(
                  'Then next week\'s report has a story to tell.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onAdd, child: const Text('Add')),
        ],
      ),
    );
  }
}

class _PlusInvite extends StatelessWidget {
  const _PlusInvite({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      gradient: AppColors.heroGradient,
      borderColor: AppColors.forest,
      onTap: onOpen,
      child: Row(
        children: [
          const NanaPortrait(
            size: 48,
            alive: true,
            asset: 'assets/illustrations/nana_happy.webp',
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 3),
                Text(
                  'Keep 12 weeks · every insight · all card styles',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.cream.withValues(alpha: 0.76),
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.lime,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PlusActiveCard extends StatelessWidget {
  const _PlusActiveCard({required this.plus, required this.onManage});

  final PlusState plus;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      onTap: onManage,
      child: Row(
        children: [
          const IconBubble(
            icon: Icons.workspace_premium_rounded,
            color: AppColors.forest,
            size: 42,
            background: AppColors.limeSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plus.statusLine, style: theme.textTheme.titleSmall),
                const SizedBox(height: 1),
                Text(
                  plus.renewalLine,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onManage, child: const Text('Manage')),
        ],
      ),
    );
  }
}

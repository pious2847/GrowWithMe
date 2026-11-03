import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import '../assessment/assessment_picker.dart';
import '../children/add_child_screen.dart';
import '../diet/diet_screen.dart';
import '../nana/nana_chat_screen.dart';

/// How Nana is feeling — drives the expression swap and the halo behaviour.
enum CompanionMood { idle, listening, thinking, speaking }

class CompanionMoodController extends Notifier<CompanionMood> {
  @override
  CompanionMood build() => CompanionMood.idle;

  void set(CompanionMood mood) => state = mood;

  void reset() => state = CompanionMood.idle;
}

final companionMoodProvider =
    NotifierProvider<CompanionMoodController, CompanionMood>(
      CompanionMoodController.new,
    );

class CompanionVisibility extends AsyncNotifier<bool> {
  static const _key = 'companionVisible';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  Future<void> setVisible(bool visible) async {
    state = AsyncData(visible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, visible);
  }
}

final companionVisibleProvider =
    AsyncNotifierProvider<CompanionVisibility, bool>(CompanionVisibility.new);

const _moodAssets = {
  CompanionMood.idle: 'assets/illustrations/nana_happy.webp',
  CompanionMood.listening: 'assets/illustrations/nana_listening.webp',
  CompanionMood.thinking: 'assets/illustrations/nana_thinking.webp',
  CompanionMood.speaking: 'assets/illustrations/nana_speaking.webp',
};

/// Wraps any screen and floats Nana above it.
///
/// The companion is intentionally always reachable: a caregiver should never
/// have to find a menu to ask for help. She can be dragged anywhere, snaps to
/// the nearest edge and remembers where she was left. Tap opens her quick
/// actions; hold to speak to her; rest her from the sheet or Settings.
class NanaCompanionLayer extends ConsumerStatefulWidget {
  const NanaCompanionLayer({
    super.key,
    required this.child,
    this.bottomInset = 96,
    this.showBubbleOnStart = true,
  });

  final Widget child;
  final double bottomInset;
  final bool showBubbleOnStart;

  @override
  ConsumerState<NanaCompanionLayer> createState() => _NanaCompanionLayerState();
}

class _NanaCompanionLayerState extends ConsumerState<NanaCompanionLayer>
    with TickerProviderStateMixin {
  static const _size = 68.0;
  static const _edge = 14.0;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat(reverse: true);

  double _fx = 0.88;
  double _fy = 0.78;
  bool _dragging = false;
  bool _showBubble = false;
  Timer? _bubbleTimer;
  Timer? _moodTimer;

  @override
  void initState() {
    super.initState();
    _restorePosition();
    _moodTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || _dragging) return;
      if (ref.read(companionMoodProvider) == CompanionMood.speaking) return;
      const cycle = [
        CompanionMood.idle,
        CompanionMood.idle,
        CompanionMood.listening,
        CompanionMood.thinking,
      ];
      ref
          .read(companionMoodProvider.notifier)
          .set(cycle[math.Random().nextInt(cycle.length)]);
    });
    if (widget.showBubbleOnStart) _greetOnceToday();
  }

  Future<void> _restorePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final fx = prefs.getDouble('companionFx');
    final fy = prefs.getDouble('companionFy');
    if (!mounted) return;
    setState(() {
      if (fx != null) _fx = fx.clamp(0.1, 0.9);
      if (fy != null) _fy = fy.clamp(0.15, 0.9);
    });
  }

  Future<void> _greetOnceToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final stamp = '${today.year}-${today.month}-${today.day}';
    if (prefs.getString('companionGreetedOn') == stamp) return;
    await prefs.setString('companionGreetedOn', stamp);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _showBubble = true);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 9), () {
      if (mounted) setState(() => _showBubble = false);
    });
  }

  void _persistPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('companionFx', _fx);
    await prefs.setDouble('companionFy', _fy);
  }

  void _openSheet() {
    HapticFeedback.selectionClick();
    ref.read(companionMoodProvider.notifier).set(CompanionMood.listening);
    setState(() => _showBubble = false);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CompanionSheet(),
    ).whenComplete(() {
      if (mounted) ref.read(companionMoodProvider.notifier).reset();
    });
  }

  /// Hold the avatar to speak — the fastest path from "I am worried" to help.
  void _openVoice() {
    HapticFeedback.mediumImpact();
    setState(() => _showBubble = false);
    ref.read(companionMoodProvider.notifier).set(CompanionMood.listening);
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const NanaChatScreen(voiceMode: true),
          ),
        )
        .whenComplete(() {
          if (mounted) ref.read(companionMoodProvider.notifier).reset();
        });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _moodTimer?.cancel();
    _pulse.dispose();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(companionVisibleProvider).value ?? true;
    if (!visible) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final left = (_fx * w - _size / 2)
            .clamp(_edge, w - _size - _edge)
            .toDouble();
        final top = (_fy * h - _size / 2)
            .clamp(14.0, math.max(14.0, h - _size - widget.bottomInset))
            .toDouble();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            if (_showBubble)
              Positioned(
                left: (left - 190).clamp(10.0, math.max(10.0, w - 272)),
                top: (top - 136).clamp(4.0, math.max(4.0, h - 200)),
                child: _NanaBubble(
                  onClose: () => setState(() => _showBubble = false),
                  onOpen: _openSheet,
                ),
              ),
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSheet,
                onLongPress: _openVoice,
                onPanStart: (_) => setState(() => _dragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _fx = ((left + _size / 2 + details.delta.dx) / w).clamp(
                      0.08,
                      0.92,
                    );
                    _fy = ((top + _size / 2 + details.delta.dy) / h).clamp(
                      0.12,
                      0.92,
                    );
                    _showBubble = false;
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    _dragging = false;
                    // Snap to the closest side so she never floats in the
                    // middle of reading content.
                    _fx = _fx < 0.5 ? 0.11 : 0.89;
                  });
                  _persistPosition();
                  HapticFeedback.selectionClick();
                },
                child: _CompanionOrb(
                  pulse: _pulse,
                  bob: _bob,
                  dragging: _dragging,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompanionOrb extends ConsumerWidget {
  const _CompanionOrb({
    required this.pulse,
    required this.bob,
    required this.dragging,
  });

  final AnimationController pulse;
  final AnimationController bob;
  final bool dragging;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(companionMoodProvider);
    final asset = _moodAssets[mood]!;
    final accent = switch (mood) {
      CompanionMood.listening => AppColors.lime,
      CompanionMood.thinking => AppColors.sky,
      CompanionMood.speaking => AppColors.coral,
      CompanionMood.idle => AppColors.lime,
    };

    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Presence halo — its colour tells you what she is doing.
          AnimatedBuilder(
            animation: pulse,
            builder: (context, _) {
              final t = pulse.value;
              return IgnorePointer(
                child: Container(
                  width: 68 + 26 * t,
                  height: 68 + 26 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.5 * (1 - t)),
                      width: 2,
                    ),
                    color: accent.withValues(alpha: 0.10 * (1 - t)),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: bob,
            builder: (context, child) {
              final lift = dragging ? 0.0 : -2.5 * bob.value;
              final tilt = dragging ? 0.0 : 0.025 * (bob.value - 0.5);
              return Transform.translate(
                offset: Offset(0, lift),
                child: Transform.rotate(angle: tilt, child: child),
              );
            },
            child: AnimatedScale(
              scale: dragging ? 1.08 : 1,
              duration: AppMotion.fast,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                  boxShadow: AppShadows.floating,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.9),
                    width: 1,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.base,
                  switchInCurve: AppMotion.enter,
                  child: ClipOval(
                    key: ValueKey(asset),
                    child: Image.asset(
                      asset,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Live status notch.
          Positioned(
            right: 4,
            bottom: 5,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.6),
                    blurRadius: 8,
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

class _NanaBubble extends ConsumerWidget {
  const _NanaBubble({required this.onClose, required this.onOpen});

  final VoidCallback onClose;
  final VoidCallback onOpen;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// What she says depends on the family's real day: a due visit beats small
  /// talk, a pregnancy changes her question, and only then does she fall back
  /// to the time of day.
  String _message(WidgetRef ref) {
    final now = DateTime.now();
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final open = reminders.where((r) {
      final s = r.status.toLowerCase();
      return s != 'done' && s != 'missed';
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final dueToday = open
        .where((r) => _sameDay(r.dueDate, now))
        .toList(growable: false);
    if (dueToday.isNotEmpty) {
      final first = dueToday.first.title;
      return dueToday.length == 1
          ? 'You have $first today. Shall we look at it together?'
          : 'You have ${dueToday.length} visits today, starting with $first. '
                'Shall we look together?';
    }

    final today = DateTime(now.year, now.month, now.day);
    final soon = open
        .where(
          (r) =>
              r.dueDate.isAfter(today) &&
              r.dueDate.isBefore(today.add(const Duration(days: 8))),
        )
        .toList(growable: false);
    if (soon.isNotEmpty) {
      return '${soon.length} visit${soon.length == 1 ? '' : 's'} coming up '
          'this week. I can help you prepare.';
    }

    final pregnant = (ref.watch(pregnanciesProvider).value ?? const []).any(
      (p) => p.status == 'active',
    );
    if (pregnant) {
      return 'How are you and the baby feeling today, mama?';
    }

    final children = ref.watch(childrenProvider).value ?? const [];
    if (children.isNotEmpty) {
      final name = children.first.name;
      return 'Has $name eaten something colourful today? '
          'Tap me if you want ideas.';
    }

    final hour = now.hour;
    if (hour < 12) return 'Good morning! Shall we see today\'s care plan?';
    if (hour < 17) return 'Good afternoon. I am right here if you need me.';
    return 'Good evening. How is the family feeling today?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final message = _message(ref);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.base,
      curve: AppMotion.spring,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(
          scale: 0.9 + 0.1 * t,
          alignment: Alignment.bottomRight,
          child: child,
        ),
      ),
      child: SizedBox(
        width: 262,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SurfaceCard(
              radius: 20,
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              onTap: onOpen,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nana',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.forest,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Pill(
                              label: 'AI',
                              dense: true,
                              foreground: AppColors.limeInk,
                              background: AppColors.limeSoft,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSoft,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: AppColors.faint),
                  ),
                ],
              ),
            ),
            CustomPaint(size: const Size(14, 8), painter: _TailPainter()),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CompanionSheet extends ConsumerWidget {
  const _CompanionSheet();

  static const _suggestions = <(IconData, String, String)>[
    (
      Icons.event_available_rounded,
      'What is due this week?',
      'What care visits do I have this week?',
    ),
    (
      Icons.restaurant_rounded,
      'What should we eat?',
      'What should we eat today? Share a healthy meal plan.',
    ),
    (
      Icons.nightlight_round,
      'Help me sleep better',
      'I am tired and not sleeping well. What can I do tonight?',
    ),
  ];

  void _openChat(BuildContext context, {String? prompt, bool voice = false}) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NanaChatScreen(initialPrompt: prompt, voiceMode: voice),
      ),
    );
  }

  String _status(WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final soon = reminders.where((r) {
      final s = r.status.toLowerCase();
      return s != 'done' &&
          s != 'missed' &&
          !r.dueDate.isBefore(today) &&
          r.dueDate.isBefore(today.add(const Duration(days: 8)));
    }).length;
    final kids = (ref.watch(childrenProvider).value ?? const []).length;
    final pregnant = (ref.watch(pregnanciesProvider).value ?? const []).any(
      (p) => p.status == 'active',
    );
    final bits = <String>[
      if (soon > 0) '$soon visit${soon == 1 ? '' : 's'} soon',
      if (pregnant) 'pregnancy care',
      if (kids > 0) '$kids child${kids == 1 ? '' : 'ren'}',
    ];
    return bits.isEmpty
        ? 'Your care companion · always with you'
        : bits.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const NanaPortrait(size: 58, alive: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nana is here',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _status(ref),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Pill(
                    label: 'ONLINE',
                    dense: true,
                    foreground: AppColors.forest,
                    background: AppColors.limeSoft,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Do it now', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              _NanaAction(
                icon: Icons.health_and_safety_rounded,
                label: 'Start a health check',
                hint: 'Works offline · danger signs first',
                color: AppColors.coral,
                background: AppColors.coralSoft,
                onTap: () {
                  Navigator.of(context).pop();
                  startAssessmentPicker(context, ref);
                },
              ),
              _NanaAction(
                icon: Icons.restaurant_rounded,
                label: "Open Nana's Kitchen",
                hint: 'Meals for your budget and season',
                color: AppColors.forest,
                background: AppColors.limeSoft,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const DietScreen()));
                },
              ),
              _NanaAction(
                icon: Icons.calendar_month_rounded,
                label: 'Show my care calendar',
                hint: 'Visits, reminders and what is due',
                color: AppColors.sky,
                background: AppColors.skySoft,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(homeTabProvider.notifier).open(1);
                },
              ),
              _NanaAction(
                icon: Icons.family_restroom_rounded,
                label: 'Add a child or pregnancy',
                hint: 'So I can care for the whole family',
                color: AppColors.rose,
                background: AppColors.roseSoft,
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddChildScreen()),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text('Or just ask me', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final (icon, label, prompt) in _suggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PressScale(
                    borderRadius: AppRadii.md,
                    onTap: () => _openChat(context, prompt: prompt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          IconBubble(
                            icon: icon,
                            color: AppColors.forest,
                            size: 34,
                            iconSize: 17,
                            background: AppColors.cream,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppColors.faint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(context, voice: true),
                      icon: const Icon(Icons.mic_rounded, size: 19),
                      label: const Text('Talk'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openChat(context),
                      icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                      label: const Text('Chat'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              TextButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(context).pop();
                  await ref
                      .read(companionVisibleProvider.notifier)
                      .setVisible(false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Nana is resting. Bring her back any time from Settings.',
                      ),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: AppColors.lime,
                        onPressed: () => ref
                            .read(companionVisibleProvider.notifier)
                            .setVisible(true),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_off_outlined, size: 17),
                label: const Text('Let Nana rest for now'),
                style: TextButton.styleFrom(foregroundColor: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NanaAction extends StatelessWidget {
  const _NanaAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressScale(
        borderRadius: AppRadii.md,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              IconBubble(
                icon: icon,
                color: color,
                size: 38,
                iconSize: 19,
                background: background,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

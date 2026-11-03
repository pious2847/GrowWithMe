import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'plus_controller.dart';

/// Nana Plus: the honest preview paywall.
///
/// Billing is not wired yet, so this screen never pretends to charge. It
/// activates a clearly-labelled seven-day preview on the device and leaves a
/// single seam ([PlusController]) for a real payment provider later.
class PlusScreen extends ConsumerStatefulWidget {
  const PlusScreen({super.key});

  @override
  ConsumerState<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends ConsumerState<PlusScreen> {
  PlusPlan _selected = PlusPlan.yearly;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = ref.watch(plusProvider).value ?? const PlusState.free();
    final active = plus.isActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Nana Plus')),
      body: AmbientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 44),
          children: [
            _PlusHero(plus: plus),
            if (active && plus.preview) ...[
              const SizedBox(height: 12),
              _PreviewBanner(daysLeft: plus.daysLeft),
            ],
            const SizedBox(height: 22),
            const SectionHeader(
              title: 'What you unlock',
              subtitle: 'Private, on this phone, ready any time',
              padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
            ),
            const _BenefitsCard(),
            const SizedBox(height: 22),
            SectionHeader(
              title: active ? 'Your plan' : 'Choose your plan',
              subtitle: active
                  ? plus.renewalLine
                  : 'Launch pricing in Ghana · local price at checkout',
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            ),
            for (final plan in PlusPlan.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlanRow(
                  plan: plan,
                  selected: active ? plus.plan == plan : _selected == plan,
                  isCurrent: active && plus.plan == plan,
                  onTap: () {
                    if (_busy) return;
                    if (active) {
                      if (plus.plan == plan) return;
                      _switchPlan(plan);
                      return;
                    }
                    setState(() => _selected = plan);
                  },
                ),
              ),
            const SizedBox(height: 8),
            if (!active)
              LimeButton(
                label: _busy ? 'Starting…' : 'Start 7-day preview',
                icon: Icons.auto_awesome_rounded,
                onPressed: _busy ? null : _startPreview,
              )
            else ...[
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check_rounded, size: 19),
                label: const Text('Keep exploring'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _cancel,
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: Text(
                  plus.trial ? 'End preview early' : 'Cancel Nana Plus',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.coral,
                  side: const BorderSide(color: AppColors.coralSoft),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const _PreviewNote(),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.restore_rounded, size: 17),
                label: const Text('Restore purchases'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'GrowWithMe\'s core care is free for every family. Nana Plus '
              'only changes what you can revisit and share — never the advice '
              'Nana gives you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.5,
              ),
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
                Text(
                  'No ads · no health data sold · cancel any time',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.faint,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPreview() async {
    final plan = _selected;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start your 7-day preview?'),
        content: Text(
          'Nana Plus preview unlocks twelve weeks of reports, every insight '
          'and all card styles on this phone for seven days.\n\n'
          'No payment is taken — billing is not connected yet. The preview '
          'ends automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Start preview'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(plusProvider.notifier).startPreview(plan);
    ref
        .read(actionLoggerProvider)
        .log(
          screen: 'plus',
          action: 'start_preview',
          target: plan.storageKey,
          params: {'source': 'plus_screen'},
        );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview started · no payment was taken.')),
    );
  }

  Future<void> _switchPlan(PlusPlan plan) async {
    setState(() => _busy = true);
    await ref.read(plusProvider.notifier).switchPlan(plan);
    ref
        .read(actionLoggerProvider)
        .log(screen: 'plus', action: 'switch_plan', target: plan.storageKey);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selected = plan;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Switched to ${plan.title.toLowerCase()}.')),
    );
  }

  Future<void> _cancel() async {
    final plus = ref.read(plusProvider).value ?? const PlusState.free();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(plus.trial ? 'End your preview?' : 'Cancel Nana Plus?'),
        content: const Text(
          'Your current week\'s report stays free, and everything you have '
          'recorded remains on this phone. You can start again any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(plus.trial ? 'End preview' : 'Cancel plan'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    await ref.read(plusProvider.notifier).cancel();
    ref
        .read(actionLoggerProvider)
        .log(screen: 'plus', action: 'cancel_plus', target: 'plus_screen');
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preview ended. This week\'s report is still free.'),
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final restored = await ref.read(plusProvider.notifier).restore();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? 'Nana Plus restored on this phone.'
              : 'No previous Nana Plus purchase was found on this phone.',
        ),
      ),
    );
  }
}

class _PlusHero extends StatelessWidget {
  const _PlusHero({required this.plus});

  final PlusState plus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = plus.isActive;
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
              top: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lime.withValues(alpha: 0.22),
                      AppColors.lime.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 26,
              bottom: 42,
              child: Sparkle(
                size: 9,
                color: AppColors.lime.withValues(alpha: 0.65),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pill(
                        label: active ? 'ACTIVE' : 'FOR FAMILIES',
                        dense: true,
                        foreground: active
                            ? AppColors.forestDeep
                            : AppColors.lime,
                        background: active
                            ? AppColors.lime
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                      const Spacer(),
                      const NanaPortrait(
                        size: 62,
                        alive: true,
                        asset: 'assets/illustrations/nana_happy.webp',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    active
                        ? 'Growing with Nana Plus'
                        : 'Care that remembers every week',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.cream,
                      fontSize: 30,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    active
                        ? plus.statusLine
                        : 'A calmer view of your family\'s care — and every '
                              'week worth keeping.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.cream.withValues(alpha: 0.76),
                      height: 1.45,
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 15,
                          color: AppColors.lime,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            plus.renewalLine,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.cream.withValues(alpha: 0.85),
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
          ],
        ),
      ),
    );
  }
}

class _PreviewBanner extends StatelessWidget {
  const _PreviewBanner({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      color: AppColors.amberSoft,
      borderColor: const Color(0xFFF0D79A),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(
            icon: Icons.info_rounded,
            color: AppColors.amber,
            size: 38,
            iconSize: 18,
            background: AppColors.white,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview active · ${daysLeft == 1 ? '1 day' : '$daysLeft days'} left',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'No payment will be taken. Billing is not connected yet, and '
                  'this preview ends automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkSoft,
                    fontSize: 11.5,
                    height: 1.4,
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

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  static const _benefits = [
    (
      Icons.history_rounded,
      AppColors.sky,
      AppColors.skySoft,
      'Twelve weeks of reports',
      'Revisit and share any week, not just the current one.',
    ),
    (
      Icons.insights_rounded,
      AppColors.teal,
      AppColors.tealSoft,
      'Every weekly insight',
      'Nana\'s full read on visits, meals, checks and growth.',
    ),
    (
      Icons.palette_rounded,
      AppColors.violet,
      AppColors.violetSoft,
      'All card styles',
      'Forest, Sunrise and Heritage posters at 1080 × 1350.',
    ),
    (
      Icons.volunteer_activism_rounded,
      AppColors.coral,
      AppColors.coralSoft,
      'Keep GrowWithMe free',
      'Your support funds free care for families who need it most.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _benefits.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 64, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
              child: Row(
                children: [
                  IconBubble(
                    icon: _benefits[i].$1,
                    color: _benefits[i].$2,
                    size: 40,
                    iconSize: 19,
                    background: _benefits[i].$3,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _benefits[i].$4,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _benefits[i].$5,
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
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final PlusPlan plan;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PressScale(
      borderRadius: AppRadii.md,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.limeSoft : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.forest : AppColors.faint,
              size: 21,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(plan.title, style: theme.textTheme.titleSmall),
                      if (plan.badge != null)
                        Pill(
                          label: plan.badge!,
                          dense: true,
                          foreground: AppColors.forestDeep,
                          background: AppColors.lime,
                        ),
                      if (isCurrent)
                        const Pill(
                          label: 'YOUR PLAN',
                          dense: true,
                          foreground: AppColors.forest,
                          background: AppColors.white,
                          border: AppColors.lineStrong,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.monthlyEquivalent,
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
                  plan.price,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    color: AppColors.forestDeep,
                  ),
                ),
                Text(
                  plan.cadence,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewNote extends StatelessWidget {
  const _PreviewNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      color: AppColors.creamDeep,
      borderColor: AppColors.line,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBubble(
            icon: Icons.receipt_long_rounded,
            color: AppColors.forest,
            size: 36,
            iconSize: 17,
            background: AppColors.white,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview only — no payment',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Billing is not connected in this build. Starting a preview '
                  'unlocks Nana Plus on this phone for seven days, then ends '
                  'on its own. No card, no charge.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.45,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/regions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';
import 'phone_screen.dart';

class _Slide {
  const _Slide({
    required this.asset,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.chips,
    this.tint = AppColors.limeSoft,
  });

  final String asset;
  final String eyebrow;
  final String title;
  final String body;
  final List<(IconData, String)> chips;
  final Color tint;
}

const _slides = <_Slide>[
  _Slide(
    asset: 'assets/illustrations/onboarding_hero.webp',
    eyebrow: 'CARE THAT GROWS WITH YOU',
    title: 'A calmer, safer way\nto care for your family',
    body:
        'Reminders, health checks and a caring AI companion — '
        'for every mother and every little one.',
    chips: [
      (Icons.favorite_rounded, 'Made for families'),
      (Icons.public_rounded, 'Starting in Ghana'),
    ],
    tint: AppColors.limeSoft,
  ),
  _Slide(
    asset: 'assets/illustrations/onboarding_calendar.webp',
    eyebrow: 'NEVER MISS A VISIT',
    title: 'Every clinic visit,\nright on time',
    body:
        'Immunizations, weighing days and antenatal visits, arranged '
        'into a simple calendar with gentle reminders.',
    chips: [
      (Icons.event_available_rounded, 'Care calendar'),
      (Icons.notifications_active_rounded, 'Gentle reminders'),
    ],
    tint: AppColors.amberSoft,
  ),
  _Slide(
    asset: 'assets/illustrations/onboarding_offline.webp',
    eyebrow: 'HELP, EVEN OFFLINE',
    title: 'Check symptoms\nat home, any time',
    body:
        'Answer a few simple questions when someone feels unwell. '
        'The health check works with no network — and urgent help finds you.',
    chips: [
      (Icons.wifi_off_rounded, 'Works offline'),
      (Icons.health_and_safety_rounded, 'Danger-sign checks'),
    ],
    tint: AppColors.tealSoft,
  ),
  _Slide(
    asset: 'assets/illustrations/nana_happy.webp',
    eyebrow: 'MEET NANA',
    title: 'A companion who\nknows your story',
    body:
        'Nana listens, remembers your family, and answers by voice — '
        'like a trusted elder who is always beside you.',
    chips: [
      (Icons.mic_rounded, 'Talk or type'),
      (Icons.auto_awesome_rounded, 'Always with you'),
    ],
    tint: AppColors.limeSoft,
  ),
];

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      HapticFeedback.lightImpact();
      _controller.nextPage(duration: AppMotion.page, curve: AppMotion.smooth);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PhoneScreen()));
  }

  Future<void> _openRegionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _RegionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final region = ref.watch(regionProvider).value ?? RegionSettings.defaults;
    final isLast = _page == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.cream,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: AmbientBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 6, 4),
                  child: Row(
                    children: [
                      const BrandMark(size: 36),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GrowWithMe',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'by TOVO LABs',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.muted,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PressScale(
                        borderRadius: 99,
                        onTap: _openRegionSheet,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                region.country.flag,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 92),
                                child: Text(
                                  region.country.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _goToLogin,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      return AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          var delta = 0.0;
                          if (_controller.hasClients &&
                              _controller.position.haveDimensions) {
                            delta = (_controller.page ?? _page.toDouble()) - i;
                          }
                          final proximity = (1 - delta.abs()).clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: 0.94 + 0.06 * proximity,
                            child: Opacity(
                              opacity: 0.45 + 0.55 * proximity,
                              child: _SlideCard(
                                slide: _slides[i],
                                active: i == _page,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ProgressDotBar(count: _slides.length, index: _page),
                          const Spacer(),
                          if (!isLast)
                            TextButton(
                              onPressed: _next,
                              child: const Text('Next'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LimeButton(
                        label: isLast ? 'Meet your companion' : 'Continue',
                        onPressed: _next,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _goToLogin,
                        child: const Text('I already have an account'),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 0,
                        runSpacing: 4,
                        children: const [
                          _TrustItem(
                            icon: Icons.lock_rounded,
                            label: 'Private',
                          ),
                          _Dot(),
                          _TrustItem(
                            icon: Icons.wifi_off_rounded,
                            label: 'Offline-ready',
                          ),
                          _Dot(),
                          _TrustItem(
                            icon: Icons.volunteer_activism_rounded,
                            label: 'Free for families',
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
      ),
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide, required this.active});

  final _Slide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey(active),
      tween: Tween(begin: active ? 0 : 1, end: 1),
      duration: AppMotion.page,
      curve: AppMotion.enter,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: slide.tint,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.06),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.asset,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        filterQuality: FilterQuality.medium,
                      ),
                      Positioned(top: 14, left: 14, child: Sparkle(size: 18)),
                      Positioned(
                        bottom: 14,
                        right: 16,
                        child: Sparkle(
                          size: 12,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              slide.eyebrow,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.forestSoft,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              slide.title,
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.forestDeep,
                height: 1.06,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slide.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label) in slide.chips)
                  Pill(
                    label: label,
                    icon: icon,
                    foreground: AppColors.forest,
                    background: AppColors.white,
                    border: AppColors.line,
                    dense: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: AppColors.lineStrong,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RegionSheet extends ConsumerStatefulWidget {
  const _RegionSheet();

  @override
  ConsumerState<_RegionSheet> createState() => _RegionSheetState();
}

class _RegionSheetState extends ConsumerState<_RegionSheet> {
  late CountryConfig _country;
  String? _region;
  late String _language;

  @override
  void initState() {
    super.initState();
    final current = ref.read(regionProvider).value ?? RegionSettings.defaults;
    _country = current.country;
    _region = current.region;
    _language = current.languageCode;
  }

  Future<void> _save() async {
    await ref
        .read(regionProvider.notifier)
        .save(
          RegionSettings(
            countryCode: _country.code,
            region: _region,
            languageCode: _language,
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          children: [
            Text(
              'Where are you caring\nfor your family?',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'This sets your clinic calendar, emergency number and local '
              'nutrition guidance. You can change it later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Text('Country', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final c in supportedCountries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PressScale(
                  borderRadius: AppRadii.md,
                  onTap: () => setState(() {
                    _country = c;
                    _region = null;
                    _language = c.languages.first.code;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _country.code == c.code
                          ? AppColors.limeSoft
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: _country.code == c.code
                            ? AppColors.forest
                            : AppColors.line,
                        width: _country.code == c.code ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(c.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (c.isHomeMarket)
                          const Pill(
                            label: 'HOME',
                            dense: true,
                            foreground: AppColors.forest,
                          ),
                        if (_country.code == c.code)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.forest,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_country.regions.length > 1) ...[
              const SizedBox(height: 14),
              Text('Region', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _country.regions)
                    ChoiceChip(
                      label: Text(r),
                      selected: _region == r,
                      onSelected: (_) => setState(() => _region = r),
                    ),
                ],
              ),
            ],
            if (_country.languages.length > 1) ...[
              const SizedBox(height: 18),
              Text('Language', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final l in _country.languages)
                    ChoiceChip(
                      label: Text(l.beta ? '${l.label} · soon' : l.label),
                      selected: _language == l.code,
                      onSelected: (_) => setState(() {
                        if (!l.beta) _language = l.code;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        );
      },
    );
  }
}

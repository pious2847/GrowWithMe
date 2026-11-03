import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_widgets.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/welcome_screen.dart';

class GrowWithMeApp extends ConsumerWidget {
  const GrowWithMeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'GrowWithMe',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.light(),
      builder: (context, child) {
        // Extreme system font scaling breaks dense care screens; clamp it
        // while still honouring accessibility preferences.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.25,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: auth.when(
          loading: () => const _BootSplash(key: ValueKey('boot')),
          error: (_, _) => const WelcomeScreen(key: ValueKey('welcome')),
          data: (signedIn) => signedIn
              ? const HomeShell(key: ValueKey('home'))
              : const WelcomeScreen(key: ValueKey('welcome')),
        ),
      ),
    );
  }
}

class _BootSplash extends StatefulWidget {
  const _BootSplash({super.key});

  @override
  State<_BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<_BootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1 + _pulse.value * 0.06,
                  child: child,
                ),
                child: const BrandMark(size: 76),
              ),
              const SizedBox(height: 22),
              Text(
                'GrowWithMe',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.forestDeep,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preparing your family\'s care…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

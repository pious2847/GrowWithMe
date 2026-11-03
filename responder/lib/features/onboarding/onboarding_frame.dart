import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/ui/app_widgets.dart';

/// Shared chrome for the four registration steps. Keeps the progress language,
/// back affordance and footer action consistent while each step owns its body.
class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
    this.eyebrow = 'RESPONDER SETUP',
  });

  /// 1-based step number out of [totalSteps].
  final int step;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final String eyebrow;

  static const totalSteps = 4;
  static const stepNames = ['Privacy', 'Profile', 'Documents', 'Review'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    if (onBack != null)
                      _RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack!,
                      )
                    else
                      const SizedBox(width: 44),
                    const Spacer(),
                    const ResponderMark(size: 32, showShadow: false),
                    const Spacer(),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$step/$totalSteps',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProgressDotBar(count: totalSteps, index: step - 1),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: t.displaySmall?.copyWith(
                        color: AppColors.forestDeep,
                        height: 1.06,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: t.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: FadeSlideIn(child: child),
                ),
              ),
              if (footer != null)
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 16),
                  child: SafeArea(top: false, child: footer!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 21, color: AppColors.ink),
        ),
      ),
    );
  }
}

/// Tappable permission / acknowledgement row used by the privacy step.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      borderRadius: AppRadii.lg,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: AppMotion.base,
        curve: AppMotion.enter,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? AppColors.limeSoft : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: value ? AppColors.forest : AppColors.line,
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.forest : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value ? AppColors.forest : AppColors.lineStrong,
                  width: 1.6,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 17, color: AppColors.lime)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: value ? AppColors.forestDeep : AppColors.inkSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

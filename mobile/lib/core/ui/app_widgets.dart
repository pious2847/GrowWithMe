import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Rounded cream page with two soft ambient glows. Used by onboarding and
/// other "moment" screens so they feel like part of one designed world.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.cream),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _Glow(color: AppColors.lime, size: 330, opacity: 0.5),
          ),
          Positioned(
            bottom: -160,
            left: -130,
            child: _Glow(color: AppColors.sand, size: 380, opacity: 0.7),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// The GrowWithMe mark: a deep forest tile with a lime sprout-heart.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showShadow ? AppShadows.card : null,
      ),
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lime = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    // Two leaves forming an open heart / sprout.
    final left = Path()
      ..moveTo(w * 0.5, h * 0.76)
      ..cubicTo(w * 0.20, h * 0.60, w * 0.18, h * 0.30, w * 0.38, h * 0.28)
      ..cubicTo(w * 0.47, h * 0.27, w * 0.5, h * 0.36, w * 0.5, h * 0.40)
      ..cubicTo(w * 0.5, h * 0.50, w * 0.44, h * 0.62, w * 0.5, h * 0.76)
      ..close();
    final right = Path()
      ..moveTo(w * 0.5, h * 0.76)
      ..cubicTo(w * 0.80, h * 0.60, w * 0.82, h * 0.30, w * 0.62, h * 0.28)
      ..cubicTo(w * 0.53, h * 0.27, w * 0.5, h * 0.36, w * 0.5, h * 0.40)
      ..cubicTo(w * 0.5, h * 0.50, w * 0.56, h * 0.62, w * 0.5, h * 0.76)
      ..close();

    canvas.drawPath(right, soft);
    canvas.drawPath(left, lime);
    canvas.drawCircle(Offset(w * 0.5, h * 0.20), w * 0.035, lime);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// White card with the brand's hairline border and low, wide shadow.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.white,
    this.borderColor = AppColors.line,
    this.radius = AppRadii.lg,
    this.onTap,
    this.shadow = true,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool shadow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow ? AppShadows.card : null,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return content;
    return PressScale(onTap: onTap!, child: content);
  }
}

/// A press that scales down gently. Cheaper and calmer than ink splashes on
/// photo-heavy cards.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.975,
    this.borderRadius = AppRadii.lg,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scale;
  final double borderRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(0, 8, 0, 10),
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: t.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.foreground = AppColors.forest,
    this.background = AppColors.limeSoft,
    this.border,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;
  final Color? border;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: foreground,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
    this.iconSize = 23,
    this.background,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// A lime call-to-action used for the single most important action on a page.
class LimeButton extends StatelessWidget {
  const LimeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.limeGradient,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.lime.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.forestDeep,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, color: AppColors.forestDeep, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return child;
  }
}

class ProgressDotBar extends StatelessWidget {
  const ProgressDotBar({
    super.key,
    required this.count,
    required this.index,
    this.activeColor = AppColors.forest,
    this.inactiveColor = AppColors.lineStrong,
    this.activeWidth = 26,
  });

  final int count;
  final int index;
  final Color activeColor;
  final Color inactiveColor;
  final double activeWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.enter,
            margin: const EdgeInsets.only(right: 6),
            height: 6,
            width: i == index ? activeWidth : 6,
            decoration: BoxDecoration(
              color: i == index ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

/// Portrait of Nana inside a floating medallion. [alive] adds a slow breath
/// and a rotating halo so the companion reads as present, not as a static icon.
class NanaPortrait extends StatefulWidget {
  const NanaPortrait({
    super.key,
    this.size = 54,
    this.asset = 'assets/illustrations/nana_happy.webp',
    this.alive = false,
    this.showRing = true,
    this.glow = true,
  });

  final double size;
  final String asset;
  final bool alive;
  final bool showRing;
  final bool glow;

  @override
  State<NanaPortrait> createState() => _NanaPortraitState();
}

class _NanaPortraitState extends State<NanaPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.alive) _breath.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant NanaPortrait old) {
    super.didUpdateWidget(old);
    if (widget.alive && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!widget.alive && _breath.isAnimating) {
      _breath.stop();
      _breath.value = 0.5;
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _breath,
      builder: (context, child) {
        final t = widget.alive ? _breath.value : 0.5;
        final scale = 1 + (t - 0.5) * 0.035;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.glow ? AppColors.limeGradient : null,
          border: widget.showRing
              ? Border.all(color: AppColors.white, width: 2.5)
              : null,
          boxShadow: widget.glow
              ? [
                  BoxShadow(
                    color: AppColors.lime.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(2.2),
        child: ClipOval(
          child: Image.asset(
            widget.asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.limeSoft,
              child: const Icon(Icons.spa, color: AppColors.forest),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small decorative sparkle used around hero content.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, required this.size, this.color = AppColors.lime});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SparklePainter(color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = (math.pi / 2) * i;
      final tip = c + Offset(math.cos(a) * r, math.sin(a) * r);
      final a2 = a + math.pi / 4;
      final mid = c + Offset(math.cos(a2) * r * 0.22, math.sin(a2) * r * 0.22);
      if (i == 0) {
        path.moveTo(tip.dx, tip.dy);
      } else {
        path.lineTo(mid.dx, mid.dy);
        path.lineTo(tip.dx, tip.dy);
      }
      final a3 = a + math.pi / 2 - math.pi / 4;
      final mid2 = c + Offset(math.cos(a3) * r * 0.22, math.sin(a3) * r * 0.22);
      path.lineTo(mid2.dx, mid2.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => old.color != color;
}

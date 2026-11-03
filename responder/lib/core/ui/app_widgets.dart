import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Rounded cream page with two soft ambient glows. Used by onboarding and
/// "moment" screens so the responder app feels like part of the same designed
/// world as the caregiver app.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.urgent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Swaps the top glow for a faint coral warmth on urgent screens.
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.cream),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -110,
            child: _Glow(
              color: urgent ? AppColors.coral : AppColors.lime,
              size: 330,
              opacity: urgent ? 0.16 : 0.5,
            ),
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

/// Responder identity mark: forest tile, lime cross with a soft heartbeat line.
/// Reads as "same family as GrowWithMe, but the clinical side of it".
class ResponderMark extends StatelessWidget {
  const ResponderMark({
    super.key,
    this.size = 44,
    this.showShadow = true,
    this.background,
  });

  final double size;
  final bool showShadow;
  final Gradient? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: background ?? AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showShadow ? AppShadows.card : null,
      ),
      child: CustomPaint(painter: _CrossPainter()),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final lime = Paint()..color = AppColors.lime;

    final arm = w * 0.10;
    final long = w * 0.50;
    final cx = w * 0.5;
    final cy = h * 0.37;
    final cross = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: arm * 2, height: long),
        Radius.circular(arm * 0.38),
      ))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: long, height: arm * 2),
        Radius.circular(arm * 0.38),
      ));
    canvas.drawPath(cross, lime);

    // Heartbeat line beneath the cross.
    final pulse = Paint()
      ..color = AppColors.lime.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final p = Path()
      ..moveTo(w * 0.18, h * 0.80)
      ..lineTo(w * 0.36, h * 0.80)
      ..lineTo(w * 0.44, h * 0.72)
      ..lineTo(w * 0.54, h * 0.88)
      ..lineTo(w * 0.62, h * 0.80)
      ..lineTo(w * 0.82, h * 0.80);
    canvas.drawPath(p, pulse);
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
    return PressScale(onTap: onTap!, borderRadius: radius, child: content);
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
              fontSize: dense ? 10.5 : 12,
              fontWeight: FontWeight.w800,
              color: foreground,
              letterSpacing: 0.2,
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
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: enabled ? onPressed : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.limeGradient : null,
            color: enabled ? null : AppColors.sand,
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.lime.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy) ...[
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.forestDeep,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: enabled ? AppColors.forestDeep : AppColors.faint,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                  ),
                ),
                if (icon != null && !busy) ...[
                  const SizedBox(width: 10),
                  Icon(
                    icon,
                    color: enabled ? AppColors.forestDeep : AppColors.faint,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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

/// Compact metric used in the duty hero and impact cards.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.accent = AppColors.lime,
    this.dark = true,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final valueColor = dark ? AppColors.cream : AppColors.ink;
    final labelColor =
        dark ? AppColors.cream.withValues(alpha: 0.6) : AppColors.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 25,
                height: 1,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontVariations: const [
                  FontVariation('wght', 700),
                  FontVariation('opsz', 48),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}

/// Severity label used on case cards and detail headers.
class TriagePill extends StatelessWidget {
  const TriagePill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: label,
      icon: icon,
      foreground: foreground,
      background: background,
      dense: dense,
    );
  }
}

/// Human status chip for an alert lifecycle value.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.dense = false});

  final String status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      'pending' || 'notified' || 'unassigned' => (
          'NEEDS YOU',
          const Color(0xFF9A3412),
          AppColors.coralSoft,
        ),
      'acknowledged' => ('ACCEPTED', AppColors.forest, AppColors.limeSoft),
      'en_route' => ('EN ROUTE', const Color(0xFF1F5F7D), AppColors.skySoft),
      'at_facility' => ('AT FACILITY', AppColors.teal, AppColors.tealSoft),
      'closed' => ('CLOSED', AppColors.muted, AppColors.sand),
      _ => (status.toUpperCase(), AppColors.muted, AppColors.sand),
    };
    return Pill(label: label, foreground: fg, background: bg, dense: dense);
  }
}

/// Tinted notice strip used for offline / queued states.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.message,
    this.color = AppColors.amber,
    this.background = AppColors.amberSoft,
    this.action,
  });

  final IconData icon;
  final String message;
  final Color color;
  final Color background;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.limeGradient,
              ),
              child: Icon(icon, size: 36, color: AppColors.forestDeep),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: t.headlineSmall),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// One-shot fade + rise used to give screens a calm entrance.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.page,
  );
  late final Animation<double> _curved =
      CurvedAnimation(parent: _controller, curve: AppMotion.enter);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curved.value) * 14),
          child: child,
        ),
      ),
      child: widget.child,
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

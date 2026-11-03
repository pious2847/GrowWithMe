import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';

/// Builds the GrowWithMe look: Manrope for UI, Fraunces for warm display
/// moments, soft cream surfaces and deep forest structure.
abstract final class AppTheme {
  static const _ui = 'Manrope';
  static const _display = 'Fraunces';

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.forest,
      onPrimary: AppColors.cream,
      primaryContainer: AppColors.limeSoft,
      onPrimaryContainer: AppColors.forestDeep,
      secondary: AppColors.limeInk,
      onSecondary: AppColors.limeSoft,
      secondaryContainer: AppColors.lime,
      onSecondaryContainer: AppColors.forestDeep,
      tertiary: AppColors.coral,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.coralSoft,
      onTertiaryContainer: Color(0xFF6E1F0A),
      error: Color(0xFFB3261E),
      onError: AppColors.white,
      errorContainer: AppColors.coralSoft,
      onErrorContainer: Color(0xFF6E1F0A),
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.white,
      surfaceContainerLow: Color(0xFFFFFDF7),
      surfaceContainer: Color(0xFFF5EFE2),
      surfaceContainerHigh: Color(0xFFEFE7D7),
      surfaceContainerHighest: AppColors.sand,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.lineStrong,
      outlineVariant: AppColors.line,
      shadow: AppColors.shadow,
      scrim: Color(0x9906241B),
      inverseSurface: AppColors.forestDeep,
      onInverseSurface: AppColors.cream,
      inversePrimary: AppColors.lime,
    );

    final text = _textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _ui,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: text,
      primaryTextTheme: text.apply(
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
      ),
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SoftPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge?.copyWith(color: AppColors.ink),
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.forest),
          foregroundColor: const WidgetStatePropertyAll(AppColors.cream),
          overlayColor: WidgetStatePropertyAll(
            AppColors.lime.withValues(alpha: 0.12),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 56)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: _ui,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.forest),
          backgroundColor: const WidgetStatePropertyAll(AppColors.white),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.lineStrong, width: 1.2),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 54)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: _ui,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          textStyle: const TextStyle(
            fontFamily: _ui,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.faint),
        labelStyle: text.bodyMedium?.copyWith(color: AppColors.muted),
        floatingLabelStyle: text.bodySmall?.copyWith(
          color: AppColors.forest,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: const BorderSide(color: AppColors.coral, width: 1.8),
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 74,
        elevation: 0,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.limeSoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.forest, size: 24);
          }
          return const IconThemeData(color: AppColors.faint, size: 23);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: _ui,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.forest : AppColors.muted,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.limeSoft,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        labelStyle: text.bodySmall!.copyWith(color: AppColors.ink),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.lineStrong,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        titleTextStyle: text.titleLarge?.copyWith(color: AppColors.ink),
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forestDeep,
        contentTextStyle: text.bodyMedium?.copyWith(color: AppColors.cream),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        insetPadding: const EdgeInsets.all(16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.forest,
        linearTrackColor: AppColors.sand,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.forest
              : AppColors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.lime
              : AppColors.sand,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.lineStrong),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.muted,
        textColor: AppColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.forestDeep,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: text.bodySmall?.copyWith(color: AppColors.cream),
      ),
    );
  }

  static TextTheme _textTheme() {
    TextStyle ui(
      double size,
      FontWeight weight, {
      double height = 1.4,
      double spacing = 0,
    }) => TextStyle(
      fontFamily: _ui,
      fontSize: size,
      height: height,
      letterSpacing: spacing,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
    );

    TextStyle display(
      double size,
      FontWeight weight, {
      double height = 1.08,
      double spacing = -0.6,
    }) => TextStyle(
      fontFamily: _display,
      fontSize: size,
      height: height,
      letterSpacing: spacing,
      fontWeight: weight,
      fontVariations: [
        FontVariation('wght', weight.value.toDouble()),
        const FontVariation('opsz', 48),
        const FontVariation('SOFT', 30),
        const FontVariation('WONK', 1),
      ],
    );

    return TextTheme(
      displayLarge: display(46, FontWeight.w700, height: 1.02),
      displayMedium: display(38, FontWeight.w700, height: 1.05),
      displaySmall: display(31, FontWeight.w700, height: 1.1),
      headlineLarge: display(28, FontWeight.w700, height: 1.12),
      headlineMedium: display(24, FontWeight.w700, height: 1.15),
      headlineSmall: display(21, FontWeight.w700, height: 1.18),
      titleLarge: ui(20, FontWeight.w800, height: 1.25, spacing: -0.2),
      titleMedium: ui(16.5, FontWeight.w800, height: 1.3, spacing: -0.1),
      titleSmall: ui(14.5, FontWeight.w800, height: 1.3),
      bodyLarge: ui(16, FontWeight.w500, height: 1.55),
      bodyMedium: ui(14.5, FontWeight.w500, height: 1.5),
      bodySmall: ui(13, FontWeight.w500, height: 1.45),
      labelLarge: ui(14.5, FontWeight.w700, height: 1.2, spacing: 0.1),
      labelMedium: ui(12.5, FontWeight.w700, height: 1.2, spacing: 0.2),
      labelSmall: ui(11.5, FontWeight.w700, height: 1.2, spacing: 0.3),
    );
  }
}

/// A calm fade-and-rise transition instead of the default zoom, so the app
/// feels considered even on low-end devices.
class _SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

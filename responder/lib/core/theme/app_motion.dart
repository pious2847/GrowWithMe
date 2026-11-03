import 'package:flutter/material.dart';

/// Shared motion language: short, confident, never bouncy enough to feel
/// unserious in a health context.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 460);
  static const page = Duration(milliseconds: 520);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const spring = Cubic(0.2, 0.9, 0.25, 1.05);
  static const smooth = Curves.easeInOutCubicEmphasized;
}

abstract final class AppRadii {
  static const xs = 10.0;
  static const sm = 14.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x140B3B2E), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x260B3B2E), blurRadius: 32, offset: Offset(0, 14)),
  ];
  static const floating = [
    BoxShadow(color: Color(0x330B3B2E), blurRadius: 22, offset: Offset(0, 10)),
  ];
}

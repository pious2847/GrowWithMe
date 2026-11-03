import 'package:flutter/material.dart';

/// GrowWithMe brand palette.
///
/// The identity is "warm clinical": deep forest greens for trust, a vivid lime
/// accent for hope and energy, cream paper tones so long reading sessions feel
/// calm rather than sterile, and terracotta for urgency. Contrast ratios are
/// chosen for outdoor readability on low-cost Android screens.
abstract final class AppColors {
  // Core brand.
  static const forest = Color(0xFF0B3B2E);
  static const forestDeep = Color(0xFF06241B);
  static const forestMid = Color(0xFF14503D);
  static const forestSoft = Color(0xFF1D6350);

  // Vitality accent.
  static const lime = Color(0xFFC7F06B);
  static const limeBright = Color(0xFFDAF98F);
  static const limeSoft = Color(0xFFEDFAD0);
  static const limeInk = Color(0xFF2C4A12);

  // Warm neutrals.
  static const cream = Color(0xFFFBF7EC);
  static const creamDeep = Color(0xFFF4EDDD);
  static const sand = Color(0xFFEDE4D1);
  static const white = Color(0xFFFFFFFF);

  // Ink.
  static const ink = Color(0xFF11211B);
  static const inkSoft = Color(0xFF3C4D45);
  static const muted = Color(0xFF66766D);
  static const faint = Color(0xFF97A49C);

  // Meaning.
  static const coral = Color(0xFFF2643F);
  static const coralSoft = Color(0xFFFFE8E0);
  static const amber = Color(0xFFE9A11B);
  static const amberSoft = Color(0xFFFFF2D6);
  static const teal = Color(0xFF2C8C82);
  static const tealSoft = Color(0xFFDDF3EE);
  static const sky = Color(0xFF3D7FA6);
  static const skySoft = Color(0xFFE3F0F7);
  static const rose = Color(0xFFB84A6E);
  static const roseSoft = Color(0xFFFBE4EC);
  static const violet = Color(0xFF6C5CA8);
  static const violetSoft = Color(0xFFEDE9FA);

  // Lines and shadows.
  static const line = Color(0xFFE7DFCF);
  static const lineStrong = Color(0xFFD6CCB8);
  static const shadow = Color(0x1A0B3B2E);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E4636), Color(0xFF06241B)],
  );

  static const limeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD9FA92), Color(0xFFB4E34F)],
  );

  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF6E3), Color(0xFFF6EAD2)],
  );

  static const coralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A55), Color(0xFFD94722)],
  );
}

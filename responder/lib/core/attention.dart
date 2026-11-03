import 'package:flutter/services.dart';

/// Field-usable attention cues. Rural responders may be walking, riding or
/// away from the screen; a new urgent case deserves a sound + vibration.
/// Best-effort only — devices with silent mode simply ignore the sound.
abstract final class Attention {
  static Future<void> newCase() async {
    HapticFeedback.heavyImpact();
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 180));
    HapticFeedback.mediumImpact();
  }

  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static Future<void> warning() => HapticFeedback.lightImpact();
}

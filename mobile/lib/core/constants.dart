import 'package:flutter/foundation.dart';

/// Production backend (Render).
const kProductionApiBase = 'https://growwithme.onrender.com/api/v1';

/// Backend base-URL candidates, tried in order at runtime.
///
/// RELEASE builds talk to production only.
/// DEBUG builds probe: build-time override → USB bridge → dev PC on Wi-Fi →
/// production as the final fallback (so a debug build still works anywhere).
final List<String> kApiBaseCandidates = kReleaseMode
    ? const [kProductionApiBase]
    : const [
        String.fromEnvironment('API_BASE_URL', defaultValue: ''),
        'http://127.0.0.1:5000/api/v1', // adb reverse tcp:5000 tcp:5000
        'http://192.168.1.70:5000/api/v1', // dev PC on home Wi-Fi
        'http://10.152.112.28:5000/api/v1', // dev PC on the phone's hotspot
        kProductionApiBase,
      ];

const kAccessTokenKey = 'accessToken';
const kRefreshTokenKey = 'refreshToken';
const kLastPulledAtKey = 'lastPulledAt';

const kLanguages = {
  'en': 'English',
  'dagbani': 'Dagbani',
  'twi': 'Twi',
  'hausa': 'Hausa',
  'other': 'Other',
};

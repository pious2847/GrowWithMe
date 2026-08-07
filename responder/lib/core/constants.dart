import 'package:flutter/foundation.dart';

const kProductionApiBase = 'https://growwithme.onrender.com/api/v1';

/// RELEASE talks to production only. DEBUG probes the USB bridge first so a
/// dev backend on the PC wins when present.
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

const kTiers = {
  'volunteer': 'Community volunteer',
  'chw': 'Community health worker',
  'nurse': 'Nurse',
  'midwife': 'Midwife',
  'doctor': 'Doctor',
};

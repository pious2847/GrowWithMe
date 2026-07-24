/// Backend base-URL candidates, tried in order at runtime (first one whose
/// /health responds wins; re-probed when the connection drops):
///  1. Build-time override (--dart-define=API_BASE_URL=...)
///  2. USB bridge: adb reverse tcp:5000 tcp:5000
///  3. Dev PC over Wi-Fi (same network as the phone)
const List<String> kApiBaseCandidates = [
  String.fromEnvironment('API_BASE_URL', defaultValue: ''),
  'http://127.0.0.1:5000/api/v1',
  'http://192.168.1.70:5000/api/v1', // dev PC on home Wi-Fi
  'http://10.152.112.28:5000/api/v1', // dev PC on the phone's hotspot
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

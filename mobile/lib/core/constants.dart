/// Base URL of the GrowWithMe backend.
///
/// Default assumes a USB-connected device with the port bridged to the PC:
///   adb reverse tcp:5000 tcp:5000
/// (127.0.0.1, not localhost — some Android versions resolve localhost to
/// IPv6 first, which the adb bridge does not forward.)
///
/// Override per device/environment with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000/api/v1
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000/api/v1',
);

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

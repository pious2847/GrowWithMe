import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Phone alert notifications for reminders — fires at the exact moment she
/// chose, fully offline. The server's day-before SMS remains the safety net.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final dynamic info = await FlutterTimezone.getLocalTimezone();
        final name = info is String ? info : (info.identifier as String);
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // Fall back to the device offset via tz.local default.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {
      // Notifications are an enhancement — never break the app over them.
    }
  }

  int _idFor(String reminderId) => reminderId.hashCode & 0x7fffffff;

  Future<void> schedule({
    required String reminderId,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_ready || when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: _idFor(reminderId),
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'care_reminders',
            'Care reminders',
            channelDescription: 'GrowWithMe visit and care reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  Future<void> cancel(String reminderId) async {
    try {
      await _plugin.cancel(id: _idFor(reminderId));
    } catch (_) {}
  }
}

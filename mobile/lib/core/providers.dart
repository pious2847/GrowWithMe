import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_client.dart';
import '../data/auth/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/sync/sync_service.dart';
import '../data/voice/tts_service.dart';
import '../data/widget/widget_service.dart';
import 'constants.dart';

final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(secureStorageProvider)));

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final syncServiceProvider = Provider<SyncService>(
    (ref) => SyncService(ref.watch(dbProvider), ref.watch(apiClientProvider)));

final widgetServiceProvider =
    Provider<WidgetService>((ref) => WidgetService(ref.watch(dbProvider)));

final ttsProvider = Provider<TtsService>((ref) => TtsService());

/// Display name saved at login/onboarding for the home-screen greeting.
final userNameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userName');
});

/// true = signed in. Starts by checking for a stored access token.
class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token =
        await ref.read(secureStorageProvider).read(key: kAccessTokenKey);
    return token != null;
  }

  void signedIn() => state = const AsyncData(true);

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kLastPulledAtKey);
    state = const AsyncData(false);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, bool>(AuthController.new);

/// Runs sync and exposes last successful sync time (null until first sync).
///
/// Concurrent triggers (screen open + connectivity change + after a save) are
/// coalesced: while a sync is in flight, further calls queue at most one
/// trailing run instead of hammering the backend.
class SyncController extends AsyncNotifier<DateTime?> {
  bool _inFlight = false;
  bool _queued = false;

  @override
  Future<DateTime?> build() async => null;

  Future<bool> sync() async {
    if (_inFlight) {
      _queued = true;
      return false;
    }
    _inFlight = true;
    state = const AsyncLoading();
    try {
      await ref.read(syncServiceProvider).syncNow();
      state = AsyncData(DateTime.now());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    } finally {
      _inFlight = false;
      // Keep the home-screen widget in step with local data even when the
      // sync itself failed offline — the widget is fully local.
      ref.read(widgetServiceProvider).refresh();
      if (_queued) {
        _queued = false;
        Future.microtask(sync);
      }
    }
  }
}

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, DateTime?>(SyncController.new);

final childrenProvider =
    StreamProvider((ref) => ref.watch(dbProvider).watchChildren());

final remindersProvider =
    StreamProvider((ref) => ref.watch(dbProvider).watchUpcomingReminders());

final allRemindersProvider =
    StreamProvider((ref) => ref.watch(dbProvider).watchAllReminders());

final pregnanciesProvider =
    StreamProvider((ref) => ref.watch(dbProvider).watchPregnancies());

final alertsProvider =
    StreamProvider((ref) => ref.watch(dbProvider).watchAlerts());

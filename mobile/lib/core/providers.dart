import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/action/action_logger.dart';
import '../data/api/api_client.dart';
import '../data/auth/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/model/model_service.dart';
import '../data/model/nlu_service.dart';
import '../data/model/on_device_model.dart';
import '../data/assistant/nana_assistant.dart';
import '../data/diet/diet_planner.dart';
import '../data/diet/tips_updater.dart';
import '../data/notifications/notification_service.dart';
import '../data/repositories/care_actions.dart';
import '../data/sync/sync_service.dart';
import '../data/voice/nana_voice.dart';
import '../data/voice/tts_service.dart';
import '../data/widget/widget_service.dart';
import 'constants.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(secureStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

final actionLoggerProvider = Provider<ActionLogger>(
  (ref) => ActionLogger(ref.watch(apiClientProvider)),
);

/// Explicit opt-in for anonymous interaction logging (used to train the
/// on-device action model). Off by default.
class ActionConsentController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(actionLoggerProvider).hasConsent();

  Future<void> set(bool consent) async {
    await ref.read(actionLoggerProvider).setConsent(consent);
    state = AsyncData(consent);
    if (consent) {
      await ref.read(actionLoggerProvider).flush();
    }
  }
}

final actionConsentProvider =
    AsyncNotifierProvider<ActionConsentController, bool>(
      ActionConsentController.new,
    );

/// Which bottom tab is showing. Lifted out of the shell so Nana's companion
/// can take a caregiver straight to her calendar or alerts without duplicating
/// navigation logic.
class HomeTabController extends Notifier<int> {
  @override
  int build() => 0;

  void open(int index) {
    if (index < 0 || index > 3) return;
    state = index;
  }
}

final homeTabProvider = NotifierProvider<HomeTabController, int>(
  HomeTabController.new,
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(dbProvider), ref.watch(apiClientProvider)),
);

final widgetServiceProvider = Provider<WidgetService>(
  (ref) => WidgetService(ref.watch(dbProvider)),
);

final ttsProvider = Provider<TtsService>((ref) => TtsService());

final modelServiceProvider = Provider<ModelService>(
  (ref) => ModelService(ref.watch(apiClientProvider)),
);

final nluServiceProvider = Provider<NluService>(
  (ref) => NluService(ref.watch(apiClientProvider)),
);

final slmServiceProvider = Provider<OnDeviceModel>(
  (ref) => OnDeviceModel(ref.watch(apiClientProvider), 'nana-slm'),
);

final nanaVoiceProvider = Provider<NanaVoice>(
  (ref) => NanaVoice(ref.watch(apiClientProvider), ref.watch(ttsProvider), ref),
);

final careActionsProvider = Provider<CareActions>(
  (ref) => CareActions(ref.watch(dbProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final nanaAssistantProvider = Provider<NanaAssistant>(
  (ref) => NanaAssistant(
    ref.watch(dbProvider),
    ref.watch(apiClientProvider),
    ref.watch(nluServiceProvider),
  ),
);

final dietPlannerProvider = Provider<DietPlanner>(
  (ref) => DietPlanner(
    ref.watch(dbProvider),
    ref.watch(apiClientProvider),
    ref.watch(nanaAssistantProvider),
  ),
);

final tipsUpdaterProvider = Provider<TipsUpdater>(
  (ref) => TipsUpdater(
    ref.watch(dbProvider),
    ref.watch(apiClientProvider),
    ref.watch(nanaAssistantProvider),
  ),
);

final dailyTipsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchDailyTips(),
);

final latestDietPlanProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchLatestDietPlan(),
);

final recentDietLogsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchRecentDietLogs(7),
);

final pregnancyAssessmentsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchPregnancyAssessments(),
);

final assessmentsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchAssessments(),
);

final growthRecordsProvider = StreamProvider.family(
  (ref, String childId) => ref.watch(dbProvider).watchGrowthRecords(childId),
);

final allGrowthRecordsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchAllGrowthRecords(),
);

/// Diet logs from a given day (YYYY-MM-DD) onwards — the weekly report looks
/// back over the last twelve weeks for Nana Plus members.
final dietLogsSinceProvider = StreamProvider.family<List<DietLogRow>, String>(
  (ref, dayKey) => ref.watch(dbProvider).watchDietLogsSince(dayKey),
);

/// Voice mode for non-literate users: when on, the app automatically reads
/// each triage question and result aloud.
class AutoVoiceController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('autoVoice') ?? false;
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    state = AsyncData(!current);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoVoice', !current);
  }
}

final autoVoiceProvider = AsyncNotifierProvider<AutoVoiceController, bool>(
  AutoVoiceController.new,
);

/// Selected natural voice provider: 'elevenlabs' or 'fish_audio'.
class VoiceProviderController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('voiceProvider') ?? 'elevenlabs';
  }

  Future<void> setProvider(String provider) async {
    state = AsyncData(provider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voiceProvider', provider);
  }
}

final voiceProviderProvider =
    AsyncNotifierProvider<VoiceProviderController, String>(
      VoiceProviderController.new,
    );

/// Display name saved at login/onboarding for the home-screen greeting.
final userNameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userName');
});

/// true = signed in. Starts by checking for a stored access token.
class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final token = await ref
        .read(secureStorageProvider)
        .read(key: kAccessTokenKey);
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

final authControllerProvider = AsyncNotifierProvider<AuthController, bool>(
  AuthController.new,
);

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
      // Sync failures were previously invisible — a broken pull looked like
      // "the app lost my data". Always leave a trace in the console.
      debugPrint('[sync] FAILED: $e\n$st');
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

final syncControllerProvider = AsyncNotifierProvider<SyncController, DateTime?>(
  SyncController.new,
);

final childrenProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchChildren(),
);

final remindersProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchUpcomingReminders(),
);

final allRemindersProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchAllReminders(),
);

final pregnanciesProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchPregnancies(),
);

final alertsProvider = StreamProvider(
  (ref) => ref.watch(dbProvider).watchAlerts(),
);

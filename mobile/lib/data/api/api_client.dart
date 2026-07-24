import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

/// Dio wrapper with:
/// - self-healing base URL: probes the candidate servers (USB bridge, Wi-Fi
///   LAN, build-time override) and locks onto whichever answers /health,
///   re-probing after connection failures — so the app finds the backend
///   whether or not the USB cable is attached;
/// - access-token attach + one transparent refresh on 401.
class ApiClient {
  ApiClient(this._storage)
      : dio = Dio(BaseOptions(
          baseUrl: kApiBaseCandidates.firstWhere((c) => c.isNotEmpty),
          connectTimeout: const Duration(seconds: 8),
        )) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          await _ensureBaseUrl();
          options.baseUrl = dio.options.baseUrl;
          final token = await _storage.read(key: kAccessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Server unreachable on the current route — re-probe next time.
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout) {
            _resolved = false;
          }
          final isAuthRoute = error.requestOptions.path.contains('/auth/');
          if (error.response?.statusCode == 401 && !isAuthRoute) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final retried = await dio.fetch(error.requestOptions);
                return handler.resolve(retried);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage _storage;
  // A single candidate (release builds) needs no probing.
  late bool _resolved =
      kApiBaseCandidates.where((c) => c.isNotEmpty).length <= 1;

  /// Marks the base URL as stale so the next request re-probes (call on
  /// connectivity changes).
  void invalidateBaseUrl() => _resolved = false;

  Future<void> _ensureBaseUrl() async {
    if (_resolved) return;
    // Generous enough for a sleeping free-tier server to wake up; local
    // candidates fail instantly (connection refused) so dev stays fast.
    final probe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
    ));
    for (final base in kApiBaseCandidates.where((c) => c.isNotEmpty)) {
      final healthUrl =
          '${base.replaceFirst(RegExp(r'/api/v1/?$'), '')}/health';
      try {
        final res = await probe.get<dynamic>(healthUrl);
        if (res.statusCode == 200) {
          dio.options.baseUrl = base;
          _resolved = true;
          return;
        }
      } catch (_) {
        // try the next candidate
      }
    }
    // Nothing reachable — keep the current base; callers' offline fallbacks
    // (local intents, device TTS, queued sync) take over.
  }

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: kRefreshTokenKey);
    if (refreshToken == null) return false;
    try {
      // Bare client: the interceptor above must not run for the refresh call.
      final res = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
          .post('/auth/refresh', data: {'refreshToken': refreshToken});
      final tokens = res.data['tokens'] as Map<String, dynamic>;
      await saveTokens(tokens);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    await _storage.write(key: kAccessTokenKey, value: tokens['accessToken'] as String);
    await _storage.write(key: kRefreshTokenKey, value: tokens['refreshToken'] as String);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: kAccessTokenKey);
    await _storage.delete(key: kRefreshTokenKey);
  }
}

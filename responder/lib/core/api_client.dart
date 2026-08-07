import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants.dart';

/// Singleton API client, same resolution strategy as the caregiver app:
/// every request first ensures the base URL points at a server that answers
/// /health (USB bridge in dev, deployed backend otherwise), then attaches the
/// bearer token; one transparent refresh-and-retry on 401.
class Api {
  Api._() {
    dio = Dio(BaseOptions(
      baseUrl: kApiBaseCandidates.firstWhere((c) => c.isNotEmpty),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 60), // Render cold starts
    ));
    dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        await _ensureBaseUrl();
        options.baseUrl = dio.options.baseUrl;
        final token = await storage.read(key: kAccessTokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (err, handler) async {
        // Server unreachable on the current route — re-probe next time.
        if (err.type == DioExceptionType.connectionError ||
            err.type == DioExceptionType.connectionTimeout) {
          _resolved = false;
        }
        final isAuthRoute = err.requestOptions.path.contains('/auth/');
        if (err.response?.statusCode == 401 && !isAuthRoute) {
          if (await _refresh()) {
            final opts = err.requestOptions;
            final token = await storage.read(key: kAccessTokenKey);
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              return handler.resolve(await dio.fetch(opts));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        handler.next(err);
      },
    ));
  }

  static final Api I = Api._();
  late final Dio dio;
  final storage = const FlutterSecureStorage();

  // A single candidate (release builds) needs no probing.
  late bool _resolved =
      kApiBaseCandidates.where((c) => c.isNotEmpty).length <= 1;

  Future<void> _ensureBaseUrl() async {
    if (_resolved) return;
    // Generous enough for a sleeping free-tier server to wake up; local
    // candidates fail instantly (connection refused) so dev stays fast.
    final probe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 8),
    ));
    for (final base in kApiBaseCandidates.where((c) => c.isNotEmpty)) {
      final healthUrl = '${base.replaceFirst(RegExp(r'/api/v1/?$'), '')}/health';
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
    // Nothing reachable — keep the current base and let the request fail
    // normally so screens can show their offline message.
  }

  Future<bool> _refresh() async {
    final refresh = await storage.read(key: kRefreshTokenKey);
    if (refresh == null) return false;
    try {
      // Bare client: the interceptor above must not run for the refresh call.
      final res = await Dio(BaseOptions(baseUrl: dio.options.baseUrl))
          .post('/auth/refresh', data: {'refreshToken': refresh});
      final tokens = res.data['tokens'] as Map<String, dynamic>;
      await saveTokens(tokens);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    await storage.write(
        key: kAccessTokenKey, value: tokens['accessToken'] as String?);
    await storage.write(
        key: kRefreshTokenKey, value: tokens['refreshToken'] as String?);
  }

  Future<bool> hasSession() async =>
      await storage.read(key: kAccessTokenKey) != null;

  Future<void> logout() async {
    await storage.delete(key: kAccessTokenKey);
    await storage.delete(key: kRefreshTokenKey);
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants.dart';

/// Dio wrapper that attaches the access token and transparently refreshes it
/// once on a 401 before failing.
class ApiClient {
  ApiClient(this._storage) : dio = Dio(BaseOptions(baseUrl: kApiBaseUrl)) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: kAccessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthRoute =
              error.requestOptions.path.contains('/auth/');
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

  Future<bool> _tryRefresh() async {
    final refreshToken = await _storage.read(key: kRefreshTokenKey);
    if (refreshToken == null) return false;
    try {
      // Bare client: the interceptor above must not run for the refresh call.
      final res = await Dio(BaseOptions(baseUrl: kApiBaseUrl))
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

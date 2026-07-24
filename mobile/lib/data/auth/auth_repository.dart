import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class VerifyOtpResult {
  VerifyOtpResult({required this.isNewUser, required this.user});

  final bool isNewUser;
  final Map<String, dynamic> user;
}

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<void> requestOtp(String phone) async {
    await _api.dio.post('/auth/request-otp', data: {'phone': phone});
  }

  Future<VerifyOtpResult> verifyOtp(String phone, String code) async {
    final res = await _api.dio
        .post('/auth/verify-otp', data: {'phone': phone, 'code': code});
    await _api.saveTokens(res.data['tokens'] as Map<String, dynamic>);
    final user = res.data['user'] as Map<String, dynamic>;
    final name = user['name'] as String?;
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
    }
    return VerifyOtpResult(
      isNewUser: res.data['isNewUser'] as bool? ?? false,
      user: user,
    );
  }

  /// Onboarding profile + consent flags (MEST policy: explicit consent).
  Future<void> updateProfile(Map<String, dynamic> patch) async {
    await _api.dio.patch('/users/me', data: patch);
    final name = patch['name'] as String?;
    if (name != null && name.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
    }
  }

  Future<void> signOut() => _api.clearTokens();
}

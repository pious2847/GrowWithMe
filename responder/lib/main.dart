import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/alerts/alert_detail.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/consent_screen.dart';
import 'features/onboarding/documents_screen.dart';
import 'features/onboarding/profile_screen.dart';
import 'features/onboarding/verification_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(const ResponderApp());

class ResponderApp extends StatefulWidget {
  const ResponderApp({super.key});

  @override
  State<ResponderApp> createState() => _ResponderAppState();
}

class _ResponderAppState extends State<ResponderApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    // growwithme://alert/<id> — from the SMS deep-link page.
    _appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'alert' && uri.pathSegments.isNotEmpty) {
        navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (_) => AlertDetailScreen(alertId: uri.pathSegments.first)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowWithMe Responder',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3FAF8),
      ),
      home: const SplashGate(),
    );
  }
}

/// Decides where the user lands: login → profile → documents → home.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    Widget dest = const LoginScreen();
    if (await Api.I.hasSession()) {
      try {
        final res = await Api.I.dio.get('/users/me');
        final user = res.data['user'] as Map<String, dynamic>;
        dest = routeForUser(user);
      } catch (_) {
        dest = const LoginScreen();
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🩺', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('GrowWithMe Responder',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Registration flow: consent → profile → documents → verification → home.
/// Resumes at the exact step the user stopped at; rejected accounts land on
/// the verification screen to see the reviewer's note and re-submit.
Widget routeForUser(Map<String, dynamic> user) {
  if (user['consent']?['patientConfidentiality'] != true) {
    return ConsentScreen(user: user);
  }
  final isResponder = user['role'] == 'volunteer' || user['role'] == 'admin';
  final name = (user['name'] as String?) ?? '';
  if (!isResponder || name.isEmpty) return ProfileScreen(user: user);

  final docs =
      ((user['credentials']?['documents'] as List?) ?? []).cast<Map<String, dynamic>>();
  final hasGhanaCard = docs.any((d) => d['kind'] == 'ghana_card');
  final needsLicense = const ['nurse', 'midwife', 'doctor']
      .contains(user['credentials']?['tier'] as String?);
  final hasLicense = docs.any((d) => d['kind'] == 'license');
  if (!hasGhanaCard || (needsLicense && !hasLicense)) {
    return DocumentsScreen(user: user);
  }
  if (user['credentials']?['status'] == 'rejected') {
    return VerificationScreen(user: user);
  }
  return HomeShell(user: user);
}

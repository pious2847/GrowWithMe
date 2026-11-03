import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/offline_cache.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/ui/app_widgets.dart';
import 'features/alerts/alert_detail.dart';
import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/consent_screen.dart';
import 'features/onboarding/documents_screen.dart';
import 'features/onboarding/profile_screen.dart';
import 'features/onboarding/verification_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// An SMS deep link that arrived before the app knew who the user was.
/// [HomeShell] opens it after the first frame.
String? _pendingAlertId;

String? takePendingAlertId() {
  final value = _pendingAlertId;
  _pendingAlertId = null;
  return value;
}

void main() => runApp(const ResponderApp());

class ResponderApp extends StatefulWidget {
  const ResponderApp({super.key});

  @override
  State<ResponderApp> createState() => _ResponderAppState();
}

class _ResponderAppState extends State<ResponderApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // growwithme://alert/<id> — from the SMS deep-link page.
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    }).catchError((_) {});
  }

  void _handleUri(Uri uri) {
    if (uri.host != 'alert' || uri.pathSegments.isEmpty) return;
    final id = uri.pathSegments.first;
    _openAlertLink(id);
  }

  Future<void> _openAlertLink(String id) async {
    if (!await Api.I.hasSession()) {
      _pendingAlertId = id;
      return;
    }
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingAlertId = id;
      return;
    }
    nav.push(MaterialPageRoute(builder: (_) => AlertDetailScreen(alertId: id)));
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowWithMe Responder',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
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
      final cached = await OfflineCache.get('me');
      final cachedUser =
          cached is Map ? Map<String, dynamic>.from(cached) : null;
      try {
        // Never hold the splash hostage to a cold server: a sleeping free
        // tier can take a minute to wake. Past 6s we route on the cached
        // profile (or login) and let the shell refresh in the background.
        final res = await Api.I.dio
            .get('/users/me')
            .timeout(const Duration(seconds: 6));
        final user = Map<String, dynamic>.from(res.data['user'] as Map);
        await OfflineCache.put('me', user);
        dest = routeForUser(user);
      } catch (_) {
        dest = cachedUser == null
            ? const LoginScreen()
            : routeForUser(cachedUser);
      }
    }
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ResponderMark(size: 84),
              const SizedBox(height: 22),
              Text(
                'GrowWithMe',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.forestDeep,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'RESPONDER',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.2,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 34),
              const _LoadingBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  const _LoadingBar();

  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          children: [
            Container(color: AppColors.sand),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return FractionallySizedBox(
                  widthFactor: 0.42,
                  alignment: Alignment(-1 + 2 * _controller.value, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.limeGradient,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                );
              },
            ),
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

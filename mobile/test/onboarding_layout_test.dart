import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/core/theme/app_theme.dart';
import 'package:grow_with_me/features/onboarding/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the welcome screen against the layout regression that clipped the
/// Skip action on 360 dp phones. Real brand fonts are loaded so text metrics
/// match the device instead of the test framework's fallback font.
void main() {
  setUpAll(() async {
    final manrope = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Variable.ttf'));
    final fraunces = FontLoader('Fraunces')
      ..addFont(rootBundle.load('assets/fonts/Fraunces-Variable.ttf'));
    await Future.wait([manrope.load(), fraunces.load()]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpWelcome(WidgetTester tester, Size logical) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = logical * 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets('welcome header fits a 360 x 800 phone', (tester) async {
    await pumpWelcome(tester, const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('GrowWithMe'), findsOneWidget);
  });

  testWidgets('welcome header fits a narrow 320 x 700 phone', (tester) async {
    await pumpWelcome(tester, const Size(320, 700));
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('welcome header survives large accessibility text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpWelcome(tester, const Size(360, 800));
    expect(tester.takeException(), isNull);
    expect(find.text('Skip'), findsOneWidget);
  });
}

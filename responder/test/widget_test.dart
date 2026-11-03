import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grow_with_me_responder/core/theme/app_theme.dart';
import 'package:grow_with_me_responder/features/auth/login_screen.dart';

void main() {
  testWidgets('Login screen renders the responder promise', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LoginScreen()),
    );
    await tester.pump();

    expect(find.text('GrowWithMe'), findsOneWidget);
    expect(
      find.text('Answer the call\nwhen it matters most.'),
      findsOneWidget,
    );
    expect(find.text('SIGN IN OR JOIN'), findsOneWidget);
    expect(find.text('Send me a code'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grow_with_me_responder/features/auth/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('GrowWithMe Responder'), findsOneWidget);
    expect(find.text('Send code by SMS'), findsOneWidget);
  });
}

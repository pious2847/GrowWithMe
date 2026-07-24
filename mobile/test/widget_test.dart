import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grow_with_me/domain/triage/triage_engine.dart';

void main() {
  testWidgets('smoke: MaterialApp builds', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });

  test('triage: danger sign classifies as urgent', () {
    final result = TriageEngine.evaluate('child', {
      'dangerSigns': ['Convulsions or fits'],
    });
    expect(result.riskLevel, 'urgent');
    expect(result.dangerSigns, contains('Convulsions or fits'));
  });

  test('triage: fever 3+ days classifies as moderate', () {
    final result = TriageEngine.evaluate('child', {
      'dangerSigns': ['None of these'],
      'fever': true,
      'feverDays': 4,
      'stiffNeck': false,
    });
    expect(result.riskLevel, 'moderate');
  });

  test('triage: no signs classifies as low', () {
    final result = TriageEngine.evaluate('child', {
      'dangerSigns': ['None of these'],
      'fever': false,
      'cough': false,
      'diarrhoea': false,
      'eatingPoorly': false,
    });
    expect(result.riskLevel, 'low');
  });

  test('triage: reduced fetal movement is urgent', () {
    final result = TriageEngine.evaluate('pregnancy', {
      'dangerSigns': ['None of these'],
      'reducedMovement': true,
    });
    expect(result.riskLevel, 'urgent');
  });
}

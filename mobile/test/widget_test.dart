import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:grow_with_me/domain/checkin.dart';
import 'package:grow_with_me/domain/diet_guide.dart';
import 'package:grow_with_me/domain/growth_reference.dart';
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

  test('growth: healthy weight passes screening', () {
    final result = assessWeight(7.9, 6, 'male');
    expect(result.status, GrowthStatus.healthy);
  });

  test('growth: low weight flags underweight', () {
    final result = assessWeight(6.0, 6, 'male');
    expect(result.status, GrowthStatus.underweight);
  });

  test('growth: very low weight flags severe', () {
    final result = assessWeight(5.0, 6, 'male');
    expect(result.status, GrowthStatus.severelyUnderweight);
  });

  test('checkin: danger yes is urgent even if AI adds soft questions', () {
    final questions = mergeQuestions(const [
      CheckinQuestion('ai_1', 'Are you sleeping well at night?', 'info'),
    ]);
    final result = evaluateCheckin(questions, {'core_bleeding': true});
    expect(result.riskLevel, 'urgent');
  });

  test('checkin: caution yes is moderate', () {
    final result =
        evaluateCheckin(coreCheckinQuestions, {'core_swelling': true});
    expect(result.riskLevel, 'moderate');
  });

  test('checkin: AI cannot duplicate core danger topics', () {
    final merged = mergeQuestions(const [
      CheckinQuestion('ai_1', 'Have you noticed any bleeding today?', 'info'),
      CheckinQuestion('ai_2', 'Are you eating three meals?', 'info'),
    ]);
    // The AI's watered-down "bleeding" question (info!) must be dropped in
    // favour of the core danger version.
    expect(merged.where((q) => q.text.toLowerCase().contains('bleed')).length, 1);
    expect(
        merged.firstWhere((q) => q.text.toLowerCase().contains('bleed')).category,
        'danger');
  });

  test('diet: seasons map to Northern Ghana calendar', () {
    expect(currentSeason(DateTime(2026, 7, 1)), 'rainy');
    expect(currentSeason(DateTime(2026, 11, 1)), 'harvest');
    expect(currentSeason(DateTime(2026, 2, 1)), 'dry');
  });

  test('diet: diversity score counts unique groups', () {
    expect(diversityScore([0, 1, 1, 2]), 3);
    expect(diversityScore([]), 0);
  });

  test('diet: offline plan gives two choices per meal slot', () {
    final plan = offlinePlan('pregnancy', 'dry');
    final slots = planSlots(plan);
    expect(slots.length, greaterThanOrEqualTo(4));
    for (final slot in slots) {
      expect((slot['options'] as List).length, 2,
          reason: '${slot['time']} should offer a choice');
    }
    expect(plan['summary'], isNotEmpty);
  });

  test('diet: planSlots tolerates legacy single-meal plans', () {
    final slots = planSlots({
      'meals': [
        {'time': 'Morning', 'name': 'Old-style koko', 'ingredients': 'koko'},
      ],
    });
    expect(slots.length, 1);
    expect((slots.first['options'] as List).first['name'], 'Old-style koko');
  });

  test('triage: reduced fetal movement is urgent', () {
    final result = TriageEngine.evaluate('pregnancy', {
      'dangerSigns': ['None of these'],
      'reducedMovement': true,
    });
    expect(result.riskLevel, 'urgent');
  });
}

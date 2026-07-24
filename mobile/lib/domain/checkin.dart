import 'triage/triage_engine.dart';

/// Periodic pregnancy check-in (every 2–3 days). The AI personalizes extra
/// questions from her history, but this deterministic core ALWAYS runs and
/// always wins: AI can add caution, never remove it.
class CheckinQuestion {
  const CheckinQuestion(this.id, this.text, this.category);

  final String id;
  final String text;
  final String category; // danger | caution | info

  factory CheckinQuestion.fromJson(Map<String, dynamic> d) => CheckinQuestion(
        d['id'] as String? ?? 'q',
        d['text'] as String? ?? '',
        d['category'] as String? ?? 'info',
      );
}

const coreCheckinQuestions = <CheckinQuestion>[
  CheckinQuestion('core_bleeding', 'Have you had any vaginal bleeding?', 'danger'),
  CheckinQuestion('core_fits', 'Have you had fits, or a severe headache with blurred vision?', 'danger'),
  CheckinQuestion('core_pain', 'Do you have severe belly pain?', 'danger'),
  CheckinQuestion('core_water', 'Has your water broken?', 'danger'),
  CheckinQuestion('core_movement', 'Is the baby moving less than usual?', 'danger'),
  CheckinQuestion('core_fever', 'Have you had a fever since your last check-in?', 'caution'),
  CheckinQuestion('core_swelling', 'Is your face or are your hands swollen?', 'caution'),
];

/// Merge AI questions after the core, dropping near-duplicates of core topics.
List<CheckinQuestion> mergeQuestions(List<CheckinQuestion> aiQuestions) {
  const coveredTopics = ['bleed', 'fit', 'headache', 'pain', 'water', 'moving', 'movement', 'fever', 'swell'];
  final extras = aiQuestions.where((q) {
    final t = q.text.toLowerCase();
    return !coveredTopics.any(t.contains);
  }).toList();
  return [...coreCheckinQuestions, ...extras];
}

/// Deterministic classification — errs toward escalation:
/// any danger YES → urgent; any caution YES → moderate; else low.
TriageResult evaluateCheckin(
    List<CheckinQuestion> questions, Map<String, bool> answers) {
  final dangerYes = <String>[];
  final cautionYes = <String>[];
  for (final q in questions) {
    if (answers[q.id] != true) continue;
    if (q.category == 'danger') dangerYes.add(q.text);
    if (q.category == 'caution') cautionYes.add(q.text);
  }

  if (dangerYes.isNotEmpty) {
    return TriageResult(
      riskLevel: 'urgent',
      dangerSigns: dangerYes,
      guidance:
          'These are danger signs in pregnancy. You need to be seen at a health '
          'facility NOW. Your volunteer, facility and your registered hospital '
          'are being alerted with your report. Arrange transport immediately.',
    );
  }
  if (cautionYes.isNotEmpty) {
    return TriageResult(
      riskLevel: 'moderate',
      dangerSigns: cautionYes,
      guidance:
          'Some answers need a nurse\'s eyes. Please visit your clinic or CHPS '
          'compound within 24 hours. Rest, drink fluids, and if any danger sign '
          'appears — bleeding, fits, severe pain — go immediately.',
    );
  }
  return const TriageResult(
    riskLevel: 'low',
    dangerSigns: [],
    guidance:
        'All is well today. Keep eating well, take your iron tablets, sleep '
        'under a net, and I will check on you again in a few days.',
  );
}

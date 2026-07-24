/// Deterministic, on-device triage aligned with WHO IMCI danger signs and
/// simplified for the hackathon MVP. The flow is adaptive: follow-up
/// questions appear based on earlier answers (showIf). Classification always
/// errs on the side of escalation — ambiguous cases go to the higher risk.
///
/// This runs fully offline; the result is stored locally and synced later.
library;

enum QuestionType { yesNo, multi, number }

class TriageQuestion {
  const TriageQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options,
    this.showIf,
  });

  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options;
  final bool Function(Map<String, dynamic> answers)? showIf;

  bool isVisible(Map<String, dynamic> answers) =>
      showIf == null || showIf!(answers);
}

class TriageResult {
  const TriageResult({
    required this.riskLevel,
    required this.dangerSigns,
    required this.guidance,
  });

  final String riskLevel; // low | moderate | urgent
  final List<String> dangerSigns;
  final String guidance;
}

bool _yes(Map<String, dynamic> a, String id) => a[id] == true;
List<String> _multi(Map<String, dynamic> a, String id) =>
    (a[id] as List?)?.cast<String>() ?? const [];

const _noneOption = 'None of these';

class TriageEngine {
  static const childQuestions = <TriageQuestion>[
    TriageQuestion(
      id: 'dangerSigns',
      text: 'Does the child have any of these signs right now?',
      type: QuestionType.multi,
      options: [
        'Convulsions or fits',
        'Unconscious or very sleepy',
        'Unable to drink or breastfeed',
        'Vomits everything',
        _noneOption,
      ],
    ),
    TriageQuestion(id: 'fever', text: 'Does the child have a fever?', type: QuestionType.yesNo),
    TriageQuestion(
      id: 'feverDays',
      text: 'For how many days has the fever lasted?',
      type: QuestionType.number,
      showIf: _hasFever,
    ),
    TriageQuestion(
      id: 'stiffNeck',
      text: 'Does the child have a stiff neck?',
      type: QuestionType.yesNo,
      showIf: _hasFever,
    ),
    TriageQuestion(id: 'cough', text: 'Does the child have a cough or difficulty breathing?', type: QuestionType.yesNo),
    TriageQuestion(
      id: 'coughDays',
      text: 'For how many days has the cough lasted?',
      type: QuestionType.number,
      showIf: _hasCough,
    ),
    TriageQuestion(
      id: 'fastBreathing',
      text: 'Is the child breathing faster than usual?',
      type: QuestionType.yesNo,
      showIf: _hasCough,
    ),
    TriageQuestion(
      id: 'chestIndrawing',
      text: 'Does the skin pull in below the ribs when the child breathes in?',
      type: QuestionType.yesNo,
      showIf: _hasCough,
    ),
    TriageQuestion(id: 'diarrhoea', text: 'Does the child have diarrhoea?', type: QuestionType.yesNo),
    TriageQuestion(
      id: 'bloodInStool',
      text: 'Is there blood in the stool?',
      type: QuestionType.yesNo,
      showIf: _hasDiarrhoea,
    ),
    TriageQuestion(
      id: 'sunkenEyes',
      text: 'Are the child\'s eyes sunken, or is the child very thirsty?',
      type: QuestionType.yesNo,
      showIf: _hasDiarrhoea,
    ),
    TriageQuestion(
      id: 'eatingPoorly',
      text: 'Has the child been eating much less than usual for more than a week?',
      type: QuestionType.yesNo,
    ),
  ];

  static const pregnancyQuestions = <TriageQuestion>[
    TriageQuestion(
      id: 'dangerSigns',
      text: 'Do you have any of these signs right now?',
      type: QuestionType.multi,
      options: [
        'Vaginal bleeding',
        'Convulsions or fits',
        'Severe headache with blurred vision',
        'Severe abdominal pain',
        'Water has broken before time',
        _noneOption,
      ],
    ),
    TriageQuestion(id: 'feverPreg', text: 'Do you have a fever?', type: QuestionType.yesNo),
    TriageQuestion(
      id: 'reducedMovement',
      text: 'Has the baby been moving less than usual today?',
      type: QuestionType.yesNo,
    ),
    TriageQuestion(
      id: 'swelling',
      text: 'Do you have swelling of the face or hands?',
      type: QuestionType.yesNo,
    ),
    TriageQuestion(
      id: 'tirednessPale',
      text: 'Do you feel unusually tired, weak or look pale?',
      type: QuestionType.yesNo,
    ),
  ];

  static bool _hasFever(Map<String, dynamic> a) => _yes(a, 'fever');
  static bool _hasCough(Map<String, dynamic> a) => _yes(a, 'cough');
  static bool _hasDiarrhoea(Map<String, dynamic> a) => _yes(a, 'diarrhoea');

  static List<TriageQuestion> questionsFor(String subjectType) =>
      subjectType == 'child' ? childQuestions : pregnancyQuestions;

  static TriageResult evaluate(String subjectType, Map<String, dynamic> answers) {
    return subjectType == 'child'
        ? _evaluateChild(answers)
        : _evaluatePregnancy(answers);
  }

  static TriageResult _evaluateChild(Map<String, dynamic> a) {
    final urgentSigns = <String>[
      ..._multi(a, 'dangerSigns').where((s) => s != _noneOption),
      if (_yes(a, 'stiffNeck')) 'Stiff neck with fever',
      if (_yes(a, 'chestIndrawing')) 'Chest indrawing',
      if (_yes(a, 'bloodInStool')) 'Blood in stool',
      if (_yes(a, 'sunkenEyes')) 'Signs of dehydration',
    ];
    if (urgentSigns.isNotEmpty) {
      return TriageResult(
        riskLevel: 'urgent',
        dangerSigns: urgentSigns,
        guidance:
            'This child needs care at a health facility NOW. A nearby volunteer and facility '
            'are being alerted. Keep the child warm, continue breastfeeding or giving fluids '
            'if the child can swallow, and start moving toward the nearest facility.',
      );
    }

    final moderateSigns = <String>[
      if ((a['feverDays'] as num? ?? 0) >= 3) 'Fever for 3 days or more',
      if (_yes(a, 'fastBreathing')) 'Fast breathing',
      if ((a['coughDays'] as num? ?? 0) >= 14) 'Cough for 2 weeks or more',
      if (_yes(a, 'diarrhoea') && !_yes(a, 'sunkenEyes')) 'Diarrhoea',
      if (_yes(a, 'eatingPoorly')) 'Poor feeding for over a week',
      if (_yes(a, 'fever') && (a['feverDays'] as num? ?? 0) < 3) 'Fever',
    ];
    if (moderateSigns.isNotEmpty) {
      return TriageResult(
        riskLevel: 'moderate',
        dangerSigns: moderateSigns,
        guidance:
            'Please take the child to the nearest CHPS compound or clinic within 24 hours. '
            'Give extra fluids and continue feeding. If any danger sign appears — convulsions, '
            'vomiting everything, unable to drink, very sleepy — go to a facility immediately.',
      );
    }

    return const TriageResult(
      riskLevel: 'low',
      dangerSigns: [],
      guidance:
          'No danger signs found. Continue normal feeding and keep the child hydrated. '
          'Watch for: fever, fast breathing, vomiting, or the child becoming unusually sleepy. '
          'Reassess with this app if anything changes, and keep upcoming clinic visits.',
    );
  }

  static TriageResult _evaluatePregnancy(Map<String, dynamic> a) {
    final urgentSigns = <String>[
      ..._multi(a, 'dangerSigns').where((s) => s != _noneOption),
      if (_yes(a, 'reducedMovement')) 'Reduced baby movement',
    ];
    if (urgentSigns.isNotEmpty) {
      return TriageResult(
        riskLevel: 'urgent',
        dangerSigns: urgentSigns,
        guidance:
            'These are danger signs in pregnancy. You need to be seen at a health facility NOW. '
            'A nearby volunteer and facility are being alerted. Do not wait — arrange transport '
            'immediately and do not travel alone if possible.',
      );
    }

    final moderateSigns = <String>[
      if (_yes(a, 'feverPreg')) 'Fever in pregnancy',
      if (_yes(a, 'swelling')) 'Swelling of face or hands',
      if (_yes(a, 'tirednessPale')) 'Possible anaemia (tiredness/paleness)',
    ];
    if (moderateSigns.isNotEmpty) {
      return TriageResult(
        riskLevel: 'moderate',
        dangerSigns: moderateSigns,
        guidance:
            'Please visit your nearest clinic or CHPS compound within 24 hours for a check-up. '
            'Rest, drink plenty of fluids, and go immediately if you notice bleeding, severe '
            'headache, blurred vision, or fits.',
      );
    }

    return const TriageResult(
      riskLevel: 'low',
      dangerSigns: [],
      guidance:
          'No danger signs found. Continue your antenatal visits, sleep under a treated bed net, '
          'eat iron-rich local foods, and reassess if you notice bleeding, severe headache, '
          'swelling, or reduced baby movement.',
    );
  }
}

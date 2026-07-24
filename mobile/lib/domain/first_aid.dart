/// "While help comes" first-response guidance shown (and spoken) with urgent
/// results — pre-facility actions a caregiver can take safely. Aligned with
/// WHO/IMCI first-response advice; never a substitute for the facility visit
/// the alert is already arranging.
library;

class FirstAidStep {
  const FirstAidStep(this.emoji, this.text);

  final String emoji;
  final String text;
}

const _bySign = <String, List<FirstAidStep>>{
  'Convulsions or fits': [
    FirstAidStep('🛏️', 'Lay the child on their side on a soft surface, away from fire and sharp things.'),
    FirstAidStep('🚫', 'Do not put anything in the mouth. Do not hold the child down.'),
    FirstAidStep('🌡️', 'If the body is hot, remove extra clothing and sponge with lukewarm water.'),
  ],
  'Unconscious or very sleepy': [
    FirstAidStep('🛏️', 'Lay the child on their side. Keep the airway clear.'),
    FirstAidStep('🧣', 'Keep the child warm but not covered over the face.'),
  ],
  'Unable to drink or breastfeed': [
    FirstAidStep('🥄', 'If the child can swallow, give small sips of breast milk or clean water with a spoon.'),
    FirstAidStep('🚫', 'Never force liquid into the mouth of a child who cannot swallow.'),
  ],
  'Vomits everything': [
    FirstAidStep('🥄', 'Give very small sips of fluid — one spoon every few minutes.'),
    FirstAidStep('🧂', 'If you have ORS, mix one full packet in one large water bottle (1 litre) of clean water.'),
  ],
  'Signs of dehydration': [
    FirstAidStep('🧂', 'Give ORS: small frequent sips. No ORS? Mix 6 level teaspoons sugar + half teaspoon salt in 1 litre clean water.'),
    FirstAidStep('🤱', 'Keep breastfeeding — more often than usual.'),
  ],
  'Blood in stool': [
    FirstAidStep('💧', 'Keep giving fluids and breast milk on the way to the facility.'),
  ],
  'Vaginal bleeding': [
    FirstAidStep('🛏️', 'Lie down on your left side while transport is arranged.'),
    FirstAidStep('🩸', 'Keep any soaked cloths to show the nurse how much bleeding there was.'),
  ],
  'Convulsions or fits (pregnancy)': [
    FirstAidStep('🛏️', 'Lie on the left side, away from anything sharp. Do not restrain.'),
  ],
  'Reduced baby movement': [
    FirstAidStep('🥤', 'Drink something cold and sweet, lie on your left side, and count movements while traveling.'),
  ],
};

const _general = <FirstAidStep>[
  FirstAidStep('🚶', 'Start moving toward the facility now — do not wait for symptoms to improve.'),
  FirstAidStep('🤱', 'Keep the child close to your body for warmth (skin-to-skin for babies).'),
  FirstAidStep('📱', 'Keep your phone with you — the volunteer or clinic may call.'),
];

/// Steps for the given danger signs, deduplicated, with general steps last.
List<FirstAidStep> firstAidFor(List<String> dangerSigns) {
  final steps = <FirstAidStep>[];
  for (final sign in dangerSigns) {
    final match = _bySign[sign];
    if (match != null) steps.addAll(match);
  }
  steps.addAll(_general);
  final seen = <String>{};
  return steps.where((s) => seen.add(s.text)).toList();
}

String firstAidSpeech(List<String> dangerSigns) =>
    'While help is coming, do this. ${firstAidFor(dangerSigns).map((s) => s.text).join(' ')}';

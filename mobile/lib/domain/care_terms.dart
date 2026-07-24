/// Plain-language glossary for medical terms — because "BCG + OPV 0" means
/// nothing to most caregivers. Every visit title gets a simple explanation
/// anyone can understand (and hear read aloud).
library;

class _Term {
  const _Term(this.keywords, this.plain);

  final List<String> keywords;
  final String plain;
}

const _terms = <_Term>[
  _Term(['bcg'], 'an injection that protects baby from TB (a serious cough sickness)'),
  _Term(['opv'], 'drops in the mouth that protect against polio'),
  _Term(['ipv'], 'an injection that protects against polio'),
  _Term(['penta'], 'one injection that protects against 5 sicknesses at once'),
  _Term(['pcv'], 'an injection that protects the lungs from pneumonia'),
  _Term(['rota'], 'drops that protect against severe diarrhoea'),
  _Term(['measles', 'mr '], 'an injection against measles and German measles'),
  _Term(['yellow fever'], 'an injection against yellow fever'),
  _Term(['mena', 'men a'], 'an injection against meningitis'),
  _Term(['vitamin a'], 'drops that keep the eyes strong and the body protected'),
  _Term(['deworm'], 'a tablet that removes worms from the belly'),
  _Term(['weighing', 'growth'], 'baby is weighed to check they are growing well'),
  _Term(['antenatal', 'anc'], 'a pregnancy check-up — the nurse checks you and the baby'),
  _Term(['postnatal', 'pnc'], 'a check-up for mother and baby after birth'),
  _Term(['family planning'], 'a talk about spacing your next pregnancy'),
];

/// Simple explanation for a visit title, or null when there is nothing
/// technical to explain (e.g. her own custom reminders).
String? explainCareTerm(String title) {
  final t = ' ${title.toLowerCase()} ';
  final parts = <String>[];
  for (final term in _terms) {
    if (term.keywords.any(t.contains) && !parts.contains(term.plain)) {
      parts.add(term.plain);
    }
  }
  if (parts.isEmpty) return null;
  if (parts.length == 1) return 'In simple words: ${parts.first}.';
  final last = parts.removeLast();
  return 'In simple words: ${parts.join('; ')}; and $last — all in one visit.';
}

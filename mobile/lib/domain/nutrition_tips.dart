/// Offline nutrition guidance that travels.
///
/// The advice below is clinically universal — breastfeeding frequency,
/// thickness of porridge, iron in pregnancy. The food examples are tokens
/// (`{staple}`, `{greens}`, `{protein}` …) rendered through the family's
/// [FoodPack], so the same tip reads naturally in Tamale, Lagos, Nairobi,
/// Kampala, Dar es Salaam or anywhere else.
///
/// Tips rotate daily (day-of-year) so the home-screen widget and Tips tab
/// always show something fresh without any connectivity.
library;

import 'food_packs.dart';

class NutritionTip {
  const NutritionTip(this.title, this.body);

  final String title;
  final String body;

  NutritionTip localized(FoodPack pack) =>
      NutritionTip(pack.render(title), pack.render(body));
}

class AgeBand {
  const AgeBand(this.label, this.minMonths, this.maxMonths, this.tips);

  final String label;
  final int minMonths;
  final int maxMonths; // inclusive
  final List<NutritionTip> tips;
}

const List<AgeBand> childFeedingBands = [
  AgeBand('0–5 months', 0, 5, [
    NutritionTip(
      'Breast milk only',
      'Give only breast milk — no water, porridge or herbal drinks. Breast milk has all the food and water your baby needs for the first 6 months.',
    ),
    NutritionTip(
      'Feed on demand',
      'Breastfeed at least 8–12 times a day, day and night, whenever baby shows hunger signs. Frequent feeding builds your milk supply.',
    ),
    NutritionTip(
      'Mother\'s meals matter',
      'Eat an extra small meal each day while breastfeeding — {staple} with {greens}, beans, eggs or {protein} help you make good milk. Drink plenty of clean water.',
    ),
    NutritionTip(
      'Empty one breast first',
      'Let baby finish one breast before switching — the last milk (hind milk) is the richest and helps baby grow.',
    ),
  ]),
  AgeBand('6–8 months', 6, 8, [
    NutritionTip(
      'Start soft porridge',
      'Begin thick {porridge} enriched with groundnut paste or soya powder, 2–3 times a day, while continuing to breastfeed.',
    ),
    NutritionTip(
      'Add an egg',
      'Mash a boiled egg into baby\'s porridge a few times each week — eggs are one of the best and cheapest growth foods.',
    ),
    NutritionTip(
      'Orange and green foods',
      'Add mashed orange-fleshed sweet potato, pawpaw or a spoon of pounded {greens} to porridge for strong eyes and blood.',
    ),
    NutritionTip(
      'Thick, not watery',
      'Porridge should stay on the spoon when tilted. Watery porridge fills the belly but does not feed the child.',
    ),
  ]),
  AgeBand('9–11 months', 9, 11, [
    NutritionTip(
      'Family foods, mashed',
      'Give mashed family foods — {staple} with soup, rice with beans, mashed yam or potato with {greens} stew — 3–4 times a day plus breast milk.',
    ),
    NutritionTip(
      'Add fish or meat',
      'Add pounded {protein}, or small pieces of meat to baby\'s food daily if you can — it builds blood and brain.',
    ),
    NutritionTip(
      'Finger foods',
      'Offer soft finger foods like {snack}, soft cooked vegetables or beans so baby learns to feed themselves.',
    ),
  ]),
  AgeBand('12–23 months', 12, 23, [
    NutritionTip(
      'Four meals a day',
      'Give 3 family meals plus 1–2 healthy snacks ({snack}, boiled egg, crushed groundnuts) every day, and continue breastfeeding to 2 years.',
    ),
    NutritionTip(
      'A rainbow on the plate',
      'Each day try to mix: a grain (rice, maize, millet), a protein (beans, {protein}), and a vegetable or fruit ({greens}, mango, pawpaw).',
    ),
    NutritionTip(
      'Iodized salt & clean water',
      'Cook with iodized salt and give only boiled or treated water. Wash hands with soap before every meal — clean food feeds, dirty food sickens.',
    ),
  ]),
  AgeBand('24–59 months', 24, 59, [
    NutritionTip(
      'Own bowl, full share',
      'Serve your child their own bowl so you can see how much they truly eat. A growing child needs 3 meals and 2 snacks daily.',
    ),
    NutritionTip(
      'Beans and groundnuts weekly',
      'Beans, groundnuts and soya are affordable proteins — aim for beans or groundnuts at least 4 times a week.',
    ),
    NutritionTip(
      'Watch the weighing',
      'Take your child for growth monitoring — if weight is not rising along the card\'s curve for 2 months, ask your community health nurse or clinic about it.',
    ),
  ]),
];

const List<NutritionTip> pregnancyTips = [
  NutritionTip(
    'Eat one extra meal',
    'Pregnant mothers need one extra small meal each day. Add beans, eggs, {protein} or a spoon of groundnut paste to your {staple} and soups.',
  ),
  NutritionTip(
    'Iron for strong blood',
    'Eat dark green leaves ({greens}) and take your iron-folate tablets daily — they prevent the weakness of anaemia common in pregnancy.',
  ),
  NutritionTip(
    'Sleep under a net',
    'Sleep under a treated mosquito net every night. Malaria in pregnancy is dangerous for you and the baby.',
  ),
  NutritionTip(
    'Small sips, many times',
    'If nausea makes eating hard, take small frequent meals and sip water or {porridge} through the day rather than big meals.',
  ),
  NutritionTip(
    'Keep every ANC visit',
    'Antenatal visits catch problems before they become emergencies. Your care calendar will remind you — try not to miss any.',
  ),
];

int _dayIndex(DateTime? today) =>
    (today ?? DateTime.now()).difference(DateTime(2026)).inDays;

NutritionTip _rotate(List<NutritionTip> tips, DateTime? today, FoodPack pack) {
  final tip = tips[_dayIndex(today) % tips.length];
  return tip.localized(pack);
}

NutritionTip dailyChildTip(
  int ageMonths, {
  DateTime? today,
  String? countryCode,
}) => _rotate(bandForAge(ageMonths).tips, today, foodPackFor(countryCode));

NutritionTip dailyPregnancyTip({DateTime? today, String? countryCode}) =>
    _rotate(pregnancyTips, today, foodPackFor(countryCode));

/// The full, already-localised advice list for a child's age band.
List<NutritionTip> tipsForBand(int ageMonths, {String? countryCode}) {
  final pack = foodPackFor(countryCode);
  return [for (final t in bandForAge(ageMonths).tips) t.localized(pack)];
}

/// The full, already-localised pregnancy advice list.
List<NutritionTip> pregnancyTipsFor({String? countryCode}) {
  final pack = foodPackFor(countryCode);
  return [for (final t in pregnancyTips) t.localized(pack)];
}

AgeBand bandForAge(int ageMonths) => childFeedingBands.firstWhere(
  (b) => ageMonths >= b.minMonths && ageMonths <= b.maxMonths,
  orElse: () => childFeedingBands.last,
);

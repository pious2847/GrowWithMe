/// Nana's Kitchen: seasonal, budget-aware diet guidance for pregnant women,
/// breastfeeding mothers and young children in every market GrowWithMe serves.
///
/// The clinical rules are universal; the pantry is not. Each country's
/// [FoodPack] supplies its own seasons, staple dishes and market foods, so the
/// offline library is just as useful in Tamale as in Nairobi, Lagos or a
/// country the app has never heard of. The LLM personalises from her pantry
/// when online; everything here works with no network at all.
library;

import 'food_packs.dart';

// ---- Seasons ----

/// Returns `'rainy'`, `'harvest'` or `'dry'` for the given country's
/// calendar. Ghana stays the default so existing saved plans keep their shape.
String currentSeason([DateTime? now, String? countryCode]) {
  final pack = foodPackFor(countryCode);
  return seasonKey(pack.seasonFor(now ?? DateTime.now()));
}

String seasonLabel(String season, {String? countryCode}) {
  final pack = foodPackFor(countryCode);
  final label = switch (seasonFrom(season)) {
    FoodSeason.rainy => 'Rainy season (fresh greens are plentiful)',
    FoodSeason.harvest => 'Harvest season (grains and roots are cheapest)',
    FoodSeason.dry => 'Dry season (dried leaves, stored grain and smoked fish)',
  };
  final note = pack.seasonNote;
  return note == null ? label : '$label · $note';
}

String seasonalFoodsHint(String season, {String? countryCode}) =>
    foodPackFor(countryCode).hintFor(seasonFrom(season));

// ---- Daily Plate: simplified dietary-diversity food groups ----

class FoodGroup {
  const FoodGroup(this.emoji, this.name, this.examples);

  final String emoji;
  final String name;
  final String examples;
}

const _groupMeta = <(String, String)>[
  ('🌾', 'Staples'),
  ('🫘', 'Beans & groundnuts'),
  ('🥬', 'Dark green leaves'),
  ('🥭', 'Yellow/orange foods'),
  ('🍊', 'Other fruits & veg'),
  ('🥚', 'Eggs'),
  ('🐟', 'Fish & meat'),
  ('🥛', 'Milk & dairy'),
];

/// The Eight-Group plate with examples from the family's own market.
List<FoodGroup> foodGroupsFor(String? countryCode) {
  final pack = foodPackFor(countryCode);
  return [
    for (var i = 0; i < _groupMeta.length; i++)
      FoodGroup(_groupMeta[i].$1, _groupMeta[i].$2, pack.groupExamples[i]),
  ];
}

/// Ghanaian plate — kept for older code paths and existing widgets.
const foodGroups = <FoodGroup>[
  FoodGroup('🌾', 'Staples', 'TZ, koko, rice, yam, kenkey'),
  FoodGroup('🫘', 'Beans & groundnuts', 'cowpea, tubaani, groundnut paste'),
  FoodGroup('🥬', 'Dark green leaves', 'ayoyo, kontomire, moringa'),
  FoodGroup('🥭', 'Yellow/orange foods', 'mango, pawpaw, orange sweet potato'),
  FoodGroup('🍊', 'Other fruits & veg', 'orange, tomato, garden eggs, okro'),
  FoodGroup('🥚', 'Eggs', 'boiled or in stew'),
  FoodGroup(
    '🐟',
    'Fish & meat',
    'smoked fish, fish powder, chicken, guinea fowl',
  ),
  FoodGroup('🥛', 'Milk & dairy', 'fresh milk, wagashi, yoghurt'),
];

/// Diversity score = number of groups eaten today. 5+ of 8 is a good day.
int diversityScore(List<int> groupsEaten) => groupsEaten.toSet().length;

/// Keywords span every market we serve, so a plate logged in Kano, Kisumu or
/// Kampala ticks the same groups as one logged in Tamale.
const _groupKeywords = <int, List<String>>{
  0: [
    'tz',
    'koko',
    'rice',
    'kenkey',
    'yam',
    'maize',
    'millet',
    'banku',
    'porridge',
    'bread',
    'ugali',
    'uji',
    'posho',
    'matoke',
    'cassava',
    'ndizi',
    'chapati',
    'garri',
    'tuwo',
    'pap',
    'sorghum',
    'sweet potato',
    'potato',
    'plantain',
    'fufu',
    'sadza',
    'nsima',
    'couscous',
    'oats',
    'millet',
    'teff',
    'quinoa',
    'noodles',
  ],
  1: [
    'bean',
    'cowpea',
    'tubaani',
    'groundnut',
    'soya',
    'lentil',
    'peas',
    'egusi',
    'moi moi',
    'chickpea',
  ],
  2: [
    'ayoyo',
    'kontomire',
    'moringa',
    'leaves',
    'alefu',
    'green',
    'ugu',
    'spinach',
    'sukuma',
    'managu',
    'terere',
    'nakati',
    'dodo',
    'bugga',
    'mchicha',
    'kisamvu',
    'kale',
    'amaranth',
    'zogale',
    'callaloo',
  ],
  3: [
    'mango',
    'pawpaw',
    'papaya',
    'carrot',
    'sweet potato',
    'pumpkin',
    'squash',
    'apricot',
    'peach',
  ],
  4: [
    'okro',
    'okra',
    'tomato',
    'garden egg',
    'orange',
    'banana',
    'fruit',
    'pepper',
    'avocado',
    'passion',
    'pineapple',
    'apple',
    'watermelon',
    'cucumber',
    'cabbage',
  ],
  5: ['egg'],
  6: [
    'fish',
    'meat',
    'chicken',
    'guinea fowl',
    'beef',
    'goat',
    'mutton',
    'liver',
    'omena',
    'mukene',
    'dagaa',
    'tilapia',
    'sardine',
    'pork',
    'turkey',
    'termite',
    'cricket',
  ],
  7: [
    'milk',
    'wagashi',
    'yoghurt',
    'yogurt',
    'mursik',
    'mtindi',
    'cheese',
    'wara',
  ],
};

/// When she approves "I made this", the meal's ingredients auto-tick the
/// matching Daily Plate groups — eating the plan IS the tracking.
List<int> inferGroups(String mealText) {
  final t = mealText.toLowerCase();
  return [
    for (final e in _groupKeywords.entries)
      if (e.value.any(t.contains)) e.key,
  ];
}

String scoreMessage(int score) {
  if (score >= 5) return 'A strong plate today — well done! 🎉';
  if (score >= 3) return 'Good start — try to add greens, egg or fish.';
  return 'The plate needs more variety. Even small additions help: a spoon of groundnut paste, a handful of leaves.';
}

// ---- Offline meal-plan library (used when the AI is unreachable) ----

class PlanMeal {
  const PlanMeal(
    this.time,
    this.name,
    this.ingredients,
    this.portion,
    this.prep,
  );

  final String time;
  final String name;
  final String ingredients;
  final String portion;
  final String prep;

  Map<String, dynamic> toJson() => {
    'time': time,
    'name': name,
    'ingredients': ingredients,
    'portion': portion,
    'prep': prep,
  };
}

Map<String, dynamic> _slot(String time, List<PlanMeal> options) => {
  'time': time,
  'options': options.map((m) => m.toJson()).toList(),
};

/// Two familiar, affordable dishes per meal slot, built from the country's
/// own staples. Never a single choice: a mother decides with her market.
List<PlanMeal> _morningMeals(FoodPack pack) {
  final nuts = pack.code == 'KE' || pack.code == 'TZ'
      ? 'groundnut paste'
      : 'groundnut or soya powder';
  return switch (pack.code) {
    'NG' => [
      PlanMeal(
        'Morning',
        'Pap with groundnut',
        'pap (ogi) + 2 spoons groundnut paste',
        '1 large bowl',
        'Cook pap smooth. Stir in groundnut paste while hot.',
      ),
      PlanMeal(
        'Morning',
        'Millet porridge with soya',
        'millet porridge + 2 spoons soya powder',
        '1 large bowl',
        'Cook millet soft with extra water. Stir the powder in well.',
      ),
    ],
    'KE' => [
      PlanMeal(
        'Morning',
        'Uji with groundnut',
        'millet uji + 2 spoons groundnut paste',
        '1 large mug',
        'Cook uji thick. Stir in groundnut paste before serving.',
      ),
      PlanMeal(
        'Morning',
        'Rice porridge with milk',
        'rice porridge + small milk',
        '1 large bowl',
        'Cook rice very soft. Add milk at the end.',
      ),
    ],
    'UG' => [
      PlanMeal(
        'Morning',
        'Posho porridge with groundnut',
        'posho porridge + groundnut paste',
        '1 large mug',
        'Whisk posho into boiling water so it stays smooth.',
      ),
      PlanMeal(
        'Morning',
        'Millet porridge with soya',
        'millet porridge + soya powder',
        '1 large mug',
        'Cook millet soft, then stir in soya off the heat.',
      ),
    ],
    'TZ' => [
      PlanMeal(
        'Morning',
        'Uji with groundnut',
        'millet uji + groundnut paste',
        '1 large mug',
        'Cook uji thick and stir in groundnut paste.',
      ),
      PlanMeal(
        'Morning',
        'Rice porridge with milk',
        'rice porridge + small milk',
        '1 large bowl',
        'Cook rice soft with extra water, then add milk.',
      ),
    ],
    'XX' => [
      PlanMeal(
        'Morning',
        'Fortified porridge',
        'fortified porridge + groundnut paste or milk',
        '1 large bowl',
        'Cook the porridge thick, then stir in the paste or milk.',
      ),
      PlanMeal(
        'Morning',
        'Grain porridge with soya',
        'maize, millet or rice porridge + soya powder',
        '1 large bowl',
        'Keep the porridge thick enough to stay on the spoon.',
      ),
    ],
    _ => [
      PlanMeal(
        'Morning',
        'Enriched koko',
        'millet or maize koko + 2 spoons $nuts',
        '1 large bowl',
        'Cook koko thick. Stir in groundnut paste. Add small sugar if you have.',
      ),
      PlanMeal(
        'Morning',
        'Rice porridge with soya',
        'rice porridge + 2 spoons soya or groundnut powder',
        '1 large bowl',
        'Cook rice soft with extra water. Stir the powder in well.',
      ),
    ],
  };
}

List<PlanMeal> _middayMeals(FoodPack pack, String greens, String soupFlavour) {
  return switch (pack.code) {
    'NG' => [
      PlanMeal(
        'Midday',
        'Tuwo with ugu soup',
        'tuwo + $greens soup with egusi and small dried fish',
        '2 wraps tuwo, 1 ladle soup',
        'Cook the soup thick with egusi. Serve tuwo on the side.',
      ),
      PlanMeal(
        'Midday',
        'Jollof rice and beans',
        'rice + cowpea beans + pepper sauce with small fish',
        '1 milk tin rice + half tin beans',
        'Cook rice and beans, then simmer in a light pepper sauce.',
      ),
    ],
    'KE' => [
      PlanMeal(
        'Midday',
        'Ugali with sukuma wiki',
        'ugali + $greens fried with onion and small oil',
        '1 piece ugali, 1 ladle greens',
        'Cook ugali firm. Fry the greens lightly — do not overcook.',
      ),
      PlanMeal(
        'Midday',
        'Rice and beans',
        'rice + beans + small avocado or tomato',
        '1 plate',
        'Boil beans soft, mix with rice and a little oil.',
      ),
    ],
    'UG' => [
      PlanMeal(
        'Midday',
        'Matoke with groundnut sauce',
        'matoke + groundnut sauce with $greens',
        '1 plate',
        'Steam matoke until soft. Pour groundnut sauce over it.',
      ),
      PlanMeal(
        'Midday',
        'Rice and beans',
        'rice + beans + small dried fish',
        '1 plate',
        'Cook beans soft and mix with rice and fish.',
      ),
    ],
    'TZ' => [
      PlanMeal(
        'Midday',
        'Ugali with mchicha',
        'ugali + $greens with onion and small oil',
        '1 piece ugali, 1 ladle greens',
        'Cook ugali firm. Wilt the greens in a little oil.',
      ),
      PlanMeal(
        'Midday',
        'Rice and beans',
        'rice + beans + small dagaa',
        '1 plate',
        'Boil beans soft, mix with rice and dried fish.',
      ),
    ],
    'XX' => [
      PlanMeal(
        'Midday',
        'Staple with bean stew',
        '${pack.staple} + bean stew with $greens',
        '1 plate',
        'Cook the staple soft. Simmer beans with tomato and greens.',
      ),
      PlanMeal(
        'Midday',
        'Rice and beans',
        'rice + beans + small dried fish or egg',
        '1 plate',
        'Cook beans soft, mix with rice and a little oil.',
      ),
    ],
    _ => [
      PlanMeal(
        'Midday',
        'TZ with green soup',
        'TZ + $greens soup with dawadawa and small dried fish',
        '2 ladles TZ, 1 ladle soup',
        'Pound leaves into the soup. Add dawadawa for taste and strength.',
      ),
      PlanMeal(
        'Midday',
        'Rice and beans',
        'rice + cowpea beans + $soupFlavour with small dried fish',
        '1 milk tin rice + half milk tin beans',
        'Cook rice and beans together. Fry pepper with the fish, serve on top.',
      ),
    ],
  };
}

List<PlanMeal> _eveningMeals(FoodPack pack, String greens) {
  return switch (pack.code) {
    'NG' => [
      PlanMeal(
        'Evening',
        'Moi moi with egg',
        'bean moi moi + one egg if you can',
        '2 wraps + 1 egg',
        'Steam the moi moi. Serve with fruit or vegetables.',
      ),
      PlanMeal(
        'Evening',
        'Yam with egusi stew',
        'boiled yam + egusi and $greens stew',
        '2 slices + 1 ladle stew',
        'Boil the yam. Cook egusi with leaves, oil and pepper.',
      ),
    ],
    'KE' => [
      PlanMeal(
        'Evening',
        'Githeri with egg',
        'maize and beans + one egg if you can',
        '1 large bowl',
        'Boil maize and beans soft. Add a boiled egg.',
      ),
      PlanMeal(
        'Evening',
        'Sweet potato with greens',
        'boiled sweet potato + $greens stew',
        '2 pieces + 1 ladle stew',
        'Boil the sweet potato. Wilt the greens with a little oil.',
      ),
    ],
    'UG' => [
      PlanMeal(
        'Evening',
        'Beans with egg',
        'beans, small oil, tomato; add an egg if you can',
        '1 large bowl',
        'Boil beans soft. Fry tomato in small oil and mix in.',
      ),
      PlanMeal(
        'Evening',
        'Cassava with greens',
        'boiled cassava + $greens in groundnut sauce',
        '2 pieces + 1 ladle',
        'Boil cassava. Cook greens in a thin groundnut sauce.',
      ),
    ],
    'TZ' => [
      PlanMeal(
        'Evening',
        'Beans with egg',
        'beans, small oil, tomato; add an egg if you can',
        '1 large bowl',
        'Boil beans soft. Fry tomato in small oil and mix in.',
      ),
      PlanMeal(
        'Evening',
        'Ndizi with greens',
        'boiled ndizi (plantain) + $greens stew',
        '2 pieces + 1 ladle',
        'Boil the plantain. Cook greens with oil and tomato.',
      ),
    ],
    'XX' => [
      PlanMeal(
        'Evening',
        'Beans with egg',
        'beans, small oil, tomato; add an egg if you can',
        '1 large bowl',
        'Boil beans soft. Fry tomato in small oil and mix in.',
      ),
      PlanMeal(
        'Evening',
        'Roots with green stew',
        'boiled root or potato + $greens stew',
        '2 pieces + 1 ladle stew',
        'Boil the root. Cook greens with oil, tomato and onion.',
      ),
    ],
    _ => [
      PlanMeal(
        'Evening',
        'Beans with egg',
        'cowpea beans, small oil, pepper; add an egg if you can',
        '1 milk tin of cooked beans',
        'Boil beans soft. Fry pepper in small oil, mix in.',
      ),
      PlanMeal(
        'Evening',
        'Yam with kontomire stew',
        'boiled yam or sweet potato + $greens stew',
        '2 slices + 1 ladle stew',
        'Boil the yam. Cook the leaves with oil, pepper and dawadawa.',
      ),
    ],
  };
}

Map<String, dynamic> offlinePlan(
  String audience,
  String season, {
  String? countryCode,
}) {
  final pack = foodPackFor(countryCode);
  final dry = season == 'dry';
  final greens = dry ? 'dried ${pack.greens}' : 'fresh ${pack.greens}';
  final soupFlavour = switch (pack.code) {
    'NG' => 'pepper sauce',
    'KE' || 'TZ' => 'tomato sauce',
    'UG' => 'groundnut sauce',
    _ => 'pepper sauce',
  };
  final slots = <Map<String, dynamic>>[
    _slot('Morning', _morningMeals(pack)),
    _slot('Midday', _middayMeals(pack, greens, soupFlavour)),
    _slot('Evening', _eveningMeals(pack, greens)),
    if (audience == 'pregnancy')
      _slot('Snack', [
        PlanMeal(
          'Snack',
          'Extra pregnancy meal',
          '${pack.snack} + a handful of groundnuts',
          '1 piece + 1 handful',
          'Pregnant mothers need one extra small meal every day.',
        ),
        PlanMeal(
          'Snack',
          'Egg and fruit',
          'one boiled egg + a slice of pawpaw, mango or banana',
          '1 egg + 1 slice',
          'A cheap, strong snack for you and the baby.',
        ),
      ]),
    if (audience == 'lactating')
      _slot('Snack', [
        PlanMeal(
          'Snack',
          'Breastfeeding booster',
          '${pack.porridge} + groundnuts; drink water each time baby feeds',
          '1 cup + 1 handful',
          'Making milk needs extra food and plenty of fluids all day.',
        ),
        PlanMeal(
          'Snack',
          'Fruit and groundnut',
          '${pack.snack} + handful of roasted groundnuts',
          '1 fruit + 1 handful',
          'Quick strength between feeds.',
        ),
      ]),
    if (audience == 'child')
      _slot('Snack', [
        PlanMeal(
          'Snack',
          'Child\'s enriched porridge',
          'thick ${pack.porridge} + groundnut paste + mashed fruit',
          '1 small bowl',
          'Porridge must stay on the spoon when tilted — thick feeds, watery fills.',
        ),
        PlanMeal(
          'Snack',
          'Mashed egg and root',
          'boiled egg mashed with sweet potato or cassava',
          '1 small bowl',
          'Mash soft. Feed with a clean spoon, slowly.',
        ),
      ]),
  ];
  return {
    'summary': audience == 'pregnancy'
        ? 'My daughter, choose one dish for each meal. Both choices feed you and the baby using ${seasonLabel(season, countryCode: pack.code).toLowerCase()} foods. Remember your iron tablets.'
        : audience == 'lactating'
        ? 'Choose one dish for each meal — every choice keeps your strength and your milk flowing.'
        : 'Choose one dish for each meal — every choice grows a strong child.',
    'meals': slots,
    'tips': [
      'Iodized salt only, and boiled or treated water.',
      'Wash hands with soap before cooking and eating.',
      if (dry)
        'Dried leaves and fish powder keep their strength — use them freely in soups.',
    ],
  };
}

/// Normalizes any saved plan (old single-meal shape or new options shape)
/// into slots of {time, options: [...]}.
List<Map<String, dynamic>> planSlots(Map<String, dynamic> plan) {
  final slots = <Map<String, dynamic>>[];
  for (final raw in (plan['meals'] as List? ?? [])) {
    final m = raw as Map<String, dynamic>;
    final options = m['options'] is List
        ? (m['options'] as List).cast<Map<String, dynamic>>()
        : [m]; // legacy: the slot itself was the meal
    final valid = options.where((o) => o['name'] != null).toList();
    if (valid.isNotEmpty) {
      slots.add({'time': m['time'] ?? 'Meal', 'options': valid});
    }
  }
  return slots;
}

/// Nana's Kitchen: seasonal, budget-aware diet guidance for Northern Ghana —
/// pregnant women, breastfeeding mothers and young children. The offline
/// library below always works; the LLM personalizes from her pantry online.
library;

// ---- Food seasons (Northern Ghana) ----

String currentSeason([DateTime? now]) {
  final month = (now ?? DateTime.now()).month;
  if (month >= 5 && month <= 9) return 'rainy';
  if (month >= 10 && month <= 12) return 'harvest';
  return 'dry';
}

String seasonLabel(String season) => switch (season) {
      'rainy' => 'Rainy season (fresh leaves & maize)',
      'harvest' => 'Harvest season (grains & yam are cheap)',
      _ => 'Dry season (dried leaves, smoked fish, stored grain)',
    };

String seasonalFoodsHint(String season) => switch (season) {
      'rainy' =>
        'fresh ayoyo, kontomire, okro, fresh maize, groundnuts, mango (early)',
      'harvest' =>
        'new yam, millet, maize, rice, cowpea/beans, groundnuts, sweet potato',
      _ =>
        'dried ayoyo & okro, dawadawa, smoked/dried fish, stored millet & maize, cowpea, shea butter',
    };

// ---- Daily Plate: simplified dietary-diversity food groups ----

class FoodGroup {
  const FoodGroup(this.emoji, this.name, this.examples);

  final String emoji;
  final String name;
  final String examples;
}

const foodGroups = <FoodGroup>[
  FoodGroup('🌾', 'Staples', 'TZ, koko, rice, yam, kenkey'),
  FoodGroup('🫘', 'Beans & groundnuts', 'cowpea, tubaani, groundnut paste'),
  FoodGroup('🥬', 'Dark green leaves', 'ayoyo, kontomire, moringa'),
  FoodGroup('🥭', 'Yellow/orange foods', 'mango, pawpaw, orange sweet potato'),
  FoodGroup('🍊', 'Other fruits & veg', 'orange, tomato, garden eggs, okro'),
  FoodGroup('🥚', 'Eggs', 'boiled or in stew'),
  FoodGroup('🐟', 'Fish & meat', 'smoked fish, fish powder, chicken, guinea fowl'),
  FoodGroup('🥛', 'Milk & dairy', 'fresh milk, wagashi, yoghurt'),
];

/// Diversity score = number of groups eaten today. 5+ of 8 is a good day.
int diversityScore(List<int> groupsEaten) => groupsEaten.toSet().length;

const _groupKeywords = <int, List<String>>{
  0: ['tz', 'koko', 'rice', 'kenkey', 'yam', 'maize', 'millet', 'banku', 'porridge', 'bread'],
  1: ['bean', 'cowpea', 'tubaani', 'groundnut', 'soya'],
  2: ['ayoyo', 'kontomire', 'moringa', 'leaves', 'alefu', 'green'],
  3: ['mango', 'pawpaw', 'papaya', 'carrot', 'sweet potato'],
  4: ['okro', 'okra', 'tomato', 'garden egg', 'orange', 'banana', 'fruit', 'pepper'],
  5: ['egg'],
  6: ['fish', 'meat', 'chicken', 'guinea fowl', 'beef'],
  7: ['milk', 'wagashi', 'yoghurt', 'yogurt'],
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
  const PlanMeal(this.time, this.name, this.ingredients, this.portion, this.prep);

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

Map<String, dynamic> offlinePlan(String audience, String season) {
  final greens = season == 'dry' ? 'dried ayoyo' : 'fresh ayoyo or kontomire';
  final slots = <Map<String, dynamic>>[
    _slot('Morning', [
      PlanMeal('Morning', 'Enriched koko',
          'millet or maize koko + 2 spoons groundnut paste', '1 large bowl',
          'Cook koko thick. Stir in groundnut paste. Add small sugar if you have.'),
      PlanMeal('Morning', 'Rice porridge with soya',
          'rice porridge + 2 spoons soya or groundnut powder', '1 large bowl',
          'Cook rice soft with extra water. Stir the powder in well.'),
    ]),
    _slot('Midday', [
      PlanMeal('Midday', 'TZ with green soup',
          'TZ + $greens soup with dawadawa and small dried fish',
          '2 ladles TZ, 1 ladle soup',
          'Pound leaves into the soup. Add dawadawa for taste and strength.'),
      PlanMeal('Midday', 'Rice and beans',
          'rice + cowpea beans + pepper sauce with small dried fish',
          '1 milk tin rice + half milk tin beans',
          'Cook rice and beans together. Fry pepper with the fish, serve on top.'),
    ]),
    _slot('Evening', [
      PlanMeal('Evening', 'Beans with egg',
          'cowpea beans, small oil, pepper; add an egg if you can',
          '1 milk tin of cooked beans',
          'Boil beans soft. Fry pepper in small oil, mix in.'),
      PlanMeal('Evening', 'Yam with kontomire stew',
          'boiled yam or sweet potato + $greens stew', '2 slices + 1 ladle stew',
          'Boil the yam. Cook the leaves with oil, pepper and dawadawa.'),
    ]),
    if (audience == 'pregnancy')
      _slot('Snack', [
        PlanMeal('Snack', 'Extra pregnancy meal',
            'banana or boiled sweet potato + handful of groundnuts',
            '1 piece + 1 handful',
            'Pregnant mothers need one extra small meal every day.'),
        PlanMeal('Snack', 'Egg and fruit',
            'one boiled egg + a slice of pawpaw or mango', '1 egg + 1 slice',
            'A cheap, strong snack for you and the baby.'),
      ]),
    if (audience == 'lactating')
      _slot('Snack', [
        PlanMeal('Snack', 'Breastfeeding booster',
            'koko or millet drink + groundnuts; drink water each time baby feeds',
            '1 cup + 1 handful',
            'Making milk needs extra food and plenty of fluids all day.'),
        PlanMeal('Snack', 'Fruit and groundnut',
            'banana or mango + handful of roasted groundnuts', '1 fruit + 1 handful',
            'Quick strength between feeds.'),
      ]),
    if (audience == 'child')
      _slot('Snack', [
        PlanMeal('Snack', 'Child\'s enriched porridge',
            'thick porridge + groundnut paste + mashed pawpaw', '1 small bowl',
            'Porridge must stay on the spoon when tilted — thick feeds, watery fills.'),
        PlanMeal('Snack', 'Mashed egg and potato',
            'boiled egg mashed with sweet potato', '1 small bowl',
            'Mash soft. Feed with a clean spoon, slowly.'),
      ]),
  ];
  return {
    'summary': audience == 'pregnancy'
        ? 'My daughter, choose one dish for each meal. Both choices feed you and the baby using ${seasonLabel(season).toLowerCase()} foods. Remember your iron tablets.'
        : audience == 'lactating'
            ? 'Choose one dish for each meal — every choice keeps your strength and your milk flowing.'
            : 'Choose one dish for each meal — every choice grows a strong child.',
    'meals': slots,
    'tips': [
      'Iodized salt only, and boiled or treated water.',
      'Wash hands with soap before cooking and eating.',
      if (season == 'dry')
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

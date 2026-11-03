/// Local food packs.
///
/// GrowWithMe started with a Ghanaian pantry. To travel — nationwide and
/// beyond — the offline nutrition library is driven by a [FoodPack] per
/// country instead of hard-coded Ghanaian foods. Every pack keeps the same
/// eight dietary-diversity groups and the same clinical advice; only the
/// examples, seasons and dish names change. Unknown countries fall back to a
/// neutral global pack so the app is never wrong, only less specific.
library;

/// Which season is happening now, expressed in the three buckets the meal
/// library understands. Equatorial East Africa rains twice a year, so packs
/// declare their own month lists rather than assuming a West-African calendar.
enum FoodSeason { rainy, harvest, dry }

FoodSeason seasonFrom(String value) => switch (value) {
  'rainy' => FoodSeason.rainy,
  'harvest' => FoodSeason.harvest,
  _ => FoodSeason.dry,
};

String seasonKey(FoodSeason season) => switch (season) {
  FoodSeason.rainy => 'rainy',
  FoodSeason.harvest => 'harvest',
  FoodSeason.dry => 'dry',
};

class FoodPack {
  const FoodPack({
    required this.code,
    required this.label,
    required this.rainyMonths,
    required this.harvestMonths,
    required this.seasonHints,
    required this.groupExamples,
    required this.porridge,
    required this.staple,
    required this.greens,
    required this.protein,
    required this.dairy,
    required this.snack,
    this.seasonNote,
  });

  final String code;

  /// Human label used in copy, e.g. "Ghanaian" or "East African".
  final String label;

  /// Months (1–12) when fresh produce is plentiful.
  final List<int> rainyMonths;

  /// Months when grains and roots are cheapest.
  final List<int> harvestMonths;

  /// One line per season: what is cheap and fresh in local markets.
  final Map<FoodSeason, String> seasonHints;

  /// Examples for the eight Daily Plate groups, in the canonical order:
  /// staples, beans & groundnuts, dark green leaves, yellow/orange foods,
  /// other fruits & vegetables, eggs, fish & meat, milk & dairy.
  final List<String> groupExamples;

  /// Everyday names used to localise generic advice.
  final String porridge;
  final String staple;
  final String greens;
  final String protein;
  final String dairy;
  final String snack;

  /// Optional caveat, e.g. hemisphere differences for the global pack.
  final String? seasonNote;

  FoodSeason seasonFor(DateTime now) {
    if (rainyMonths.contains(now.month)) return FoodSeason.rainy;
    if (harvestMonths.contains(now.month)) return FoodSeason.harvest;
    return FoodSeason.dry;
  }

  String hintFor(FoodSeason season) =>
      seasonHints[season] ?? seasonHints[FoodSeason.dry]!;

  /// Replaces `{porridge}`, `{staple}`, `{greens}`, `{protein}`, `{dairy}` and
  /// `{snack}` in the shared tip library.
  String render(String text) => text
      .replaceAll('{porridge}', porridge)
      .replaceAll('{staple}', staple)
      .replaceAll('{greens}', greens)
      .replaceAll('{protein}', protein)
      .replaceAll('{dairy}', dairy)
      .replaceAll('{snack}', snack);
}

const _ghana = FoodPack(
  code: 'GH',
  label: 'Ghanaian',
  rainyMonths: [5, 6, 7, 8, 9],
  harvestMonths: [10, 11, 12],
  seasonHints: {
    FoodSeason.rainy:
        'fresh ayoyo, kontomire, okro, fresh maize, groundnuts, early mango',
    FoodSeason.harvest:
        'new yam, millet, maize, rice, cowpea, groundnuts, sweet potato',
    FoodSeason.dry:
        'dried ayoyo & okro, dawadawa, smoked fish, stored millet & maize, cowpea, shea butter',
  },
  groupExamples: [
    'TZ, koko, rice, yam, kenkey',
    'cowpea, tubaani, groundnut paste',
    'ayoyo, kontomire, moringa',
    'mango, pawpaw, orange sweet potato',
    'orange, tomato, garden eggs, okro',
    'boiled or in stew',
    'smoked fish, fish powder, chicken, guinea fowl',
    'fresh milk, wagashi, yoghurt',
  ],
  porridge: 'millet or maize koko',
  staple: 'TZ',
  greens: 'ayoyo or kontomire',
  protein: 'smoked fish or groundnut paste',
  dairy: 'milk or wagashi',
  snack: 'banana or boiled sweet potato',
);

const _nigeria = FoodPack(
  code: 'NG',
  label: 'Nigerian',
  rainyMonths: [4, 5, 6, 7, 8, 9],
  harvestMonths: [10, 11, 12],
  seasonHints: {
    FoodSeason.rainy:
        'fresh ugu, spinach, okro, fresh maize, groundnuts, pawpaw',
    FoodSeason.harvest:
        'yam, millet, sorghum, rice, cowpea, groundnut, sweet potato',
    FoodSeason.dry:
        'dried ugu, egusi, smoked fish, stored millet & guinea corn, cowpea',
  },
  groupExamples: [
    'tuwo, pap, rice, yam, garri',
    'beans, moi moi, groundnut',
    'ugu, spinach, zogale (moringa)',
    'mango, pawpaw, orange sweet potato',
    'orange, tomato, garden egg, okro',
    'boiled or in stew',
    'smoked fish, catfish, chicken, beef',
    'fresh milk, wara, yoghurt',
  ],
  porridge: 'pap (ogi)',
  staple: 'tuwo or rice',
  greens: 'ugu or spinach',
  protein: 'fish, egusi or groundnuts',
  dairy: 'milk or wara',
  snack: 'banana or roasted groundnuts',
);

const _kenya = FoodPack(
  code: 'KE',
  label: 'Kenyan',
  rainyMonths: [3, 4, 5, 10, 11, 12],
  harvestMonths: [6, 7, 8, 9],
  seasonHints: {
    FoodSeason.rainy:
        'sukuma wiki, managu, terere, fresh maize, beans, avocado',
    FoodSeason.harvest: 'maize, beans, millet, sorghum, sweet potato, banana',
    FoodSeason.dry:
        'kale, omena (dried fish), stored maize & beans, millet, pumpkin',
  },
  groupExamples: [
    'ugali, uji, rice, chapati, githeri',
    'beans, githeri, groundnuts',
    'sukuma wiki, managu, terere',
    'mango, pawpaw, orange sweet potato',
    'avocado, tomato, carrot, banana',
    'boiled or in stew',
    'omena, tilapia, beef, chicken',
    'milk, mursik, yoghurt',
  ],
  porridge: 'uji wa wimbi',
  staple: 'ugali',
  greens: 'sukuma wiki or managu',
  protein: 'omena, eggs or beans',
  dairy: 'milk or mursik',
  snack: 'banana or boiled sweet potato',
);

const _uganda = FoodPack(
  code: 'UG',
  label: 'Ugandan',
  rainyMonths: [3, 4, 5, 9, 10, 11],
  harvestMonths: [6, 7, 8, 12],
  seasonHints: {
    FoodSeason.rainy: 'nakati, dodo, bugga, fresh maize, beans, mango',
    FoodSeason.harvest:
        'matoke, maize, beans, millet, cassava, sweet potato, groundnuts',
    FoodSeason.dry:
        'dried nakati, mukene (silver fish), stored maize & beans, groundnuts',
  },
  groupExamples: [
    'matoke, posho, rice, cassava, millet',
    'beans, groundnuts, soya',
    'nakati, dodo, bugga',
    'mango, pawpaw, orange sweet potato',
    'tomato, avocado, passion fruit, banana',
    'boiled or in stew',
    'mukene, tilapia, beef, chicken',
    'milk, yoghurt',
  ],
  porridge: 'posho or millet porridge',
  staple: 'matoke or posho',
  greens: 'nakati or dodo',
  protein: 'mukene, beans or groundnuts',
  dairy: 'milk or yoghurt',
  snack: 'banana or boiled cassava',
);

const _tanzania = FoodPack(
  code: 'TZ',
  label: 'Tanzanian',
  rainyMonths: [3, 4, 5, 11, 12],
  harvestMonths: [6, 7, 8, 9, 10],
  seasonHints: {
    FoodSeason.rainy: 'mchicha, kisamvu, okra, fresh maize, beans, avocado',
    FoodSeason.harvest:
        'maize, rice, beans, cassava, sweet potato, banana, groundnuts',
    FoodSeason.dry:
        'dried greens, dagaa, stored maize & beans, cassava flour, groundnuts',
  },
  groupExamples: [
    'ugali, rice, ndizi, cassava, millet',
    'beans, groundnuts, soya',
    'mchicha, kisamvu, moringa',
    'mango, pawpaw, orange sweet potato',
    'tomato, avocado, orange, banana',
    'boiled or in stew',
    'dagaa, tilapia, beef, chicken',
    'milk, mtindi, yoghurt',
  ],
  porridge: 'uji',
  staple: 'ugali',
  greens: 'mchicha or kisamvu',
  protein: 'dagaa, beans or groundnuts',
  dairy: 'milk or mtindi',
  snack: 'banana or boiled sweet potato',
);

/// Neutral fallback: clinically correct anywhere, deliberately generic.
const _global = FoodPack(
  code: 'XX',
  label: 'local',
  rainyMonths: [5, 6, 7, 8],
  harvestMonths: [9, 10, 11],
  seasonHints: {
    FoodSeason.rainy:
        'fresh local vegetables and fruit, beans, eggs, small dried fish',
    FoodSeason.harvest:
        'whole grains, roots and tubers, beans, groundnuts, seasonal fruit',
    FoodSeason.dry:
        'dried vegetables, stored grains, tinned or dried fish, beans, nuts',
  },
  groupExamples: [
    'rice, maize, wheat, millet, potatoes, yam',
    'beans, lentils, groundnuts, peas',
    'spinach, kale, amaranth leaves, moringa',
    'mango, pawpaw, carrot, orange sweet potato',
    'tomato, orange, banana, avocado',
    'boiled or in stew',
    'small dried fish, chicken, beef, liver',
    'milk, yoghurt, cheese',
  ],
  porridge: 'fortified porridge',
  staple: 'your local staple',
  greens: 'dark green leaves',
  protein: 'beans, eggs or small dried fish',
  dairy: 'milk or yoghurt',
  snack: 'fruit or a boiled egg',
  seasonNote:
      'Seasons differ between the northern and southern hemispheres — '
      'choose what is fresh and affordable in your market.',
);

const _packs = <String, FoodPack>{
  'GH': _ghana,
  'NG': _nigeria,
  'KE': _kenya,
  'UG': _uganda,
  'TZ': _tanzania,
  'XX': _global,
};

/// The pack for a country code, falling back to the global pack.
FoodPack foodPackFor(String? countryCode) =>
    _packs[(countryCode ?? 'GH').toUpperCase()] ?? _global;

/// All packs, for tests and settings previews.
List<FoodPack> get allFoodPacks => _packs.values.toList(growable: false);

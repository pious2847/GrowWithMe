/// Daily motivation for caregivers — one warm line a day, rotating. Shown on
/// the home-screen widget (and anywhere else a little encouragement fits).
library;

const motivationLines = [
  'You are doing well, mama. Small steps every day grow strong children. 🌱',
  'A fed child, a rested mother — that is already a victory today. 💚',
  'Every clinic visit you keep is a gift to your baby\'s future. 🎁',
  'Strong mothers build strong villages. You are one of them. 💪',
  'Breast milk, clean water, warm arms — you have what matters most. 🤱',
  'Asking for help is strength, not weakness. Nana is always here. 🧓🏾',
  'Your care today becomes your child\'s health tomorrow. 🌟',
  'One extra spoon of groundnut paste is one step to a stronger child. 🥜',
  'Rest when baby rests — caring for yourself is caring for them. 😴',
  'You kept going yesterday. You will keep going today. 🌅',
  'A mother\'s love plus a care calendar — nothing stronger. ❤️',
  'Little by little, the bird builds its nest. Well done, mama. 🐦',
];

String dailyMotivation([DateTime? now]) {
  final day = (now ?? DateTime.now()).difference(DateTime(2026)).inDays;
  return motivationLines[day % motivationLines.length];
}

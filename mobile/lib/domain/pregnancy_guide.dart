/// Week-aware pregnancy guidance for the home card: local baby-size
/// analogies, and trimester do's & don'ts. Fully offline content.
library;

class WeekGuide {
  const WeekGuide(this.sizeAnalogy, this.note);

  final String sizeAnalogy;
  final String note;
}

String babySize(int week) {
  if (week <= 8) return 'a groundnut 🥜';
  if (week <= 12) return 'a lime 🍈';
  if (week <= 16) return 'an orange 🍊';
  if (week <= 20) return 'a mango 🥭';
  if (week <= 24) return 'a corn cob 🌽';
  if (week <= 28) return 'a pawpaw 🍐';
  if (week <= 32) return 'a coconut 🥥';
  if (week <= 36) return 'a small watermelon 🍉';
  return 'ready to meet you 👶';
}

class DoDont {
  const DoDont(this.dos, this.donts);

  final List<String> dos;
  final List<String> donts;
}

DoDont guidanceForWeek(int week) {
  if (week <= 13) {
    return const DoDont([
      'Start ANC visits early — first visit before week 12',
      'Take folic acid / iron tablets every day',
      'Eat small frequent meals if nausea comes',
      'Sleep under a treated mosquito net',
    ], [
      'No alcohol, smoking or herbal concoctions',
      'Do not take any medicine without asking the nurse',
      'Avoid heavy lifting and long tiring journeys',
    ]);
  }
  if (week <= 27) {
    return const DoDont([
      'Keep every ANC visit — ask about your scan',
      'Eat iron-rich foods: ayoyo, moringa, beans, smoked fish',
      'Feel for baby movements every day from ~week 20',
      'Rest with your feet up when swelling starts',
    ], [
      'Do not skip meals — you are feeding two',
      'Avoid lying flat on your back for long',
      'No alcohol, smoking or unprescribed medicine',
    ]);
  }
  return const DoDont([
    'Plan transport to the facility NOW, before labour',
    'Pack a delivery kit: cloths, pads, baby clothes',
    'Count baby movements daily — 10+ kicks a day is good',
    'Know the danger signs: bleeding, fits, severe headache',
  ], [
    'Do not travel far from your facility',
    'Never ignore reduced baby movement — go the same day',
    'Do not plan to deliver at home without a skilled attendant',
  ]);
}

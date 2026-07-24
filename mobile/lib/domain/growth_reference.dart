/// Simplified WHO 2006 weight-for-age reference (kg) for growth screening,
/// with linear interpolation between anchor months. Values approximate the
/// WHO Child Growth Standards median, -2SD and -3SD curves.
///
/// SCREENING ONLY — a flag here means "go to the clinic for assessment",
/// never a diagnosis. Thresholds err toward escalation, matching the app's
/// safety posture.
library;

class GrowthPoint {
  const GrowthPoint(this.month, this.median, this.minus2sd, this.minus3sd);

  final int month;
  final double median;
  final double minus2sd;
  final double minus3sd;
}

const _boys = <GrowthPoint>[
  GrowthPoint(0, 3.3, 2.5, 2.1),
  GrowthPoint(3, 6.4, 5.0, 4.4),
  GrowthPoint(6, 7.9, 6.4, 5.7),
  GrowthPoint(9, 8.9, 7.1, 6.4),
  GrowthPoint(12, 9.6, 7.7, 6.9),
  GrowthPoint(18, 10.9, 8.8, 7.7),
  GrowthPoint(24, 12.2, 9.7, 8.6),
  GrowthPoint(36, 14.3, 11.3, 10.0),
  GrowthPoint(48, 16.3, 12.7, 11.1),
  GrowthPoint(60, 18.3, 14.1, 12.4),
];

const _girls = <GrowthPoint>[
  GrowthPoint(0, 3.2, 2.4, 2.0),
  GrowthPoint(3, 5.8, 4.5, 4.0),
  GrowthPoint(6, 7.3, 5.7, 5.1),
  GrowthPoint(9, 8.2, 6.5, 5.8),
  GrowthPoint(12, 8.9, 7.0, 6.3),
  GrowthPoint(18, 10.2, 8.1, 7.2),
  GrowthPoint(24, 11.5, 9.0, 8.1),
  GrowthPoint(36, 13.9, 10.8, 9.6),
  GrowthPoint(48, 16.1, 12.3, 10.9),
  GrowthPoint(60, 18.2, 13.7, 12.1),
];

List<GrowthPoint> _table(String? sex) => sex == 'female' ? _girls : _boys;

double _interp(double ageMonths, List<GrowthPoint> table,
    double Function(GrowthPoint) pick) {
  if (ageMonths <= table.first.month) return pick(table.first);
  if (ageMonths >= table.last.month) return pick(table.last);
  for (var i = 0; i < table.length - 1; i++) {
    final a = table[i];
    final b = table[i + 1];
    if (ageMonths >= a.month && ageMonths <= b.month) {
      final t = (ageMonths - a.month) / (b.month - a.month);
      return pick(a) + (pick(b) - pick(a)) * t;
    }
  }
  return pick(table.last);
}

double medianWeight(double ageMonths, String? sex) =>
    _interp(ageMonths, _table(sex), (p) => p.median);
double minus2sdWeight(double ageMonths, String? sex) =>
    _interp(ageMonths, _table(sex), (p) => p.minus2sd);
double minus3sdWeight(double ageMonths, String? sex) =>
    _interp(ageMonths, _table(sex), (p) => p.minus3sd);

enum GrowthStatus { healthy, underweight, severelyUnderweight }

class GrowthAssessment {
  const GrowthAssessment(this.status, this.message);

  final GrowthStatus status;
  final String message;
}

GrowthAssessment assessWeight(double weightKg, double ageMonths, String? sex) {
  if (weightKg < minus3sdWeight(ageMonths, sex)) {
    return const GrowthAssessment(
      GrowthStatus.severelyUnderweight,
      'Weight is severely low for age. Please go to the nearest health facility '
      'as soon as possible for a full nutrition assessment.',
    );
  }
  if (weightKg < minus2sdWeight(ageMonths, sex)) {
    return const GrowthAssessment(
      GrowthStatus.underweight,
      'Weight is low for age. Visit your CHPS compound or clinic within a few '
      'days, and check the feeding tips for this age.',
    );
  }
  return const GrowthAssessment(
    GrowthStatus.healthy,
    'Weight is in the healthy range for age. Keep feeding well and continue '
    'monthly weighing.',
  );
}

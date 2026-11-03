import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/domain/diet_guide.dart';
import 'package:grow_with_me/domain/food_packs.dart';
import 'package:grow_with_me/domain/nutrition_tips.dart';

void main() {
  group('food packs', () {
    test('every pack fills all eight groups and three seasons', () {
      for (final pack in allFoodPacks) {
        expect(pack.groupExamples.length, 8, reason: pack.code);
        expect(pack.seasonHints.length, 3, reason: pack.code);
        expect(pack.porridge, isNotEmpty);
        expect(
          pack.render('{staple} + {greens}'),
          isNot(contains('{')),
          reason: pack.code,
        );
      }
    });

    test('unknown countries fall back to the global pack', () {
      expect(foodPackFor('FR').code, 'XX');
      expect(foodPackFor(null).code, 'GH');
      expect(foodPackFor('ke').code, 'KE');
    });
  });

  group('seasons', () {
    test('Ghana keeps its single rainy season', () {
      expect(currentSeason(DateTime(2026, 7, 1)), 'rainy');
      expect(currentSeason(DateTime(2026, 11, 1)), 'harvest');
      expect(currentSeason(DateTime(2026, 2, 1)), 'dry');
    });

    test('Kenya follows its two rainy seasons', () {
      expect(currentSeason(DateTime(2026, 4, 1), 'KE'), 'rainy');
      expect(currentSeason(DateTime(2026, 7, 1), 'KE'), 'harvest');
      expect(currentSeason(DateTime(2026, 1, 1), 'KE'), 'dry');
      expect(currentSeason(DateTime(2026, 12, 1), 'KE'), 'rainy');
    });

    test('seasonal hints use market foods from the selected country', () {
      expect(seasonalFoodsHint('rainy', countryCode: 'GH'), contains('ayoyo'));
      expect(
        seasonalFoodsHint('rainy', countryCode: 'KE'),
        contains('sukuma wiki'),
      );
      expect(
        seasonalFoodsHint('rainy', countryCode: 'XX'),
        contains('local vegetables'),
      );
    });
  });

  group('offline meal library', () {
    test('Ghana remains the default and offers two choices per slot', () {
      final plan = offlinePlan('pregnancy', 'dry');
      final slots = planSlots(plan);
      expect(slots.length, greaterThanOrEqualTo(4));
      for (final slot in slots) {
        expect(
          (slot['options'] as List).length,
          2,
          reason: '${slot['time']} should offer a choice',
        );
      }
      expect(plan['summary'], isNotEmpty);
    });

    test('Kenya gets ugali and sukuma, not Ghanaian dishes', () {
      final plan = offlinePlan('child', 'rainy', countryCode: 'KE');
      final text = planSlots(plan)
          .expand((s) => s['options'] as List)
          .map((m) => '${m['name']} ${m['ingredients']}')
          .join(' ')
          .toLowerCase();
      expect(text, contains('ugali'));
      expect(text, contains('sukuma'));
      expect(text, isNot(contains('kontomire')));
      expect(text, isNot(contains('koko')));
    });

    test('Nigeria and the global pack localise their own way', () {
      final ng = offlinePlan('lactating', 'harvest', countryCode: 'NG');
      final ngText = planSlots(ng)
          .expand((s) => s['options'] as List)
          .map((m) => '${m['name']} ${m['ingredients']}')
          .join(' ')
          .toLowerCase();
      expect(ngText, contains('tuwo'));
      expect(ngText, contains('moi moi'));

      final global = offlinePlan('pregnancy', 'dry', countryCode: 'FR');
      expect(global['summary'], contains('dry season'));
      final globalText = planSlots(global)
          .expand((s) => s['options'] as List)
          .map((m) => '${m['name']} ${m['ingredients']}')
          .join(' ')
          .toLowerCase();
      expect(globalText, contains('your local staple'));
      expect(globalText, isNot(contains('ayoyo')));
    });
  });

  group('daily plate', () {
    test('food group examples follow the country', () {
      expect(foodGroupsFor('KE').first.examples, contains('ugali'));
      expect(foodGroupsFor('XX').first.examples, contains('potatoes'));
      expect(foodGroupsFor('GH').first.examples, contains('kenkey'));
    });

    test('keywords recognise East and West African foods', () {
      expect(inferGroups('ugali and sukuma wiki'), containsAll(<int>[0, 2]));
      expect(
        inferGroups('matoke with groundnut sauce'),
        containsAll(<int>[0, 1]),
      );
      expect(inferGroups('omena and ugali'), containsAll(<int>[0, 6]));
      expect(inferGroups('tuwo with egusi'), containsAll(<int>[0, 1]));
    });
  });

  group('feeding tips', () {
    test('tips render without leaving placeholders for any country', () {
      for (final code in ['GH', 'NG', 'KE', 'UG', 'TZ', 'XX']) {
        final child = dailyChildTip(9, countryCode: code);
        final mother = dailyPregnancyTip(countryCode: code);
        expect(child.body, isNot(contains('{')), reason: code);
        expect(mother.body, isNot(contains('{')), reason: code);
        for (final tip in tipsForBand(9, countryCode: code)) {
          expect(tip.body, isNot(contains('{')), reason: code);
        }
        for (final tip in pregnancyTipsFor(countryCode: code)) {
          expect(tip.body, isNot(contains('{')), reason: code);
        }
      }
    });

    test('the same advice names local foods', () {
      expect(dailyChildTip(7, countryCode: 'GH').body, isNotEmpty);
      final kenyan = tipsForBand(
        7,
        countryCode: 'KE',
      ).map((t) => t.body).join(' ').toLowerCase();
      expect(kenyan, contains('uji'));
    });
  });
}

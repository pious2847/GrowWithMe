import 'package:flutter_test/flutter_test.dart';

import 'package:grow_with_me_responder/core/pending_actions.dart';
import 'package:grow_with_me_responder/core/triage.dart';

Map<String, dynamic> alert({
  String? status = 'pending',
  String? summary,
  String? createdAt,
}) =>
    {
      'status': status,
      'summary': summary,
      'createdAt': createdAt,
      'location': {
        'coordinates': [0.0, 5.65],
      },
    };

void main() {
  group('danger signs', () {
    test('reads signs from the alert summary the backend builds', () {
      final signs = dangerSignsOf(alert(
        summary: 'URGENT: Ama needs help for bleeding. '
            'Danger signs: bleeding, fever.',
      ));
      expect(signs, ['bleeding', 'fever']);
    });

    test('treats "not specified" as no signs', () {
      final signs = dangerSignsOf(alert(
        summary: 'URGENT: Ama needs help. Danger signs: not specified.',
      ));
      expect(signs, isEmpty);
    });

    test('prefers the structured assessment when it is populated', () {
      final signs = dangerSignsOf({
        'summary': 'no marker here',
        'assessment': {
          'dangerSigns': ['convulsion', '', '  '],
        },
      });
      expect(signs, ['convulsion']);
    });
  });

  group('triage level', () {
    test('flags a recognised critical sign', () {
      final triage = triageOf(alert(
        summary: 'Help. Danger signs: difficulty breathing.',
      ));
      expect(triage.level, TriageLevel.critical);
      expect(triage.label, 'CRITICAL');
    });

    test('flags three or more signs even when none are critical terms', () {
      final triage = triageOf(alert(
        summary: 'Help. Danger signs: headache, tiredness, poor appetite.',
      ));
      expect(triage.level, TriageLevel.critical);
    });

    test('one or two signs is high but not critical', () {
      final triage =
          triageOf(alert(summary: 'Help. Danger signs: headache.'));
      expect(triage.level, TriageLevel.high);
      expect(triage.label, 'HIGH');
    });

    test('no signs is stable', () {
      expect(triageOf(alert(summary: 'Routine check-in.')).level,
          TriageLevel.standard);
    });
  });

  group('case ordering', () {
    test('open cases come before closed ones', () {
      final sorted = sortCases([
        alert(status: 'closed'),
        alert(status: 'pending'),
      ]);
      expect(sorted.first['status'], 'pending');
      expect(sorted.last['status'], 'closed');
    });

    test('within a status, critical triage is ranked first', () {
      final sorted = sortCases([
        alert(summary: 'Help. Danger signs: headache.'),
        alert(summary: 'Help. Danger signs: convulsion.'),
      ]);
      expect(sorted.first['summary'], contains('convulsion'));
    });
  });

  group('distance helpers', () {
    test('formats metres and kilometres', () {
      expect(distanceLabel(null), 'Distance unknown');
      expect(distanceLabel(420), '420 m');
      expect(distanceLabel(2490), '2.5 km');
    });

    test('computes a plausible distance between two points', () {
      final metres = distanceMeters(alert(), 5.65, 0.0);
      expect(metres, isNotNull);
      expect(metres, lessThan(5));
    });
  });

  group('pending action serialisation', () {
    test('round-trips a queued status update', () {
      final queuedAt = DateTime.utc(2026, 11, 3, 9, 30);
      final original = PendingAction(
        alertId: 'a1',
        status: 'en_route',
        note: 'On my way',
        queuedAt: queuedAt,
      );
      final restored = PendingAction.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.alertId, 'a1');
      expect(restored.status, 'en_route');
      expect(restored.note, 'On my way');
      expect(restored.queuedAt, queuedAt);
    });

    test('drops malformed entries instead of crashing the queue', () {
      expect(PendingAction.fromJson('nope'), isNull);
      expect(PendingAction.fromJson({'status': 'acknowledged'}), isNull);
    });
  });
}

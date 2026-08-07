import 'package:flutter_test/flutter_test.dart';
import 'package:grow_with_me/data/model/nlu_service.dart';

/// Pins the Dart featurizer to the training notebook's implementation.
/// The expected numbers come from ml/train_nana_nlu.ipynb's contract-check
/// cell — if either side changes, this test (and the notebook probe) must
/// change together, otherwise on-device predictions become noise.
void main() {
  test('nlu featurizer matches the training notebook contract', () {
    expect(NluService.fnv1a32('u:fever') % 8192, 4112);

    final v = NluService.featurize('my baby has fever', 8192);
    final nonzero = v.where((x) => x > 0).length;
    expect(nonzero, 21);

    final firstIdx = v.indexWhere((x) => x > 0);
    expect(firstIdx, 862);

    // L2 norm must be 1 for non-empty text.
    final norm = v.fold<double>(0, (s, x) => s + x * x);
    expect(norm, closeTo(1.0, 1e-6));
  });

  test('empty and symbol-only text featurizes to a zero vector', () {
    expect(NluService.featurize('', 8192).any((x) => x != 0), isFalse);
    expect(NluService.featurize('!!! ???', 8192).any((x) => x != 0), isFalse);
  });
}

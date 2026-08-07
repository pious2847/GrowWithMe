import 'dart:math' as math;

import '../api/api_client.dart';
import 'on_device_model.dart';

/// What the offline NLU understood from the caregiver's words.
class NluResult {
  const NluResult({
    required this.intent,
    required this.confidence,
    required this.subject,
  });

  final String intent;
  final double confidence;

  /// 'child' | 'pregnancy' | 'unknown'
  final String subject;
}

/// Tier 1.5 of OFFLINE_MODEL_PLAN.md — the distilled ~1 MB understanding
/// model (nana-nlu). It CLASSIFIES what the caregiver said (intent + subject);
/// it never generates text, so offline replies stay curated and vetted.
///
/// The featurizer below is a byte-exact contract with
/// ml/train_nana_nlu.ipynb — change one side and you must change the other:
/// lowercase; [^a-z0-9' ]→space; word unigrams `u:`, bigrams `b:_`, char
/// trigrams `c:` of `^tok$`; FNV-1a 32-bit % buckets; L2 normalize.
class NluService {
  NluService(ApiClient api) : _model = OnDeviceModel(api, 'nana-nlu');

  final OnDeviceModel _model;

  bool get ready => _model.ready;
  int? get version => _model.version;
  int? get sizeBytes => _model.sizeBytes;
  Future<void> ensureLatest() => _model.ensureLatest();

  /// Public for the contract test in test/nlu_featurizer_test.dart, which
  /// pins these against the numbers the training notebook prints.
  static int fnv1a32(String s) {
    var h = 2166136261;
    for (final b in s.codeUnits) {
      // Feature strings are ASCII by construction (see _featurize), so code
      // units equal UTF-8 bytes.
      h ^= b;
      h = (h * 16777619) & 0xFFFFFFFF;
    }
    return h;
  }

  static List<double> featurize(String text, int buckets) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final feats = <String>[];
    for (final w in cleaned) {
      feats.add('u:$w');
      final p = '^$w\$';
      for (var i = 0; i + 3 <= p.length; i++) {
        feats.add('c:${p.substring(i, i + 3)}');
      }
    }
    for (var i = 0; i + 1 < cleaned.length; i++) {
      feats.add('b:${cleaned[i]}_${cleaned[i + 1]}');
    }
    final v = List<double>.filled(buckets, 0);
    for (final f in feats) {
      v[fnv1a32(f) % buckets] += 1;
    }
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    if (norm > 0) {
      norm = 1 / math.sqrt(norm);
      for (var i = 0; i < v.length; i++) {
        v[i] *= norm;
      }
    }
    return v;
  }

  /// Classifies the caregiver's words. Returns null when the model is not
  /// downloaded yet or confidence is below the manifest threshold — callers
  /// fall back to the keyword parser, exactly the pre-NLU behavior.
  NluResult? classify(String text) {
    if (!ready || text.trim().isEmpty) return null;
    final meta = _model.meta;
    final intents = (meta['intents'] as List?)?.cast<String>();
    final subjects = (meta['subjects'] as List?)?.cast<String>();
    final buckets = (meta['buckets'] as num?)?.toInt();
    if (intents == null || subjects == null || buckets == null) return null;
    final minConfidence =
        (meta['minConfidence'] as num?)?.toDouble() ?? 0.5;

    final out =
        _model.run(featurize(text, buckets), intents.length + subjects.length);
    var bi = 0;
    for (var i = 1; i < intents.length; i++) {
      if (out[i] > out[bi]) bi = i;
    }
    var bs = 0;
    for (var i = 1; i < subjects.length; i++) {
      if (out[intents.length + i] > out[intents.length + bs]) bs = i;
    }
    if (out[bi] < minConfidence) return null;
    return NluResult(
      intent: intents[bi],
      confidence: out[bi],
      subject: subjects[bs],
    );
  }
}

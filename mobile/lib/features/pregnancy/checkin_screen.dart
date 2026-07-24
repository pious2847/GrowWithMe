import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/checkin.dart';
import '../assessment/result_screen.dart';

/// The 2–3 day pregnancy check-in. Question set = fixed danger-sign core +
/// AI-personalized extras from her history (fetched when online). Risk
/// classification is always deterministic. Urgent → location + alert + PDF
/// report to her registered hospital, all server-side on sync.
class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key, required this.pregnancy});

  final PregnancyRow pregnancy;

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen> {
  List<CheckinQuestion>? _questions;
  final Map<String, bool> _answers = {};
  int _index = 0;
  bool _finishing = false;
  bool _personalized = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    var questions = mergeQuestions(const []);
    try {
      final context = await ref.read(nanaAssistantProvider).buildContext();
      final res = await ref.read(apiClientProvider).dio.post(
        '/assistant/checkin-questions',
        data: {'context': context},
      );
      final ai = (res.data['questions'] as List? ?? [])
          .map((q) => CheckinQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      if (ai.isNotEmpty) {
        questions = mergeQuestions(ai);
        _personalized = true;
      }
    } catch (_) {
      // Offline — the deterministic core carries the check-in alone.
    }
    if (mounted) setState(() => _questions = questions);
    _speakCurrent();
  }

  void _speakCurrent() {
    if ((ref.read(autoVoiceProvider).value ?? false) && _questions != null) {
      if (_index < _questions!.length) {
        ref.read(ttsProvider).speak(_questions![_index].text);
      }
    }
  }

  Future<void> _answer(bool value) async {
    final questions = _questions!;
    _answers[questions[_index].id] = value;
    if (_index + 1 < questions.length) {
      setState(() => _index += 1);
      _speakCurrent();
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final questions = _questions!;
    final result = evaluateCheckin(questions, _answers);

    double? lng;
    double? lat;
    if (result.riskLevel == 'urgent') {
      try {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 15)));
          lng = pos.longitude;
          lat = pos.latitude;
        }
      } catch (_) {}
    }

    final db = ref.read(dbProvider);
    final assessmentId = const Uuid().v4();
    final now = DateTime.now();
    await db.transaction(() async {
      await db.into(db.assessments).insert(AssessmentsCompanion.insert(
            id: assessmentId,
            clientUpdatedAt: now.millisecondsSinceEpoch,
            subjectType: 'pregnancy',
            pregnancyId: Value(widget.pregnancy.id),
            answersJson: Value(jsonEncode([
              for (final q in questions)
                {'questionId': q.id, 'question': q.text, 'answer': _answers[q.id] ?? false}
            ])),
            dangerSignsJson: Value(jsonEncode(result.dangerSigns)),
            riskLevel: result.riskLevel,
            guidance: Value(result.guidance),
            lng: Value(lng),
            lat: Value(lat),
            completedAt: now,
          ));
      await (db.update(db.pregnancies)
            ..where((t) => t.id.equals(widget.pregnancy.id)))
          .write(PregnanciesCompanion(
        lastCheckinAt: Value(now),
        lastRiskLevel: Value(result.riskLevel),
        clientUpdatedAt: Value(now.millisecondsSinceEpoch),
        synced: const Value(false),
      ));
    });

    final synced = await ref.read(syncControllerProvider.notifier).sync();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
            result: result, assessmentId: assessmentId, synced: synced)));
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions;
    if (questions == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pregnancy check-in')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Nana is preparing your questions…'),
            ],
          ),
        ),
      );
    }
    if (_index >= questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = questions[_index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancy check-in'),
        actions: [
          IconButton(
            tooltip: 'Read aloud',
            icon: const Icon(Icons.volume_up),
            onPressed: () => ref.read(ttsProvider).speak(q.text),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
              value: (_index + 1) / questions.length),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_personalized)
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Text('🧓🏾'),
                  label: const Text('Personalized by Nana'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(height: 12),
            Text(q.text, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            SizedBox(
              height: 72,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _answer(true),
                icon: const Icon(Icons.check_circle, size: 30),
                label: const Text('Yes'),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  textStyle: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _answer(false),
                icon: const Icon(Icons.cancel, size: 30),
                label: const Text('No'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

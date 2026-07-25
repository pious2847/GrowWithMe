import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
  final SpeechToText _speech = SpeechToText();
  int _index = 0;
  bool _finishing = false;
  bool _personalized = false;
  bool _voiceSession = false;
  bool _listening = false;
  int _voiceRetries = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _speech.stop();
    ref.read(nanaVoiceProvider).stop();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    var questions = mergeQuestions(const []);
    try {
      // Check-in-specific context: her week + past answers, so the AI can
      // follow up on what she actually reported before.
      final context = await ref
          .read(nanaAssistantProvider)
          .buildCheckinContext(widget.pregnancy);
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
    if (_voiceSession) return; // the voice session speaks for itself
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
      if (_voiceSession) {
        _askCurrent();
      } else {
        _speakCurrent();
      }
    } else {
      if (_voiceSession) {
        await _speech.stop();
        await ref
            .read(nanaVoiceProvider)
            .speak('Thank you, my daughter. Let me look at your answers.');
      }
      await _finish();
    }
  }

  // ---- Voice session: Nana asks each question aloud, listens for YES/NO,
  // ---- and moves on — hands-free from start to saved result.

  Future<void> _toggleVoiceSession() async {
    if (_voiceSession) {
      _voiceSession = false;
      await _speech.stop();
      await ref.read(nanaVoiceProvider).stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _voiceSession = true);
    await ref.read(nanaVoiceProvider).speak(
        'I will ask you the questions myself. After each one, answer me with YES or NO.');
    if (mounted && _voiceSession) _askCurrent();
  }

  Future<void> _askCurrent() async {
    if (!_voiceSession || _questions == null || _index >= _questions!.length) {
      return;
    }
    _voiceRetries = 0;
    await _speech.stop(); // cancel any leftover listening first
    await ref.read(nanaVoiceProvider).speak(_questions![_index].text);
    if (!mounted || !_voiceSession) return;
    // Short pause so the mic never hears the tail of Nana's own voice.
    await Future.delayed(const Duration(milliseconds: 350));
    _listenForAnswer();
  }

  Future<void> _listenForAnswer() async {
    if (!_voiceSession || !mounted) return;
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) {
          setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      setState(() => _voiceSession = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Microphone is not available — tap YES or NO instead')));
      return;
    }
    if (!mounted || !_voiceSession) return;
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(partialResults: false),
      onResult: (result) {
        if (result.finalResult) {
          if (mounted) setState(() => _listening = false);
          _handleVoiceAnswer(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _handleVoiceAnswer(String words) async {
    if (!_voiceSession || !mounted) return;
    final tokens = words.toLowerCase().split(RegExp(r'[^a-z]+'));
    const noWords = ['no', 'not', 'nope', 'never', 'nothing', 'don', 'dont'];
    const yesWords = ['yes', 'yeah', 'yep', 'yah', 'sure', 'correct', 'true'];
    bool? value;
    if (tokens.any(noWords.contains)) {
      value = false;
    } else if (tokens.any(yesWords.contains)) {
      value = true;
    }

    if (value == null) {
      _voiceRetries += 1;
      if (_voiceRetries >= 3) {
        // She's struggling with the mic — hand this one back to the buttons.
        await ref
            .read(nanaVoiceProvider)
            .speak('Tap YES or NO on the screen for this one.');
        return;
      }
      await ref
          .read(nanaVoiceProvider)
          .speak('Please answer me with YES or NO.');
      if (mounted && _voiceSession) _listenForAnswer();
      return;
    }
    _answer(value);
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
            const Spacer(),
            if (_voiceSession)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      _listening ? Icons.hearing : Icons.record_voice_over,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _listening
                            ? 'Nana is listening — say YES or NO'
                            : 'Nana is speaking…',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Stop voice session',
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: _toggleVoiceSession,
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _toggleVoiceSession,
                icon: const Icon(Icons.support_agent),
                label: const Text('Let Nana ask me aloud'),
              ),
          ],
        ),
      ),
    );
  }
}

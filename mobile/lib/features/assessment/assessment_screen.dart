import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/triage/triage_engine.dart';
import 'result_screen.dart';

/// Adaptive triage flow. Works fully offline: questions and rules live on
/// device; the completed assessment is stored locally and synced when online.
/// For urgent results, location is captured (with consent) so the backend can
/// route the nearest volunteer and facility.
class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key, required this.subjectType, this.childId});

  final String subjectType; // child | pregnancy | mother
  final String? childId;

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

/// Language-neutral visual cues so non-readers can recognize each option.
const Map<String, String> kOptionEmoji = {
  'Convulsions or fits': '⚡',
  'Unconscious or very sleepy': '😴',
  'Unable to drink or breastfeed': '🍼',
  'Vomits everything': '🤮',
  'Vaginal bleeding': '🩸',
  'Severe headache with blurred vision': '🤕',
  'Severe abdominal pain': '😖',
  'Water has broken before time': '💧',
  'None of these': '✅',
};

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  final Map<String, dynamic> _answers = {};
  final DateTime _startedAt = DateTime.now();
  final _numberController = TextEditingController();
  int _index = 0;
  bool _finishing = false;

  List<TriageQuestion> get _visible =>
      TriageEngine.questionsFor(widget.subjectType)
          .where((q) => q.isVisible(_answers))
          .toList();

  @override
  void initState() {
    super.initState();
    // Voice mode: read the first question as soon as the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSpeakQuestion());
  }

  void _maybeSpeakQuestion() {
    if (ref.read(autoVoiceProvider).value ?? false) {
      final questions = _visible;
      if (_index < questions.length) {
        ref.read(ttsProvider).speak(questions[_index].text);
      }
    }
  }

  void _answer(dynamic value) {
    final questions = _visible;
    final q = questions[_index];
    setState(() {
      _answers[q.id] = value;
      _numberController.clear();
      // Visibility can change after each answer — recompute and advance.
      final updated = _visible;
      final currentPos = updated.indexWhere((x) => x.id == q.id);
      if (currentPos + 1 < updated.length) {
        _index = currentPos + 1;
      } else {
        _finish();
      }
    });
    _maybeSpeakQuestion();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;

    final result = TriageEngine.evaluate(widget.subjectType, _answers);
    double? lng;
    double? lat;

    if (result.riskLevel == 'urgent') {
      // Location only at the moment of an urgent alert, per consent model.
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
      } catch (_) {
        // No fix — the alert still goes out without coordinates.
      }
    }

    final db = ref.read(dbProvider);
    final assessmentId = const Uuid().v4();
    await db.into(db.assessments).insert(AssessmentsCompanion.insert(
          id: assessmentId,
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          subjectType: widget.subjectType,
          childId: Value(widget.childId),
          answersJson: Value(jsonEncode([
            for (final e in _answers.entries) {'questionId': e.key, 'answer': e.value}
          ])),
          dangerSignsJson: Value(jsonEncode(result.dangerSigns)),
          riskLevel: result.riskLevel,
          guidance: Value(result.guidance),
          lng: Value(lng),
          lat: Value(lat),
          startedAt: Value(_startedAt),
          completedAt: DateTime.now(),
        ));

    // Urgent offline results fire the alert the moment this succeeds.
    final synced = await ref.read(syncControllerProvider.notifier).sync();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
            result: result, assessmentId: assessmentId, synced: synced)));
  }

  @override
  Widget build(BuildContext context) {
    final questions = _visible;
    if (_index >= questions.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = questions[_index];
    final progress = (_index + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectType == 'child'
            ? 'Child health check'
            : 'Pregnancy health check'),
        actions: [
          IconButton(
            tooltip: 'Read question aloud',
            icon: const Icon(Icons.volume_up),
            onPressed: () => ref.read(ttsProvider).speak(q.text),
          ),
          IconButton(
            tooltip: 'Voice mode: read every question automatically',
            icon: Icon(
              (ref.watch(autoVoiceProvider).value ?? false)
                  ? Icons.record_voice_over
                  : Icons.voice_over_off,
              color: (ref.watch(autoVoiceProvider).value ?? false)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () async {
              await ref.read(autoVoiceProvider.notifier).toggle();
              _maybeSpeakQuestion();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: progress),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(q.text, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 32),
            Expanded(child: _buildInput(q)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TriageQuestion q) {
    switch (q.type) {
      case QuestionType.yesNo:
        // Big, color + icon coded buttons — readable without reading.
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
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
              width: double.infinity,
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
        );
      case QuestionType.number:
        return Column(
          children: [
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: 'Number of days'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () =>
                    _answer(num.tryParse(_numberController.text) ?? 0),
                child: const Text('Next'),
              ),
            ),
          ],
        );
      case QuestionType.multi:
        return _MultiSelect(options: q.options!, onDone: _answer);
    }
  }
}

class _MultiSelect extends StatefulWidget {
  const _MultiSelect({required this.options, required this.onDone});

  final List<String> options;
  final void Function(List<String>) onDone;

  @override
  State<_MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<_MultiSelect> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final noneOption = widget.options.last;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final option in widget.options)
                CheckboxListTile(
                  value: _selected.contains(option),
                  title: Text(
                    '${kOptionEmoji[option] ?? '•'}  $option',
                    style: const TextStyle(fontSize: 16),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      if (option == noneOption) {
                        _selected.clear();
                      } else {
                        _selected.remove(noneOption);
                      }
                      _selected.add(option);
                    } else {
                      _selected.remove(option);
                    }
                  }),
                ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _selected.isEmpty ? null : () => widget.onDone(_selected.toList()),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}

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
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () => _answer(true), child: const Text('Yes')),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                  onPressed: () => _answer(false), child: const Text('No')),
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
                  title: Text(option),
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

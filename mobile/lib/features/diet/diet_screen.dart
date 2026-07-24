import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/diet_guide.dart';

/// Nana's Kitchen: seasonal, budget-aware meal plans (AI-personalized from
/// her pantry when online, offline library otherwise) + the Daily Plate
/// dietary-diversity tracker. Everything persists and syncs.
class DietScreen extends ConsumerStatefulWidget {
  const DietScreen({super.key});

  @override
  ConsumerState<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends ConsumerState<DietScreen> {
  bool _building = false;
  bool _listening = false;
  final _tellController = TextEditingController();
  final _tellFocus = FocusNode();
  final SpeechToText _speech = SpeechToText();

  @override
  void dispose() {
    _speech.stop();
    _tellController.dispose();
    _tellFocus.dispose();
    super.dispose();
  }

  /// Voice call mode: she just talks — "money is small, I have maize and
  /// groundnut, we are five" — Nana extracts what matters, saves her words,
  /// and answers out loud.
  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) {
          setState(() => _listening = false);
        }
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Microphone is not available on this phone')));
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        _tellController.text = result.recognizedWords;
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _listening = false);
          _tellNana(result.recognizedWords);
        }
      },
    );
  }

  Future<void> _tellNana(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _building) return;
    _tellController.clear();
    setState(() => _building = true);

    final latest = await ref.read(dbProvider).latestDietPlan();
    final plan = await ref.read(dietPlannerProvider).generate(
          budget: latest?.budget ?? 'low',
          pantry: latest?.pantry ?? '',
          household: '4',
          spokenText: trimmed,
        );
    ref.read(syncControllerProvider.notifier).sync();

    if (mounted) setState(() => _building = false);
    final summary = plan['summary'] as String? ?? '';
    if (summary.isNotEmpty) ref.read(nanaVoiceProvider).speak(summary);
  }

  /// One tap on a recommended meal = "I prepared this": records the meal for
  /// the day and auto-ticks its food groups on the Daily Plate — following
  /// the plan IS the tracking.
  Future<void> _markMealEaten(
      List<DietLogRow> logs, Map<String, dynamic> meal) async {
    final label = '${meal['time']} — ${meal['name']}';
    final today = _todayState(logs);
    if (today.eaten.contains(label)) return;

    final eaten = [...today.eaten, label];
    final groups = [...today.groups];
    for (final g in inferGroups('${meal['name']} ${meal['ingredients']}')) {
      if (!groups.contains(g)) groups.add(g);
    }
    await _writeToday(logs, groups: groups, eaten: eaten);
    ref.read(syncControllerProvider.notifier).sync();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Well done! ${meal['name']} added to today\'s plate.')));
  }

  Future<void> _newPlan() async {
    // Quick wizard: affordability → pantry → household size.
    final answers = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => const _PlanWizardSheet(),
    );
    if (answers == null) return;
    setState(() => _building = true);

    final plan = await ref.read(dietPlannerProvider).generate(
          budget: answers['budget']!,
          pantry: answers['pantry']!,
          household: answers['household']!,
        );
    ref.read(syncControllerProvider.notifier).sync();

    if (mounted) setState(() => _building = false);
    final summary = plan['summary'] as String? ?? '';
    if (summary.isNotEmpty) ref.read(nanaVoiceProvider).speak(summary);
  }

  /// Union of a day's rows (duplicates can exist from an earlier bug — they
  /// are merged into the first row and tombstoned on the next write).
  ({DietLogRow? canonical, List<int> groups, List<String> eaten}) _todayState(
      List<DietLogRow> logs) {
    final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final rows = logs.where((l) => l.day == dayKey).toList();
    final groups = <int>{};
    final eaten = <String>{};
    for (final r in rows) {
      try {
        groups.addAll((jsonDecode(r.groupsJson) as List).cast<int>());
      } catch (_) {}
      if (r.eatenMealsJson != null) {
        try {
          eaten.addAll((jsonDecode(r.eatenMealsJson!) as List).cast<String>());
        } catch (_) {}
      }
    }
    return (
      canonical: rows.isEmpty ? null : rows.first,
      groups: groups.toList(),
      eaten: eaten.toList(),
    );
  }

  Future<void> _writeToday(List<DietLogRow> logs,
      {required List<int> groups, required List<String> eaten}) async {
    final db = ref.read(dbProvider);
    final now = DateTime.now();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    final rows = logs.where((l) => l.day == dayKey).toList();
    final score = diversityScore(groups);

    if (rows.isEmpty) {
      await db.into(db.dietLogs).insert(DietLogsCompanion.insert(
            id: const Uuid().v4(),
            clientUpdatedAt: now.millisecondsSinceEpoch,
            day: dayKey,
            groupsJson: jsonEncode(groups),
            score: score,
            eatenMealsJson: Value(jsonEncode(eaten)),
          ));
      return;
    }
    await (db.update(db.dietLogs)..where((t) => t.id.equals(rows.first.id)))
        .write(DietLogsCompanion(
      groupsJson: Value(jsonEncode(groups)),
      score: Value(score),
      eatenMealsJson: Value(jsonEncode(eaten)),
      clientUpdatedAt: Value(now.millisecondsSinceEpoch),
      synced: const Value(false),
    ));
    // Tombstone accidental duplicates so they stop confusing the charts.
    for (final dup in rows.skip(1)) {
      await (db.update(db.dietLogs)..where((t) => t.id.equals(dup.id)))
          .write(DietLogsCompanion(
        deleted: const Value(true),
        clientUpdatedAt: Value(now.millisecondsSinceEpoch),
        synced: const Value(false),
      ));
    }
  }

  Future<void> _toggleGroup(List<DietLogRow> logs, int index) async {
    final today = _todayState(logs);
    final groups = [...today.groups];
    if (groups.contains(index)) {
      groups.remove(index);
    } else {
      groups.add(index);
    }
    await _writeToday(logs, groups: groups, eaten: today.eaten);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latestPlan = ref.watch(latestDietPlanProvider).value;
    final logs =
        ref.watch(recentDietLogsProvider).value ?? const <DietLogRow>[];
    final today = _todayState(logs);
    final todayGroups = today.groups;
    final todayScore = diversityScore(todayGroups);

    Map<String, dynamic>? plan;
    if (latestPlan != null) {
      try {
        plan = jsonDecode(latestPlan.planJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nana\'s Kitchen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- Daily Plate tracker ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Today\'s plate',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: todayScore >= 5
                            ? Colors.green.shade100
                            : theme.colorScheme.surfaceContainerHighest,
                        label: Text('$todayScore / ${foodGroups.length}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Tap what you (or your child) ate today',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < foodGroups.length; i++)
                        FilterChip(
                          selected: todayGroups.contains(i),
                          onSelected: (_) => _toggleGroup(logs, i),
                          label: Text(
                              '${foodGroups[i].emoji} ${foodGroups[i].name}'),
                          tooltip: foodGroups[i].examples,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(scoreMessage(todayScore),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),

          // ---- Weekly diversity chart ----
          if (logs.length > 1)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This week', style: theme.textTheme.titleSmall),
                    SizedBox(
                      height: 120,
                      child: BarChart(
                        BarChartData(
                          maxY: foodGroups.length.toDouble(),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= logs.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final d = DateTime.parse(
                                      logs.reversed.toList()[i].day);
                                  return Text(DateFormat('E').format(d),
                                      style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var i = 0;
                                i < logs.reversed.length;
                                i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: logs.reversed
                                      .toList()[i]
                                      .score
                                      .toDouble(),
                                  width: 14,
                                  borderRadius: BorderRadius.circular(4),
                                  color: logs.reversed.toList()[i].score >= 5
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),

          // ---- Meal plan ----
          Row(
            children: [
              Text('My meal plan', style: theme.textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: _building ? null : _newPlan,
                icon: _building
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.restaurant_menu, size: 18),
                label: Text(_building ? 'Cooking…' : '3 questions'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ---- Tell Nana directly: type or talk, like a call ----
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _listening
                        ? '🎙️ Nana is listening… just talk'
                        : 'Or just tell Nana — she picks out what matters',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: _listening
                            ? Colors.red
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            _listening ? FontWeight.bold : FontWeight.normal),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tellController,
                          focusNode: _tellFocus,
                          minLines: 1,
                          maxLines: 3,
                          onSubmitted: _tellNana,
                          decoration: const InputDecoration(
                            hintText:
                                'e.g. money is small, I have maize, groundnut and dried fish, we are five',
                            hintMaxLines: 2,
                            filled: false,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Material(
                        color: _listening
                            ? Colors.red
                            : theme.colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Talk to Nana',
                          onPressed: _building ? null : _toggleMic,
                          icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                              color: _listening ? Colors.white : null),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'Send to Nana',
                          onPressed: _building
                              ? null
                              : () => _tellNana(_tellController.text),
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (plan == null)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _tellFocus.requestFocus(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No plan yet. Tap the microphone and tell Nana about your '
                    'food and money — or type it above. She will use foods in '
                    'season now (${seasonalFoodsHint(currentSeason())}).',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            )
          else ...[
            Card(
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Text('🧓🏾', style: TextStyle(fontSize: 26)),
                title: Text(plan['summary'] as String? ?? ''),
                subtitle: latestPlan == null
                    ? null
                    : Text(
                        '${latestPlan.source == 'ai' ? 'Personalized by Nana' : 'From Nana\'s cookbook'} · ${DateFormat('EEE d MMM').format(latestPlan.plannedFor)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.volume_up),
                  tooltip: 'Read the whole plan aloud',
                  onPressed: () {
                    final text = StringBuffer(plan!['summary'] ?? '');
                    for (final slot in planSlots(plan)) {
                      final names = (slot['options'] as List)
                          .map((o) => o['name'])
                          .join(', or ');
                      text.write(' ${slot['time']}: you can make $names.');
                    }
                    ref.read(nanaVoiceProvider).speak(text.toString());
                  },
                ),
              ),
            ),
            for (final slot in planSlots(plan)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                child: Text(
                  '${switch (slot['time']) {
                    'Morning' => '🌅',
                    'Midday' => '☀️',
                    'Evening' => '🌙',
                    _ => '🍌',
                  }} ${slot['time']}${(slot['options'] as List).length > 1 ? ' — choose one' : ''}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _MealSlotCarousel(
                slot: slot,
                eatenLabels: today.eaten,
                onMadeThis: (meal) => _markMealEaten(
                    logs, {...meal, 'time': slot['time']}),
              ),
            ],
            if ((plan['tips'] as List? ?? []).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final tip in plan['tips'] as List)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('🌿 $tip'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The two meal choices as a horizontal carousel: auto-flips between options
/// every few seconds so both get seen, pauses when she swipes herself, and
/// settles (stops flipping) on the option she marked as eaten.
class _MealSlotCarousel extends StatefulWidget {
  const _MealSlotCarousel({
    required this.slot,
    required this.eatenLabels,
    required this.onMadeThis,
  });

  final Map<String, dynamic> slot;
  final List<String> eatenLabels;
  final void Function(Map<String, dynamic> meal) onMadeThis;

  @override
  State<_MealSlotCarousel> createState() => _MealSlotCarouselState();
}

class _MealSlotCarouselState extends State<_MealSlotCarousel> {
  late final PageController _controller =
      PageController(viewportFraction: 0.94);
  Timer? _autoTimer;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _autoJump = false;
  int _page = 0;

  List<Map<String, dynamic>> get _options =>
      (widget.slot['options'] as List).cast<Map<String, dynamic>>();

  int _eatenIndex() {
    for (var i = 0; i < _options.length; i++) {
      if (widget.eatenLabels
          .contains('${widget.slot['time']} — ${_options[i]['name']}')) {
        return i;
      }
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    if (_options.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        if (DateTime.now().isBefore(_pausedUntil)) return;
        if (_eatenIndex() != -1) return; // she chose — stop flipping
        _autoJump = true;
        _controller.animateToPage(
          (_page + 1) % _options.length,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _options;
    if (options.length == 1) {
      return _OptionCard(
        meal: options.first,
        isEaten: _eatenIndex() == 0,
        onMadeThis: () => widget.onMadeThis(options.first),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 235,
          child: PageView.builder(
            controller: _controller,
            itemCount: options.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              if (_autoJump) {
                _autoJump = false;
              } else {
                // Manual swipe — give her time to read before flipping again.
                _pausedUntil =
                    DateTime.now().add(const Duration(seconds: 10));
              }
            },
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _OptionCard(
                meal: options[i],
                isEaten: _eatenIndex() == i,
                onMadeThis: () => widget.onMadeThis(options[i]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < options.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 7,
                width: i == _page ? 20 : 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.meal,
    required this.isEaten,
    required this.onMadeThis,
  });

  final Map<String, dynamic> meal;
  final bool isEaten;
  final VoidCallback onMadeThis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${meal['name']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 6),
            Text('${meal['ingredients']}',
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('Portion: ${meal['portion']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Expanded(
              child: Text('${meal['prep']}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                  style: theme.textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: isEaten
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Colors.green.shade700,
                        disabledForegroundColor: Colors.white,
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Eaten today ✓'),
                    )
                  : OutlinedButton.icon(
                      onPressed: onMadeThis,
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: const Text('I made this'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanWizardSheet extends StatefulWidget {
  const _PlanWizardSheet();

  @override
  State<_PlanWizardSheet> createState() => _PlanWizardSheetState();
}

class _PlanWizardSheetState extends State<_PlanWizardSheet> {
  String _budget = 'low';
  final _pantryController = TextEditingController();
  final _householdController = TextEditingController(text: '4');

  Widget _budgetOption(
      BuildContext context, String value, String emoji, String label) {
    final theme = Theme.of(context);
    final selected = _budget == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _budget = value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal)),
            ),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Keep the sheet above the keyboard.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Plan my meals',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Can you buy extra foods from the market this week?',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _budgetOption(context, 'ok', '🛒', 'Yes, I can buy some extras'),
              const SizedBox(height: 8),
              _budgetOption(
                  context, 'low', '🪙', 'Money is tight — use what I have'),
              const SizedBox(height: 18),
              TextField(
                controller: _pantryController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'What foodstuffs do you have at home?',
                  hintText: 'maize, groundnut, dried fish, kontomire…',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _householdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'How many people eat with you?',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(context, {
                    'budget': _budget,
                    'pantry': _pantryController.text.trim(),
                    'household': _householdController.text.trim().isEmpty
                        ? '4'
                        : _householdController.text.trim(),
                  }),
                  icon: const Text('🧓🏾', style: TextStyle(fontSize: 18)),
                  label: const Text('Ask Nana'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

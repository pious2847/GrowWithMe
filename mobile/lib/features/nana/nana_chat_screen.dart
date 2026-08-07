import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../data/assistant/nana_assistant.dart';
import '../../data/db/app_database.dart';
import '../../data/voice/nana_voice.dart';
import '../../domain/growth_reference.dart';
import '../assessment/assessment_screen.dart';
import '../children/add_child_screen.dart';
import '../diet/diet_screen.dart';
import '../pregnancy/add_pregnancy_screen.dart';

class _ChatMessage {
  _ChatMessage(this.role, this.text, {this.offline = false});

  final String role; // user | assistant
  final String text;

  /// true when the offline helper answered (backend unreachable) — shown as
  /// a small tag so the caregiver knows which brain spoke.
  final bool offline;
}

/// Nana — the voice-first AI care educator. Type or talk; Nana answers out
/// loud, teaches, and can operate the app for you (with confirmation).
class NanaChatScreen extends ConsumerStatefulWidget {
  const NanaChatScreen(
      {super.key, this.speakBriefingOnOpen = false, this.voiceMode = false});

  final bool speakBriefingOnOpen;

  /// Call-style companion: Nana listens as soon as she finishes talking, so
  /// the caregiver never touches the screen.
  final bool voiceMode;

  @override
  ConsumerState<NanaChatScreen> createState() => _NanaChatScreenState();
}

class _NanaChatScreenState extends ConsumerState<NanaChatScreen> {
  final List<_ChatMessage> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  // Cached in initState — Riverpod forbids ref lookups inside dispose().
  late final NanaVoice _voice;
  late final SyncController _syncController;
  bool _thinking = false;
  bool _listening = false;
  late bool _voiceMode = widget.voiceMode;
  NanaAction? _pendingAction;
  String? _pendingActionSummary;

  @override
  void initState() {
    super.initState();
    _voice = ref.read(nanaVoiceProvider);
    _syncController = ref.read(syncControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Nana remembers: load the saved conversation history first.
      final saved = await ref.read(dbProvider).recentChatMessages(50);
      if (mounted && saved.isNotEmpty) {
        setState(() {
          _messages.addAll(
              saved.reversed.map((m) => _ChatMessage(m.role, m.content)));
        });
        _scrollDown();
      }
      if (widget.speakBriefingOnOpen) {
        final briefing = await ref.read(nanaAssistantProvider).buildBriefing();
        _addAssistant(briefing, speak: true);
      } else if (_voiceMode) {
        _addAssistant(
          'I am here, my daughter. Talk to me — ask me anything, or tell me '
          'how you are feeling today.',
          speak: true,
          persist: false,
        );
      } else if (saved.isEmpty) {
        _addAssistant(
          'Hello, I am Nana. 🌼 How is the family today? You can ask me '
          'anything, or tap the microphone and just talk to me.',
          speak: false,
          persist: false,
        );
      }
    });
  }

  void _persist(String role, String text) {
    final db = ref.read(dbProvider);
    db.into(db.chatMessages).insert(ChatMessagesCompanion.insert(
          id: const Uuid().v4(),
          clientUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          role: role,
          content: text,
          sentAt: DateTime.now(),
        ));
  }

  @override
  void dispose() {
    _speech.stop();
    _voice.stop();
    // Push the conversation to the server in the background.
    _syncController.sync();
    super.dispose();
  }

  void _addAssistant(String text,
      {bool speak = true, bool persist = true, bool offline = false}) {
    setState(() =>
        _messages.add(_ChatMessage('assistant', text, offline: offline)));
    if (persist) _persist('assistant', text);
    if (speak) _speakReply(text);
    _scrollDown();
  }

  /// In voice mode: speak, and when the voice finishes, open the mic again —
  /// the conversation flows like a phone call. The short pause keeps the mic
  /// from hearing the tail of Nana's own voice.
  Future<void> _speakReply(String text) async {
    await ref.read(nanaVoiceProvider).speak(text);
    if (!mounted || !_voiceMode) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted &&
        _voiceMode &&
        !_listening &&
        !_thinking &&
        _pendingAction == null) {
      _toggleMic();
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? overrideText]) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _thinking) return;
    _inputController.clear();
    setState(() {
      _messages.add(_ChatMessage('user', text));
      _thinking = true;
      _pendingAction = null;
    });
    _persist('user', text);
    _scrollDown();

    final history = [
      for (final m in _messages)
        {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text},
    ];
    final reply = await ref.read(nanaAssistantProvider).send(text, history);

    setState(() => _thinking = false);
    if (reply.action != null) {
      await _handleAction(reply);
    } else {
      _addAssistant(reply.say, offline: !reply.fromLlm);
    }
  }

  Future<void> _handleAction(NanaReply reply) async {
    final action = reply.action!;
    final offline = !reply.fromLlm;
    switch (action.name) {
      // Immediate, non-mutating actions
      case 'start_health_check':
        _addAssistant(reply.say, offline: offline);
        final childName = action.params['childName'] as String?;
        final child = childName == null
            ? null
            : await ref.read(careActionsProvider).findChildByName(childName);
        // Subject can come by name lookup (online LLM) or as a plain
        // 'subject' param (offline NLU, which knows child vs pregnancy but
        // not names).
        final subjectParam = action.params['subject'] as String?;
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AssessmentScreen(
                subjectType:
                    child != null ? 'child' : (subjectParam ?? 'pregnancy'),
                childId: child?.id)));
        return;
      case 'open_add_child':
        _addAssistant(reply.say, offline: offline);
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
        return;
      case 'open_add_pregnancy':
        _addAssistant(reply.say, offline: offline);
        if (!mounted) return;
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPregnancyScreen()));
        return;
      case 'plan_diet':
        _addAssistant(reply.say, offline: offline);
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DietScreen()));
        return;
      case 'read_today':
        _addAssistant(reply.say, speak: false, offline: offline);
        final briefing = await ref.read(nanaAssistantProvider).buildBriefing();
        _addAssistant(briefing);
        return;
      // Mutating actions require a visible confirmation
      case 'add_child':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Add child: ${action.params['name']} (${action.params['sex'] ?? '?'}), born ${action.params['dateOfBirth']}';
        });
        _addAssistant(reply.say, offline: offline);
        return;
      case 'add_pregnancy':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Track pregnancy, due ${action.params['expectedDueDate']}';
        });
        _addAssistant(reply.say, offline: offline);
        return;
      case 'log_weight':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Save weight ${action.params['weightKg']} kg for ${action.params['childName']}';
        });
        _addAssistant(reply.say, offline: offline);
        return;
      case 'set_reminder':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Remind you: "${action.params['title']}" on ${action.params['date']} at ${action.params['time'] ?? '09:00'}';
        });
        _addAssistant(reply.say, offline: offline);
        return;
      default:
        _addAssistant(reply.say, offline: offline);
    }
  }

  Future<void> _confirmPending() async {
    final action = _pendingAction;
    if (action == null) return;
    setState(() => _pendingAction = null);
    final actions = ref.read(careActionsProvider);

    try {
      switch (action.name) {
        case 'add_child':
          final dob = DateTime.parse(action.params['dateOfBirth'] as String);
          await actions.addChild(
            name: action.params['name'] as String,
            sex: action.params['sex'] as String?,
            dateOfBirth: dob,
          );
          _addAssistant(
              'Done! ${action.params['name']} is registered and their care '
              'calendar is ready. I will remind you before every visit.');
          break;
        case 'add_pregnancy':
          final edd =
              DateTime.parse(action.params['expectedDueDate'] as String);
          await actions.addPregnancy(expectedDueDate: edd);
          _addAssistant(
              'Wonderful. Your antenatal visits are now on the calendar, '
              'expecting baby around ${DateFormat('d MMMM').format(edd)}. '
              'I am with you all the way.');
          break;
        case 'log_weight':
          final name = action.params['childName'] as String;
          final weight = (action.params['weightKg'] as num).toDouble();
          final child = await actions.findChildByName(name);
          if (child == null) {
            _addAssistant(
                'Hmm, I could not find a child called $name. Please check the name.');
            return;
          }
          await actions.logWeight(childId: child.id, weightKg: weight);
          final ageMonths =
              DateTime.now().difference(child.dateOfBirth).inDays / 30.44;
          final screen = assessWeight(weight, ageMonths, child.sex);
          _addAssistant('Weight saved. ${screen.message}');
          break;
        case 'set_reminder':
          final title = action.params['title'] as String;
          final date = action.params['date'] as String;
          final time = (action.params['time'] as String?) ?? '09:00';
          final parts = time.split(':');
          final day = DateTime.parse(date);
          final when = DateTime(day.year, day.month, day.day,
              int.tryParse(parts[0]) ?? 9, int.tryParse(parts.elementAtOrNull(1) ?? '0') ?? 0);
          final id = await actions.addCustomReminder(title: title, when: when);
          await ref.read(notificationServiceProvider).schedule(
                reminderId: id,
                title: 'GrowWithMe reminder',
                body: title,
                when: when,
              );
          _addAssistant(
              'Done. I will remind you: "$title" on ${DateFormat('EEEE d MMMM').format(when)} at ${DateFormat.jm().format(when)}. It is on your calendar too.');
          break;
      }
      ref.read(syncControllerProvider.notifier).sync();
    } catch (e) {
      _addAssistant(
          'Sorry, I could not do that. Please try again or use the buttons.');
    }
  }

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
        _inputController.text = result.recognizedWords;
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => _listening = false);
          _send(result.recognizedWords);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(child: Text('🧓🏾')),
            const SizedBox(width: 10),
            const Text('Nana'),
            if (_voiceMode) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('● on call',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: _voiceMode
                ? 'End voice conversation'
                : 'Start voice conversation',
            icon: Icon(_voiceMode ? Icons.call_end : Icons.phone_in_talk,
                color: _voiceMode ? Colors.red : null),
            onPressed: () {
              setState(() => _voiceMode = !_voiceMode);
              if (_voiceMode) {
                if (!_listening) _toggleMic();
              } else {
                if (_listening) _toggleMic();
                ref.read(nanaVoiceProvider).stop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Always-visible honesty note: Nana is an AI and can be wrong.
          Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'ℹ️ Nana is an AI helper and can make mistakes. For anything '
              'serious, always check with a nurse, midwife or doctor.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_thinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(children: [
                      SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('Nana is thinking…'),
                    ]),
                  );
                }
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.text,
                          style: TextStyle(
                              color: isUser ? Colors.white : null,
                              height: 1.35),
                        ),
                        if (m.offline)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '📴 offline helper — connect to reach Nana\'s full brain',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_pendingAction != null)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shall I do this?',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_pendingActionSummary ?? ''),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _confirmPending,
                            icon: const Icon(Icons.check),
                            label: const Text('Yes, do it'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _pendingAction = null);
                              _addAssistant('Okay, I will not do it.');
                            },
                            child: const Text('No'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText:
                            _listening ? 'Listening…' : 'Ask Nana anything…',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: _listening
                        ? Colors.red
                        : theme.colorScheme.primaryContainer,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Talk to Nana',
                      onPressed: _toggleMic,
                      icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                          color: _listening ? Colors.white : null),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

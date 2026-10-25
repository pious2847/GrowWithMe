import 'package:drift/drift.dart' hide Column;
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
import '../calendar/calendar_tab.dart';
import '../children/add_child_screen.dart';
import '../diet/diet_screen.dart';
import '../pregnancy/add_pregnancy_screen.dart';
import '../pregnancy/checkin_screen.dart';
import '../tips/tips_tab.dart';

class _ChatMessage {
  _ChatMessage(this.role, this.text, {this.offline = false, this.source = 'llm'});

  final String role; // user | assistant
  final String text;

  /// Which brain produced this: 'llm', 'nlu' (on-device model) or 'keyword'.
  final String source;

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
      {bool speak = true,
      bool persist = true,
      bool offline = false,
      String source = 'llm'}) {
    setState(() => _messages
        .add(_ChatMessage('assistant', text, offline: offline, source: source)));
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
      _addAssistant(reply.say,
          offline: !reply.fromLlm, source: reply.source);
    }
  }

  Future<void> _handleAction(NanaReply reply) async {
    final action = reply.action!;
    final offline = !reply.fromLlm;
    switch (action.name) {
      // Immediate, non-mutating actions
      case 'start_health_check':
        _addAssistant(reply.say, offline: offline, source: reply.source);
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
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddChildScreen()));
        return;
      case 'open_add_pregnancy':
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddPregnancyScreen()));
        return;
      case 'plan_diet':
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const DietScreen()));
        return;
      case 'read_today':
        _addAssistant(reply.say,
            speak: false, offline: offline, source: reply.source);
        final briefing = await ref.read(nanaAssistantProvider).buildBriefing();
        _addAssistant(briefing);
        return;
      case 'open_calendar':
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('My calendar')),
                body: const CalendarTab())));
        return;
      case 'open_tips':
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Tips & lessons')),
                body: const TipsTab())));
        return;
      case 'start_checkin':
        final db = ref.read(dbProvider);
        final pregnancy = await (db.select(db.pregnancies)
              ..where((t) => t.deleted.equals(false) & t.status.equals('active')))
            .getSingleOrNull();
        if (pregnancy == null) {
          _addAssistant(
              'You are not tracking a pregnancy yet. Tell me "I am pregnant" '
              'and we will start together.',
              offline: offline,
              source: reply.source);
          return;
        }
        _addAssistant(reply.say, offline: offline, source: reply.source);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CheckinScreen(pregnancy: pregnancy)));
        return;
      // Mutating actions require a visible confirmation
      case 'add_child':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Add child: ${action.params['name']} (${action.params['sex'] ?? '?'}), born ${action.params['dateOfBirth']}';
        });
        _addAssistant(reply.say, offline: offline, source: reply.source);
        return;
      case 'add_pregnancy':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Track pregnancy, due ${action.params['expectedDueDate']}';
        });
        _addAssistant(reply.say, offline: offline, source: reply.source);
        return;
      case 'log_weight':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Save weight ${action.params['weightKg']} kg for ${action.params['childName']}';
        });
        _addAssistant(reply.say, offline: offline, source: reply.source);
        return;
      case 'set_reminder':
        setState(() {
          _pendingAction = action;
          _pendingActionSummary =
              'Remind you: "${action.params['title']}" on ${action.params['date']} at ${action.params['time'] ?? '09:00'}';
        });
        _addAssistant(reply.say, offline: offline, source: reply.source);
        return;
      default:
        _addAssistant(reply.say, offline: offline, source: reply.source);
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

  Widget _quickChip(String emoji, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Text(emoji, style: const TextStyle(fontSize: 18)),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildModelStatusRow(
    BuildContext context, {
    required String title,
    required String filename,
    required bool ready,
    required int? version,
    required int? size,
  }) {
    final theme = Theme.of(context);
    final isDownloaded = ready;
    
    String formatSize(int? bytes) {
      if (bytes == null) return '0 KB';
      if (bytes >= 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
      return '${(bytes / 1024).round()} KB';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDownloaded
            ? theme.colorScheme.primaryContainer.withAlpha(31)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDownloaded
              ? theme.colorScheme.primary.withAlpha(51)
              : theme.colorScheme.outline.withAlpha(38),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDownloaded ? Icons.check_circle : Icons.cloud_download_outlined,
            color: isDownloaded ? Colors.green.shade600 : theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  filename,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDownloaded
                  ? theme.colorScheme.primary.withAlpha(26)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isDownloaded ? 'v$version • ${formatSize(size)}' : 'Not Loaded',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDownloaded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineStatus() {
    final nlu = ref.read(nluServiceProvider);
    final risk = ref.read(modelServiceProvider);
    final slm = ref.read(slmServiceProvider);
    
    bool isChecking = false;
    String statusMessage = '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.offline_bolt,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Offline AI Status',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _buildModelStatusRow(
                      context,
                      title: 'Nana Understanding',
                      filename: 'nana-nlu',
                      ready: nlu.ready,
                      version: nlu.version,
                      size: nlu.sizeBytes,
                    ),
                    _buildModelStatusRow(
                      context,
                      title: 'Vitals Risk Model',
                      filename: 'maternal-risk',
                      ready: risk.ready,
                      version: risk.version,
                      size: risk.sizeBytes,
                    ),
                    _buildModelStatusRow(
                      context,
                      title: 'Nana SLM Adapter',
                      filename: 'nana-slm',
                      ready: slm.ready,
                      version: slm.version,
                      size: slm.sizeBytes,
                    ),
                    const SizedBox(height: 12),
                    if (isChecking) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withAlpha(26)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                statusMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (statusMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusMessage.startsWith('Error')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusMessage.startsWith('Error')
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusMessage.startsWith('Error')
                                ? Colors.red.shade800
                                : Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'When the green bolt shows in the chat header, you can use Nana completely offline! Open airplane mode and try asking maternal questions—replies will show which local helper produced them.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isChecking ? null : () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: isChecking
                      ? null
                      : () async {
                          setState(() {
                            isChecking = true;
                            statusMessage = 'Checking Nana NLU...';
                          });
                          try {
                            await nlu.ensureLatest(throwOnError: true);
                            setState(() {
                              statusMessage = 'Checking Vitals Risk...';
                            });
                            await risk.ensureLatest(throwOnError: true);
                            setState(() {
                              statusMessage = 'Checking Nana SLM...';
                            });
                            await slm.ensureLatest(throwOnError: true);
                            setState(() {
                              statusMessage = 'All models updated successfully!';
                              isChecking = false;
                            });
                          } catch (e) {
                            setState(() {
                              statusMessage = 'Error: ${e.toString().split('\n').first}';
                              isChecking = false;
                            });
                          }
                        },
                  icon: isChecking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Check now'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Choose voice engine',
            icon: const Icon(Icons.settings_voice),
            onSelected: (String choice) async {
              await ref.read(voiceProviderProvider.notifier).setProvider(choice);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voice engine switched to ${choice == 'elevenlabs' ? 'ElevenLabs' : 'Fish Audio'}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (BuildContext context) {
              final activeProvider = ref.watch(voiceProviderProvider).value ?? 'elevenlabs';
              return [
                PopupMenuItem<String>(
                  value: 'elevenlabs',
                  child: Row(
                    children: [
                      const Text('ElevenLabs'),
                      if (activeProvider == 'elevenlabs') ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, color: Colors.green),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'fish_audio',
                  child: Row(
                    children: [
                      const Text('Fish Audio'),
                      if (activeProvider == 'fish_audio') ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, color: Colors.green),
                      ],
                    ],
                  ),
                ),
              ];
            },
          ),
          // Offline-brain status: green chip = the on-device NLU model is
          // downloaded and Nana understands speech without internet.
          // Tap for details (versions, sizes, how to test).
          IconButton(
            tooltip: 'Offline AI status',
            icon: Icon(
              ref.watch(nluServiceProvider).ready
                  ? Icons.offline_bolt
                  : Icons.offline_bolt_outlined,
              color: ref.watch(nluServiceProvider).ready
                  ? Colors.green.shade600
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: _showOfflineStatus,
          ),
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
                        if (m.offline && m.source != 'quick')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              m.source == 'nlu'
                                  ? '📴 offline — understood by Nana\'s on-device AI'
                                  : '📴 offline basic helper — connect to reach Nana\'s full brain',
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
          // Quick actions — one tap, no reading or typing needed. Each chip
          // speaks its reply aloud and performs the action directly, so a
          // caregiver who cannot read can still drive the whole app.
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _quickChip('🩺', 'Check sickness', () => _handleAction(const NanaReply(
                    'Let us check together, step by step.',
                    action: NanaAction('start_health_check', {}), source: 'quick'))),
                _quickChip('🍲', 'Food', () => _handleAction(const NanaReply(
                    'Let us plan good food that fits your pocket.',
                    action: NanaAction('plan_diet', {}), source: 'quick'))),
                _quickChip('📅', 'My visits', () => _handleAction(const NanaReply(
                    'Let me tell you what is coming.',
                    action: NanaAction('read_today', {}), source: 'quick'))),
                _quickChip('🤰', 'Check-in', () => _handleAction(const NanaReply(
                    'Let us check on you and the baby.',
                    action: NanaAction('start_checkin', {}), source: 'quick'))),
                _quickChip('👶', 'Add baby', () => _handleAction(const NanaReply(
                    'Let us add your child together.',
                    action: NanaAction('open_add_child', {}), source: 'quick'))),
                _quickChip('🗓️', 'Calendar', () => _handleAction(const NanaReply(
                    'Here is your calendar.',
                    action: NanaAction('open_calendar', {}), source: 'quick'))),
              ],
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

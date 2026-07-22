import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/time_context.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../services/ai/ai_config.dart';
import '../command/apply_task_command.dart';
import '../settings/ai_settings_screen.dart';

/// §6 / §19 Saara agent — a conversational surface powered by the user's own AI
/// key. It doesn't just chat: it can **act** — create or change a task — with a
/// confirm before it does. Deterministic core still works with no AI.
class SaaraAgentScreen extends ConsumerStatefulWidget {
  const SaaraAgentScreen({super.key});

  @override
  ConsumerState<SaaraAgentScreen> createState() => _SaaraAgentScreenState();
}

class _Msg {
  _Msg({
    required this.role,
    this.text,
    this.action,
    this.task,
    this.selectedAreaId,
  });
  final String role; // 'user' | 'assistant'
  String? text; // text bubble / result
  Map<String, dynamic>? action; // an actionable command awaiting confirm
  Task? task; // matched existing task (edits)
  String? selectedAreaId; // area chosen for a create
  bool applied = false;
}

class _SaaraAgentScreenState extends ConsumerState<SaaraAgentScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<_Msg> _messages = [];
  bool _sending = false;
  bool _listening = false;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _controller.text = r.recognizedWords);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(aiConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saara'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'AI settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
          ),
        ],
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          if (!config.isConfigured) return const _NeedsKey();
          return Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _Bubble(
                          msg: _messages[i],
                          onApply: () => _apply(_messages[i]),
                          onAreaChanged: (id) =>
                              setState(() => _messages[i].selectedAreaId = id),
                          onCancel: () =>
                              setState(() => _messages[i].applied = true),
                        ),
                      ),
              ),
              if (_sending) const LinearProgressIndicator(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ask, or tell Saara to do something…',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _listening ? Icons.mic : Icons.mic_none,
                                color: _listening
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              onPressed: _toggleListen,
                            ),
                          ),
                          onSubmitted: (_) => _send(config),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : () => _send(config),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send(AiConfig config) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _controller.clear();
      _sending = true;
    });
    _scrollToEnd();
    try {
      final tasks = await ref.read(taskDaoProvider).openTasks();
      final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
      final taskList = jsonEncode([
        for (final t in tasks)
          {
            'id': t.id,
            'title': t.title,
            'when': t.scheduledStart?.toIso8601String(),
          },
      ]);
      final history = _messages
          .where((m) => m.text != null)
          .map((m) => '${m.role == 'user' ? 'User' : 'Saara'}: ${m.text}')
          .toList();
      final recent = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      final now = DateTime.now();
      final prompt =
          'You are Saara, a calm integrity & productivity companion inside the '
          'user\'s app. Today is ${promptNow(now)}. The user\'s open '
          'tasks (JSON): $taskList. Their areas: '
          '[${areas.map((a) => a.displayName).join(', ')}].\n'
          'Conversation so far:\n${recent.join('\n')}\n\n'
          'If the latest user message asks to CREATE or CHANGE a task, reply '
          'ONLY with JSON: {"mode":"act","action":"create"|"reschedule"|'
          '"complete"|"rename"|"delete","taskId":<existing id or null>,"title":'
          '<string or null>,"kind":"task"|"event","datetime":<ISO or null>,'
          '"durationMinutes":<num or null>,"area":<best-fitting area name or '
          'null>,"location":<str or null>,"link":<str or null>,"linkType":'
          '"meeting"|"document"|"other","notes":<str>,"summary":<short human '
          'description>}. Otherwise reply ONLY with JSON: {"mode":"chat",'
          '"reply":<your warm, concise reply>}. JSON only, no other text.';
      final res = await ref
          .read(llmServiceProvider)
          .extractFromTextHealing(config, prompt: prompt);
      // If Saara had to switch to a model the key can actually use, remember it
      // so this only ever happens once.
      if (res.usedModel != null && config.apiKey != null) {
        await ref
            .read(aiConfigStoreProvider)
            .save(
              provider: config.provider,
              apiKey: config.apiKey!,
              model: res.usedModel!,
            );
        ref.invalidate(aiConfigProvider);
      }
      final out = res.text;
      final data = _tryParse(out);
      if (data != null &&
          data['mode'] == 'act' &&
          (data['action']?.toString() ?? 'none') != 'none') {
        final taskId = data['taskId']?.toString();
        final task = taskId == null
            ? null
            : await ref.read(taskDaoProvider).findById(taskId);
        if (data['action'] != 'create' && task == null) {
          _addAssistant(
            "I couldn't find that task — try naming it as it "
            'appears in your list.',
          );
        } else {
          final areaId = data['action'] == 'create'
              ? _matchArea(data['area'], areas)
              : null;
          setState(
            () => _messages.add(
              _Msg(
                role: 'assistant',
                action: data,
                task: task,
                selectedAreaId: areaId,
              ),
            ),
          );
        }
      } else if (data != null && data['reply'] != null) {
        _addAssistant(data['reply'].toString());
      } else {
        _addAssistant(out.trim());
      }
    } catch (e) {
      _addAssistant('⚠️ $e');
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  Map<String, dynamic>? _tryParse(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceAll(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceAll('```', '')
          .trim();
    }
    try {
      final v = json.decode(s);
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  String? _matchArea(Object? name, List<Area> areas) {
    if (name == null) return null;
    final want = name.toString().trim().toLowerCase();
    if (want.isEmpty) return null;
    for (final a in areas) {
      if (a.displayName.toLowerCase().contains(want) ||
          a.baseCategory.name == want) {
        return a.id;
      }
    }
    return null;
  }

  void _addAssistant(String text) {
    setState(() => _messages.add(_Msg(role: 'assistant', text: text)));
  }

  Future<void> _apply(_Msg m) async {
    try {
      final result = await applyTaskCommand(
        ref,
        m.action!,
        task: m.task,
        areaId: m.selectedAreaId,
      );
      setState(() {
        m.applied = true;
        _messages.add(_Msg(role: 'assistant', text: '✓ $result'));
      });
    } catch (e) {
      setState(() {
        m.applied = true;
        _messages.add(_Msg(role: 'assistant', text: '⚠️ $e'));
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _Bubble extends ConsumerWidget {
  const _Bubble({
    required this.msg,
    required this.onApply,
    required this.onAreaChanged,
    required this.onCancel,
  });
  final _Msg msg;
  final VoidCallback onApply;
  final ValueChanged<String?> onAreaChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    if (msg.action != null && !msg.applied) {
      return _ActionCard(
        msg: msg,
        onApply: onApply,
        onAreaChanged: onAreaChanged,
        onCancel: onCancel,
      );
    }
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text ?? '',
          style: TextStyle(color: isUser ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}

class _ActionCard extends ConsumerWidget {
  const _ActionCard({
    required this.msg,
    required this.onApply,
    required this.onAreaChanged,
    required this.onCancel,
  });
  final _Msg msg;
  final VoidCallback onApply;
  final ValueChanged<String?> onAreaChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = msg.action!;
    final action = data['action'].toString();
    final dt = parseAiDateTime(data['datetime']);
    final when = dt == null
        ? ''
        : ' on ${DateFormat('EEE, MMM d · h:mm a').format(dt)}';
    final title = data['title']?.toString() ?? msg.task?.title ?? '';
    final detail = switch (action) {
      'create' =>
        'Create ${data['kind'] == 'event' ? 'event' : 'task'} “$title”$when',
      'reschedule' =>
        dt == null
            ? 'Reschedule “${msg.task?.title}”'
            : 'Move “${msg.task?.title}” to ${DateFormat('EEE, MMM d · h:mm a').format(dt)}',
      'rename' => 'Rename “${msg.task?.title}” to “$title”',
      'complete' => 'Mark “${msg.task?.title}” complete',
      'delete' => 'Delete “${msg.task?.title}”',
      _ => data['summary']?.toString() ?? 'Apply this change',
    };
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const [];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail, style: Theme.of(context).textTheme.bodyLarge),
                if (action == 'create') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: msg.selectedAreaId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      helperText: 'Keeps your integrity score accurate',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      for (final a in areas)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(a.displayName),
                        ),
                    ],
                    onChanged: onAreaChanged,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onApply,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Talk to Saara — ask for help, or just tell it what to do: '
              '“add a gym session tomorrow 7am”, “move the review to Friday”, '
              '“mark standup done”. Saara confirms before it acts.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NeedsKey extends StatelessWidget {
  const _NeedsKey();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_outlined, size: 44),
            const SizedBox(height: 12),
            const Text(
              'Bring your own AI key to chat with Saara.\nYour key stays on '
              'this device; messages go straight to your provider.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('Set up AI key'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/time_context.dart';
import '../common/top_menu.dart';
import '../sync/sync_status_chip.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/ai/ai_config.dart';
import '../command/apply_task_command.dart';
import '../settings/ai_settings_screen.dart';
import '../task_detail/task_detail_screen.dart';

/// Words too common to help narrow a search — dropped so "call with coaches"
/// searches for "call"/"coach", not the noise.
const _searchStop = {
  'with',
  'the',
  'a',
  'an',
  'to',
  'of',
  'for',
  'in',
  'on',
  'at',
  'and',
  'or',
  'my',
  'me',
  'all',
  'any',
  'show',
  'find',
  'list',
  'get',
  'task',
  'tasks',
  'event',
  'events',
  'about',
  'please',
};

/// Shown when the model returns nothing usable, so the chat never goes silent.
const _fallbackReply =
    "I didn't quite catch that. Try naming a task, or ask me to find one — "
    'e.g. "show overdue tasks" or "calls with coaches this week".';

/// Crude singulariser so "coaches"→"coach", "meetings"→"meeting" match.
String _stem(String w) {
  if (w.length > 4 && w.endsWith('es')) return w.substring(0, w.length - 2);
  if (w.length > 3 && w.endsWith('s')) return w.substring(0, w.length - 1);
  return w;
}

/// Split a query phrase into the meaningful, stemmed words to match on.
List<String> _queryStems(String? text) {
  if (text == null) return const [];
  return text
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 2 && !_searchStop.contains(w))
      .map(_stem)
      .toList();
}

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
    this.results,
  });
  final String role; // 'user' | 'assistant'
  String? text; // text bubble / result
  Map<String, dynamic>? action; // an actionable command awaiting confirm
  Task? task; // matched existing task (edits)
  String? selectedAreaId; // area chosen for a create
  List<Task>? results; // a "find" answer — matching tasks to show inline
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
          const SyncStatusChip(),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'AI settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
          ),
          const SaaraTopMenu(),
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
                            hintText:
                                'Ask, find, or tell Saara to do something…',
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
          '"durationMinutes":<num or null>,"repeat":"once"|"daily"|"weekly"|'
          '"monthly","area":<best-fitting area name or '
          'null>,"location":<str or null>,"link":<str or null>,"linkType":'
          '"meeting"|"document"|"other","notes":<str>,"summary":<short human '
          'description>}. For a time RANGE like "7:30 to 8:00", set datetime to '
          'the start and durationMinutes to the span (30). For "every '
          'day/week/month", set repeat accordingly.\n'
          'If it asks to FIND, LIST, SEARCH or SHOW tasks — e.g. "what\'s '
          'overdue in Health", "show done tasks this week", "meetings tomorrow" '
          '— reply ONLY with JSON: {"mode":"find","status":"all"|"open"|"done"|'
          '"missed"|"rejected"|"drafts","type":"all"|"task"|"event","area":'
          '<one of the area names above, or null>,"text":<keywords to match in '
          'the title/notes, or null>,"from":<ISO date or null>,"to":<ISO date '
          'or null>,"overdue":<true if they asked for overdue/late, else '
          'false>,"summary":<short human description of the search>}. The app '
          'runs the search itself, so you do NOT need to list tasks — just the '
          'filters.\n'
          'Otherwise reply ONLY with JSON: {"mode":"chat",'
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
      } else if (data != null && data['mode'] == 'find') {
        final all = await ref.read(taskDaoProvider).allTasks();
        final matches = _runFind(data, areas, all);
        setState(
          () => _messages.add(
            _Msg(
              role: 'assistant',
              text: data['summary']?.toString(),
              results: matches,
            ),
          ),
        );
      } else if (data != null && data['reply'] != null) {
        final reply = data['reply'].toString().trim();
        _addAssistant(reply.isEmpty ? _fallbackReply : reply);
      } else {
        final t = out.trim();
        _addAssistant(t.isEmpty ? _fallbackReply : t);
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

  /// Runs a "find" command's filters over every task — the same dimensions as
  /// the Tasks header filters, so asking Saara and using the filters agree.
  List<Task> _runFind(
    Map<String, dynamic> d,
    List<Area> areas,
    List<Task> all,
  ) {
    final status = (d['status'] ?? 'all').toString();
    final type = (d['type'] ?? 'all').toString();
    final areaId = _matchArea(d['area'], areas);
    final stems = _queryStems(d['text']?.toString());
    final overdue = d['overdue'] == true;
    final from = DateTime.tryParse(d['from']?.toString() ?? '');
    final toRaw = DateTime.tryParse(d['to']?.toString() ?? '');
    final toEnd = toRaw == null
        ? null
        : DateTime(
            toRaw.year,
            toRaw.month,
            toRaw.day,
          ).add(const Duration(days: 1));
    final now = DateTime.now();

    bool ok(Task t) {
      if (t.deletedAt != null) return false;
      switch (status) {
        case 'open':
          if (t.publicationState != PublicationState.released) return false;
          if (t.status != TaskStatus.created &&
              t.status != TaskStatus.started &&
              t.status != TaskStatus.inProgress) {
            return false;
          }
        case 'done':
          if (t.status != TaskStatus.completed) return false;
        case 'missed':
          if (t.status != TaskStatus.missed) return false;
        case 'rejected':
          if (t.status != TaskStatus.rejected) return false;
        case 'drafts':
          if (t.publicationState != PublicationState.draft) return false;
      }
      if (type == 'task' && t.kind == TaskKind.event) return false;
      if (type == 'event' && t.kind != TaskKind.event) return false;
      if (areaId != null && t.areaId != areaId) return false;
      final when = t.scheduledStart ?? t.dueDate;
      if (overdue) {
        if (when == null || !when.isBefore(now)) return false;
        if (t.status == TaskStatus.completed ||
            t.status == TaskStatus.rejected) {
          return false;
        }
      }
      if (from != null &&
          (when == null ||
              when.isBefore(DateTime(from.year, from.month, from.day)))) {
        return false;
      }
      if (toEnd != null && (when == null || !when.isBefore(toEnd))) {
        return false;
      }
      return true;
    }

    int byDate(Task a, Task b) {
      final wa = a.scheduledStart ?? a.dueDate;
      final wb = b.scheduledStart ?? b.dueDate;
      if (wa == null && wb == null) return 0;
      if (wa == null) return 1;
      if (wb == null) return -1;
      return wa.compareTo(wb);
    }

    final hard = all.where(ok).toList();
    if (stems.isEmpty) return hard..sort(byDate);

    // Fuzzy text match: score by how many query words (stemmed, so "coaches"
    // finds "coach") appear in the title/notes. Keep anything that matches at
    // least one — the closest results first — so a near-miss phrase like "call
    // with coaches" still returns the coach calls instead of nothing.
    int score(Task t) {
      final hay = '${t.title} ${t.notes ?? ''}'.toLowerCase();
      return stems.where(hay.contains).length;
    }

    return hard.where((t) => score(t) > 0).toList()..sort((a, b) {
      final s = score(b).compareTo(score(a));
      return s != 0 ? s : byDate(a, b);
    });
  }

  void _addAssistant(String text) {
    setState(() => _messages.add(_Msg(role: 'assistant', text: text)));
  }

  Future<void> _apply(_Msg m) async {
    try {
      final res = await applyTaskCommand(
        ref,
        m.action!,
        task: m.task,
        areaId: m.selectedAreaId,
      );
      // Show the task Saara just made/changed as a tappable row, so you can
      // open it to verify or refine what it understood.
      final affected = res.taskId == null
          ? null
          : await ref.read(taskDaoProvider).findById(res.taskId!);
      setState(() {
        m.applied = true;
        _messages.add(
          _Msg(
            role: 'assistant',
            text: '✓ ${res.message}',
            results: affected == null ? null : [affected],
          ),
        );
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
    if (msg.results != null) {
      return _ResultsCard(summary: msg.text, tasks: msg.results!);
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

/// A "find" answer: Saara's one-line summary and the matching tasks, each
/// tappable straight through to its detail. The search itself ran locally over
/// the same fields as the Tasks filters.
class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.summary, required this.tasks});
  final String? summary;
  final List<Task> tasks;

  static const _cap = 20; // don't flood the chat; the Tasks tab is for browsing

  String _sub(Task t) {
    final w = t.scheduledStart ?? t.dueDate;
    return [
      if (w != null) DateFormat('MMM d').format(w),
      t.status.name,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final header = (summary != null && summary!.trim().isNotEmpty)
        ? summary!.trim()
        : (tasks.isEmpty
              ? 'No matching tasks.'
              : 'Found ${tasks.length} task${tasks.length == 1 ? '' : 's'}');
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(header, style: Theme.of(context).textTheme.titleSmall),
                if (tasks.isNotEmpty) const SizedBox(height: 4),
                for (final t in tasks.take(_cap))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      t.kind == TaskKind.event
                          ? Icons.event
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: scheme.primary,
                    ),
                    title: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_sub(t)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(taskId: t.id),
                      ),
                    ),
                  ),
                if (tasks.length > _cap)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Text(
                      '+ ${tasks.length - _cap} more — open the Tasks tab to browse them all',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
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
    // Surface the parsed duration and repeat on the create card, so what Saara
    // understood is verifiable *before* you apply it.
    final durMin = data['durationMinutes'];
    final durLabel = durMin is num ? ' · ${durMin.toInt()} min' : '';
    final repeat = data['repeat']?.toString();
    final repeatLabel = (repeat != null && repeat != 'once' && repeat != 'null')
        ? ', repeats $repeat'
        : '';
    final detail = switch (action) {
      'create' =>
        'Create ${data['kind'] == 'event' ? 'event' : 'task'} “$title”$when$durLabel$repeatLabel',
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

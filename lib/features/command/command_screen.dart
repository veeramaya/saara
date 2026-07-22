import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/time_context.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/geofence_service.dart';
import '../../services/notification_service.dart';

/// §19 natural-language command — say or type what you want and Saara does it:
/// **create** a new task/event ("add a dentist appointment Friday 4pm"),
/// **reschedule / rename / complete / delete** an existing one ("move gym to
/// tomorrow", "mark standup done"). Every change is confirmed before applying,
/// and syncs to Google.
class CommandScreen extends ConsumerStatefulWidget {
  const CommandScreen({super.key});

  @override
  ConsumerState<CommandScreen> createState() => _CommandScreenState();
}

class _CommandScreenState extends ConsumerState<CommandScreen> {
  final _input = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _pending;
  Task? _pendingTask; // null for a create
  String? _selectedAreaId; // area chosen for a create (keeps metrics accurate)

  String? _matchArea(String? name, List<Area> areas) {
    if (name == null || name.trim().isEmpty) return null;
    final want = name.trim().toLowerCase();
    final m = areas.firstWhereOrNull(
      (a) =>
          a.displayName.toLowerCase().contains(want) ||
          a.baseCategory.name == want,
    );
    return m?.id;
  }

  @override
  void dispose() {
    _input.dispose();
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
    if (!ok) {
      setState(() => _error = 'Speech recognition unavailable.');
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (mounted) setState(() => _input.text = r.recognizedWords);
      },
    );
  }

  Future<void> _interpret() async {
    final cmd = _input.text.trim();
    if (cmd.isEmpty) return;
    final config = await ref.read(aiConfigProvider.future);
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      setState(() => _error = 'Add an AI key in Settings → Saara AI.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _pending = null;
      _pendingTask = null;
    });
    final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
    try {
      final tasks = await ref.read(taskDaoProvider).openTasks();
      final taskList = jsonEncode([
        for (final t in tasks)
          {
            'id': t.id,
            'title': t.title,
            'when': t.scheduledStart?.toIso8601String(),
          },
      ]);
      final areaNames = areas.map((a) => a.displayName).join(', ');
      final now = DateTime.now();
      final prompt =
          'Today is ${promptNow(now)}. The user gave '
          'a command to manage their tasks. Their existing open tasks (JSON): '
          '$taskList.\nTheir life areas are: [$areaNames].\nReturn ONLY JSON: '
          '{"action":"create"|"reschedule"|"complete"|"rename"|"delete"|"none",'
          '"taskId":<id of the matching existing task, or null for create>,'
          '"title":<new/created title or null>,"kind":"task"|"event",'
          '"datetime":<ISO-8601 or null>,"durationMinutes":<number or null>,'
          '"area":<the ONE area name from the list above that best fits this '
          'task; pick the closest — only use null if truly none applies>,'
          '"location":<string or null>,"link":<string or null>,"linkType":'
          '"meeting"|"document"|"other","notes":<string>,"summary":<short human '
          'description>}. Use "create" for a brand-new task/event ("add…", '
          '"remind me to…", "schedule…"). Use reschedule/complete/rename/delete '
          'for an existing task, matched by meaning. Use kind "event" when a '
          'specific clock time/appointment is given. Resolve relative dates. If '
          'unclear, action="none". Command: "$cmd"';
      final out = await ref
          .read(llmServiceProvider)
          .extractFromText(config, prompt: prompt);
      final data = _parse(out);
      final action = (data['action'] ?? 'none').toString();
      if (action == 'none') {
        setState(
          () => _error =
              'I couldn\'t turn that into an action. Try “add …”, “move …”, or '
              '“mark … done”.',
        );
        return;
      }
      if (action == 'create') {
        setState(() {
          _pending = data;
          _pendingTask = null;
          _selectedAreaId = _matchArea(data['area']?.toString(), areas);
        });
        return;
      }
      // existing-task actions need a match
      final taskId = data['taskId']?.toString();
      final task = taskId == null
          ? null
          : await ref.read(taskDaoProvider).findById(taskId);
      if (task == null) {
        setState(() => _error = 'I couldn\'t find that task.');
        return;
      }
      setState(() {
        _pending = data;
        _pendingTask = task;
      });
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _parse(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceAll(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceAll('```', '')
          .trim();
    }
    return json.decode(s) as Map<String, dynamic>;
  }

  Future<void> _apply() async {
    final data = _pending!;
    final task = _pendingTask;
    final action = data['action'].toString();
    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now();
    DateTime? affectedDay;
    try {
      switch (action) {
        case 'create':
          affectedDay = await _create(data, now);
          break;
        case 'reschedule':
          final dt = parseAiDateTime(data['datetime']);
          if (dt == null) throw 'No valid date in the command.';
          await (db.update(
            db.tasks,
          )..where((t) => t.id.equals(task!.id))).write(
            TasksCompanion(
              scheduledStart: Value(dt),
              dueDate: Value(dt),
              updatedAt: Value(now),
            ),
          );
          if (task!.reminderOffsets != null &&
              task.reminderOffsets!.isNotEmpty) {
            await NotificationService.instance.scheduleTaskReminder(
              taskId: task.id,
              title: task.title,
              when: dt,
              offsetsMinutes: task.reminderOffsets!,
            );
          }
          affectedDay = dt;
          break;
        case 'rename':
          final title = data['title']?.toString().trim();
          if (title == null || title.isEmpty) throw 'No new title given.';
          await (db.update(
            db.tasks,
          )..where((t) => t.id.equals(task!.id))).write(
            TasksCompanion(title: Value(title), updatedAt: Value(now)),
          );
          break;
        case 'complete':
          final t = task!;
          await ref.read(taskServiceProvider).complete(t);
          await NotificationService.instance.cancelTaskReminder(t.id);
          await SaaraGeofence.remove(t.id);
          break;
        case 'delete':
          final t = task!;
          await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
            TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
          );
          await NotificationService.instance.cancelTaskReminder(t.id);
          await SaaraGeofence.remove(t.id);
          break;
      }
      _afterMutation(task?.scheduledStart, affectedDay, now);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Done ✓')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  Future<DateTime?> _create(Map<String, dynamic> data, DateTime now) async {
    final title = data['title']?.toString().trim() ?? '';
    if (title.isEmpty) throw 'No title for the new task.';
    final dt = parseAiDateTime(data['datetime']);
    // An event is a time-blocked calendar entry; without a time it's a to-do.
    final kind = (data['kind'] == 'event' && dt != null)
        ? TaskKind.event
        : TaskKind.task;
    final areaId = _selectedAreaId; // user-confirmed area (keeps metrics right)
    String? meeting, doc;
    final link = data['link']?.toString();
    if (link != null && link.isNotEmpty) {
      if (data['linkType'] == 'meeting') {
        meeting = link;
      } else {
        doc = link;
      }
    }
    final dur = data['durationMinutes'];
    final notes = data['notes']?.toString().trim();
    final loc = data['location']?.toString().trim();
    await ref
        .read(taskDaoProvider)
        .insertTask(
          TasksCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            title: title,
            kind: Value(kind),
            scheduledStart: Value(dt),
            dueDate: Value(dt),
            durationMin: Value(dur is num ? dur.toInt() : null),
            areaId: Value(areaId),
            locationName: Value(loc == null || loc.isEmpty ? null : loc),
            meetingLink: Value(meeting),
            documentLink: Value(doc),
            notes: Value(notes == null || notes.isEmpty ? null : notes),
            source: const Value(TaskSource.conversation),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return dt;
  }

  void _afterMutation(DateTime? oldWhen, DateTime? newWhen, DateTime now) {
    if (_pendingTask != null) {
      ref.invalidate(taskByIdProvider(_pendingTask!.id));
    }
    for (final d in {now, oldWhen, newWhen}) {
      if (d != null) {
        ref.invalidate(tasksForDayProvider(DateTime(d.year, d.month, d.day)));
        ref.invalidate(tasksBetweenProvider); // calendar views
      }
    }
    ref.invalidate(scheduleConflictsProvider);
    unawaited(() async {
      try {
        if (await ref.read(googleSyncServiceProvider).isConnected()) {
          await ref.read(googleSyncOrchestratorProvider).syncAll();
        }
      } catch (_) {}
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tell Saara')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Say or type what you want, e.g. “add a dentist appointment '
            'Friday 4pm”, “move the gym to tomorrow morning”, “mark standup '
            'done”, “cancel the dinner”.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _input,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tell Saara…',
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
            onSubmitted: (_) => _interpret(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('Interpret'),
            onPressed: _busy ? null : _interpret,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (_pending != null) ...[
            const SizedBox(height: 20),
            _ConfirmCard(
              task: _pendingTask,
              data: _pending!,
              selectedAreaId: _selectedAreaId,
              onAreaChanged: (id) => setState(() => _selectedAreaId = id),
              onApply: _busy ? null : _apply,
              onCancel: () => setState(() {
                _pending = null;
                _pendingTask = null;
                _selectedAreaId = null;
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmCard extends ConsumerWidget {
  const _ConfirmCard({
    required this.task,
    required this.data,
    required this.selectedAreaId,
    required this.onAreaChanged,
    required this.onApply,
    required this.onCancel,
  });
  final Task? task;
  final Map<String, dynamic> data;
  final String? selectedAreaId;
  final ValueChanged<String?> onAreaChanged;
  final VoidCallback? onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = data['action'].toString();
    final dt = parseAiDateTime(data['datetime']);
    final when = dt == null
        ? ''
        : ' on ${DateFormat('EEE, MMM d · h:mm a').format(dt)}';
    final title = data['title']?.toString() ?? task?.title ?? '';
    final detail = switch (action) {
      'create' =>
        'Create ${data['kind'] == 'event' ? 'event' : 'task'} “$title”$when',
      'reschedule' =>
        dt == null
            ? 'Reschedule “${task?.title}”'
            : 'Move “${task?.title}” to ${DateFormat('EEE, MMM d · h:mm a').format(dt)}',
      'rename' => 'Rename “${task?.title}” to “$title”',
      'complete' => 'Mark “${task?.title}” complete',
      'delete' => 'Delete “${task?.title}”',
      _ => data['summary']?.toString() ?? 'Apply this change',
    };
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(action),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('Confirm', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            Text(detail, style: Theme.of(context).textTheme.bodyLarge),
            // Categorise new tasks so they count toward an Area's integrity.
            if (action == 'create') ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: selectedAreaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  helperText: 'Keeps your integrity score accurate',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final a in areas)
                    DropdownMenuItem(value: a.id, child: Text(a.displayName)),
                ],
                onChanged: onAreaChanged,
              ),
              if (selectedAreaId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'No area — this won\'t count toward any area\'s score. '
                    'Pick one above.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onCancel, child: const Text('Cancel')),
                const SizedBox(width: 8),
                FilledButton(onPressed: onApply, child: const Text('Apply')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String a) => switch (a) {
    'create' => Icons.add_task,
    'reschedule' => Icons.schedule,
    'rename' => Icons.edit,
    'complete' => Icons.check_circle,
    'delete' => Icons.delete_outline,
    _ => Icons.auto_awesome,
  };
}

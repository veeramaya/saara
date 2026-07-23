import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/time_context.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// One action item proposed by the AI from a meeting summary / MoM (§6/§11).
/// Mutable — the review screen lets the user edit before creating.
class ExtractedItem {
  ExtractedItem({
    required this.title,
    this.kind = TaskKind.task,
    this.datetime,
    this.durationMin,
    this.area,
    this.location,
    this.link,
    this.linkType,
    this.notes = '',
    this.selected = true,
  });

  String title;
  TaskKind kind;
  DateTime? datetime;
  int? durationMin;
  String? area;
  String? location;
  String? link;
  String? linkType;
  String notes;
  bool selected;

  static ExtractedItem? fromJson(Object? o) {
    if (o is! Map) return null;
    final title = (o['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;
    return ExtractedItem(
      title: title,
      kind: o['kind'] == 'event' ? TaskKind.event : TaskKind.task,
      datetime: o['datetime'] is String ? parseAiDateTime(o['datetime']) : null,
      durationMin: (o['durationMinutes'] is num)
          ? (o['durationMinutes'] as num).toInt()
          : null,
      area: (o['area'] as String?)?.trim(),
      location: (o['location'] as String?)?.trim(),
      link: (o['link'] as String?)?.trim(),
      linkType: (o['linkType'] as String?)?.toLowerCase(),
      notes: (o['notes'] as String?)?.trim() ?? '',
    );
  }
}

/// §11 use-case: a meeting summary / minutes / message with several action
/// items → the AI proposes each as a task/event; the user reviews (edit, tick)
/// and batch-creates. The source image is attached to each.
class ReviewItemsScreen extends ConsumerStatefulWidget {
  const ReviewItemsScreen({
    super.key,
    required this.imagePath,
    this.parentEventId,
    this.fallbackAreaId,
  });
  final String imagePath;

  /// When set, every created item is hung under this event (§4) and defaults to
  /// [fallbackAreaId] (the event's area) when the AI didn't name an area.
  final String? parentEventId;
  final String? fallbackAreaId;

  @override
  ConsumerState<ReviewItemsScreen> createState() => _ReviewItemsScreenState();
}

class _ReviewItemsScreenState extends ConsumerState<ReviewItemsScreen> {
  bool _loading = true;
  bool _creating = false;
  String? _error;
  final List<ExtractedItem> _items = [];
  final List<TextEditingController> _titleCtrls = [];

  @override
  void initState() {
    super.initState();
    _extract();
  }

  @override
  void dispose() {
    for (final c in _titleCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  String _prompt() {
    final now = DateTime.now();
    return 'Today is ${promptNow(now)}. This image '
        'is a meeting summary, minutes of meeting, or a message that contains '
        'MULTIPLE action items or to-dos. Extract EVERY distinct action item. '
        'Resolve any relative date ("by Friday", "in 2 days", "next week") to an '
        'absolute ISO-8601 datetime. Return ONLY JSON: '
        '{"items":[{"title":short string,"kind":"task"|"event",'
        '"datetime":ISO-8601 or null,"durationMinutes":number|null,'
        '"area":string|null,"location":string|null,"link":string|null,'
        '"linkType":"meeting"|"document"|"other","notes":string}]}. '
        'If there are no clear action items, return {"items":[]}. $kPromptTimeRule JSON only.';
  }

  Future<void> _extract() async {
    try {
      final config = await ref.read(aiConfigProvider.future);
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Add a Gemini key in Settings → Saara AI to read summaries.';
        });
        return;
      }
      final bytes = await File(widget.imagePath).readAsBytes();
      final mime = widget.imagePath.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final out = await ref
          .read(llmServiceProvider)
          .extractFromImage(
            config,
            imageBytes: bytes,
            mimeType: mime,
            prompt: _prompt(),
          );
      final parsed = _parse(out);
      if (!mounted) return;
      setState(() {
        _items.addAll(parsed);
        for (final it in parsed) {
          _titleCtrls.add(TextEditingController(text: it.title));
        }
        _loading = false;
        if (parsed.isEmpty) _error = 'No action items found in the image.';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Extraction failed: $e';
        });
      }
    }
  }

  List<ExtractedItem> _parse(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceAll(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceAll('```', '')
          .trim();
    }
    final data = json.decode(s);
    final items = (data is Map ? data['items'] : data) as List? ?? const [];
    return items
        .map(ExtractedItem.fromJson)
        .whereType<ExtractedItem>()
        .toList();
  }

  Future<void> _pickDate(int i) async {
    final it = _items[i];
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: it.datetime ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(it.datetime ?? now),
    );
    setState(
      () => it.datetime = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _create() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i].title = _titleCtrls[i].text.trim();
    }
    final selected = _items
        .where((i) => i.selected && i.title.isNotEmpty)
        .toList();
    if (selected.isEmpty) return;
    setState(() => _creating = true);
    final uuid = ref.read(uuidProvider);
    final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
    final now = DateTime.now();

    for (final it in selected) {
      String? areaId;
      if (it.area != null && it.area!.isNotEmpty) {
        final want = it.area!.toLowerCase();
        final m = areas.firstWhereOrNull(
          (a) =>
              a.displayName.toLowerCase().contains(want) ||
              a.baseCategory.name == want,
        );
        areaId = m?.id;
      }
      // Meeting action items inherit the event's area when none was detected.
      areaId ??= widget.fallbackAreaId;
      String? meeting, doc;
      if (it.link != null && it.link!.isNotEmpty) {
        if (it.linkType == 'meeting') {
          meeting = it.link;
        } else {
          doc = it.link;
        }
      }
      // The user has already reviewed and chosen these items, so keeping one is
      // committing to it — released, and recorded in the ledger via create().
      await ref
          .read(taskServiceProvider)
          .create(
            TasksCompanion.insert(
              id: uuid.v4(),
              title: it.title,
              kind: Value(it.kind),
              scheduledStart: Value(it.datetime),
              dueDate: Value(it.datetime),
              durationMin: Value(it.durationMin),
              locationName: Value(it.location),
              meetingLink: Value(meeting),
              documentLink: Value(doc),
              areaId: Value(areaId),
              parentEventId: Value(widget.parentEventId),
              notes: Value(it.notes.isEmpty ? null : it.notes),
              attachmentImagePath: Value(widget.imagePath),
              source: const Value(TaskSource.conversation),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    if (widget.parentEventId != null) {
      ref.invalidate(childTasksForEventProvider(widget.parentEventId!));
      ref.invalidate(childTaskCountsProvider);
    }
    // Push new items to Google promptly, if connected.
    unawaited(() async {
      try {
        if (await ref.read(googleSyncServiceProvider).isConnected()) {
          await ref.read(googleSyncOrchestratorProvider).syncAll();
        }
      } catch (_) {}
    }());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created ${selected.length} '
            'item${selected.length == 1 ? '' : 's'}',
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.where((i) => i.selected).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Review action items')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
              itemCount: _items.length,
              itemBuilder: (_, i) => _itemCard(i),
            ),
      bottomNavigationBar: (_loading || _items.isEmpty)
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: _creating || count == 0 ? null : _create,
                child: _creating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Create $count '
                        'item${count == 1 ? '' : 's'}',
                      ),
              ),
            ),
    );
  }

  Widget _itemCard(int i) {
    final it = _items[i];
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: it.selected,
              onChanged: (v) => setState(() => it.selected = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrls[i],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          it.kind == TaskKind.event ? 'Event' : 'Task',
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      InkWell(
                        onTap: () => _pickDate(i),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              it.datetime == null
                                  ? 'Set date'
                                  : DateFormat(
                                      'MMM d · h:mm a',
                                    ).format(it.datetime!),
                              style: TextStyle(color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                      if (it.area != null && it.area!.isNotEmpty)
                        Text(
                          '· ${it.area}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

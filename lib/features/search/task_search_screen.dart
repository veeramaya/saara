import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../home/home_screen.dart' show AddTaskFab;
import '../task_detail/task_detail_screen.dart';

/// §7 global Tasks list + search. Browse every task/event across statuses,
/// filter (open / done / missed…), search intelligently (free text, `has:`
/// tokens, natural dates), sort, and tap through to edit or see attachments.
enum _StatusFilter {
  all,
  open,
  done,
  missed,
  rejected,
  events,
  archived,
  deleted,
}

enum _SortBy { dateAsc, dateDesc, titleAz, updatedDesc, status }

/// A completed task older than a year is "archived" — kept as history but out of
/// the way. Age-based, so there's no separate storage or migration (§7).
bool _isArchived(Task t, DateTime cutoff) =>
    t.status == TaskStatus.completed &&
    (t.completedAt ?? t.updatedAt).isBefore(cutoff);

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Turns a natural date phrase into a `[start, end)` day range, or null if the
/// query isn't a date. Guarded so plain-text/number searches aren't misread as
/// dates (e.g. "680" or "bharath" stay text searches).
(DateTime, DateTime)? _asDateRange(String q) {
  final now = DateTime.now();
  switch (q) {
    case 'today':
      final s = _startOfDay(now);
      return (s, s.add(const Duration(days: 1)));
    case 'tomorrow':
      final s = _startOfDay(now.add(const Duration(days: 1)));
      return (s, s.add(const Duration(days: 1)));
    case 'yesterday':
      final s = _startOfDay(now.subtract(const Duration(days: 1)));
      return (s, s.add(const Duration(days: 1)));
    case 'this week':
    case 'week':
      final s = _startOfDay(now.subtract(Duration(days: now.weekday - 1)));
      return (s, s.add(const Duration(days: 7)));
  }
  // ISO date only when it really looks like one (avoids "2026" → year-start).
  if (RegExp(r'^\d{4}-\d{1,2}(-\d{1,2})?$').hasMatch(q)) {
    final iso = DateTime.tryParse(q.length == 7 ? '$q-01' : q);
    if (iso != null) {
      final s = _startOfDay(iso);
      return (s, s.add(const Duration(days: 1)));
    }
  }
  // "jul 20" / "20 jul" — only try if a month name is present.
  if (RegExp(r'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec').hasMatch(q)) {
    for (final fmt in const ['MMM d', 'd MMM', 'MMMM d', 'd MMMM']) {
      try {
        final p = DateFormat(fmt).parseLoose(q);
        final s = DateTime(now.year, p.month, p.day);
        return (s, s.add(const Duration(days: 1)));
      } catch (_) {}
    }
  }
  return null;
}

class TaskSearchScreen extends ConsumerStatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  ConsumerState<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends ConsumerState<TaskSearchScreen> {
  final _search = TextEditingController();
  _StatusFilter _filter = _StatusFilter.all;
  _SortBy _sort = _SortBy.dateAsc;
  Set<String> _withCaptures = const {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesFilter(Task t, DateTime cutoff) {
    final archived = _isArchived(t, cutoff);
    switch (_filter) {
      case _StatusFilter.all:
        return !archived;
      case _StatusFilter.open:
        return !archived &&
            (t.status == TaskStatus.created ||
                t.status == TaskStatus.started ||
                t.status == TaskStatus.inProgress);
      case _StatusFilter.done:
        return !archived && t.status == TaskStatus.completed;
      case _StatusFilter.missed:
        return !archived && t.status == TaskStatus.missed;
      case _StatusFilter.rejected:
        return !archived && t.status == TaskStatus.rejected;
      case _StatusFilter.events:
        return !archived && t.kind == TaskKind.event;
      case _StatusFilter.archived:
        return archived;
      case _StatusFilter.deleted:
        return true; // the deleted provider already scopes these
    }
  }

  bool _matchesQuery(Task t, String q) {
    if (q.isEmpty) return true;

    // Structured tokens: has:link / has:doc / has:meeting / has:image /
    // has:place / has:capture (media recorded against the task).
    if (q.startsWith('has:')) {
      switch (q.substring(4)) {
        case 'link':
        case 'links':
          return t.documentLink != null || t.meetingLink != null;
        case 'doc':
        case 'document':
          return t.documentLink != null;
        case 'meeting':
        case 'call':
          return t.meetingLink != null;
        case 'image':
        case 'photo':
          return t.attachmentImagePath != null;
        case 'place':
        case 'location':
          return t.locationName != null;
        case 'capture':
        case 'media':
          return _withCaptures.contains(t.id);
        default:
          return false;
      }
    }

    // "overdue" / "late": past-due and still open.
    if (q == 'overdue' || q == 'late') {
      final when = t.scheduledStart ?? t.dueDate;
      return when != null &&
          when.isBefore(DateTime.now()) &&
          t.status != TaskStatus.completed &&
          t.status != TaskStatus.rejected;
    }

    // Natural date queries ("today", "jul 20", "2026-07-20"…).
    final range = _asDateRange(q);
    if (range != null) {
      final when = t.scheduledStart ?? t.dueDate;
      return when != null &&
          !when.isBefore(range.$1) &&
          when.isBefore(range.$2);
    }

    // Free text across every human field, including links.
    return t.title.toLowerCase().contains(q) ||
        (t.notes?.toLowerCase().contains(q) ?? false) ||
        (t.locationName?.toLowerCase().contains(q) ?? false) ||
        (t.documentLink?.toLowerCase().contains(q) ?? false) ||
        (t.meetingLink?.toLowerCase().contains(q) ?? false);
  }

  int _compare(Task a, Task b) {
    DateTime? wa() => a.scheduledStart ?? a.dueDate;
    DateTime? wb() => b.scheduledStart ?? b.dueDate;
    // Undated items sort last for date sorts.
    int byDate(bool asc) {
      final da = wa(), db = wb();
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return asc ? da.compareTo(db) : db.compareTo(da);
    }

    return switch (_sort) {
      _SortBy.dateAsc => byDate(true),
      _SortBy.dateDesc => byDate(false),
      _SortBy.titleAz => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      _SortBy.updatedDesc => b.updatedAt.compareTo(a.updatedAt),
      _SortBy.status => a.status.index.compareTo(b.status.index),
    };
  }

  String _sortLabel(_SortBy s) => switch (s) {
    _SortBy.dateAsc => 'Date ↑ (soonest)',
    _SortBy.dateDesc => 'Date ↓ (latest)',
    _SortBy.titleAz => 'Title A–Z',
    _SortBy.updatedDesc => 'Recently updated',
    _SortBy.status => 'Status',
  };

  @override
  Widget build(BuildContext context) {
    final deleted = _filter == _StatusFilter.deleted;
    final async = deleted
        ? ref.watch(deletedTasksProvider)
        : ref.watch(allTasksProvider);
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const [];
    final areaName = {for (final a in areas) a.id: a.displayName};
    _withCaptures =
        ref.watch(taskIdsWithCapturesProvider).valueOrNull ?? const {};
    final childCounts =
        ref.watch(childTaskCountsProvider).valueOrNull ?? const {};
    final q = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All tasks'),
        actions: [
          PopupMenuButton<_SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => [
              for (final s in _SortBy.values)
                PopupMenuItem(value: s, child: Text(_sortLabel(s))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Search tips',
            onPressed: _showSearchTips,
          ),
        ],
      ),
      // §7 create from wherever you are, not only from Today.
      floatingActionButton: const AddTaskFab(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'title · "today" · "jul 20" · has:link · overdue',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search.clear()),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final f in _StatusFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_label(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (all) {
                final cutoff = DateTime.now().subtract(
                  const Duration(days: 365),
                );
                final items =
                    all
                        .where(
                          (t) =>
                              _matchesFilter(t, cutoff) && _matchesQuery(t, q),
                        )
                        .toList()
                      ..sort(_compare);
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No matching tasks.'),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _TaskRow(
                    task: items[i],
                    areaName: areaName[items[i].areaId],
                    hasCapture: _withCaptures.contains(items[i].id),
                    actionItems: childCounts[items[i].id] ?? 0,
                    onRestore: deleted ? () => _restore(items[i]) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _label(_StatusFilter f) => switch (f) {
    _StatusFilter.all => 'All',
    _StatusFilter.open => 'Open',
    _StatusFilter.done => 'Done',
    _StatusFilter.missed => 'Missed',
    _StatusFilter.rejected => 'Rejected',
    _StatusFilter.events => 'Events',
    _StatusFilter.archived => 'Archived',
    _StatusFilter.deleted => 'Deleted',
  };

  void _showSearchTips() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smart search'),
        content: const SingleChildScrollView(
          child: Text(
            'Type freely to match a task\'s title, notes, place, or links.\n\n'
            'Dates:\n'
            '  • today · tomorrow · yesterday · this week\n'
            '  • jul 20 · 20 jul · 2026-07-20\n'
            '  • overdue — past-due and still open\n\n'
            'Filters (type exactly):\n'
            '  • has:link · has:doc · has:meeting\n'
            '  • has:image · has:place · has:capture\n\n'
            'Use the ⇅ Sort menu for order (date, title, status, recent). '
            'For anything more free-form, just ask in the Saara tab.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(Task t) async {
    await ref.read(taskDaoProvider).restoreTask(t.id);
    ref.invalidate(deletedTasksProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    final now = DateTime.now();
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
    ref.invalidate(tasksBetweenProvider); // calendar views
    // Re-push to Google as a fresh item.
    () async {
      try {
        if (await ref.read(googleSyncServiceProvider).isConnected()) {
          await ref.read(googleSyncOrchestratorProvider).syncAll();
        }
      } catch (_) {}
    }();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restored “${t.title}”')));
    }
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    this.areaName,
    this.hasCapture = false,
    this.actionItems = 0,
    this.onRestore,
  });
  final Task task;
  final String? areaName;
  final bool hasCapture;
  final int actionItems;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = task.scheduledStart ?? task.dueDate;
    final done = task.status == TaskStatus.completed;
    final isEvent = task.kind == TaskKind.event;
    final color = switch (task.status) {
      TaskStatus.completed => Colors.green,
      TaskStatus.missed => scheme.error,
      TaskStatus.rejected => scheme.error,
      _ => isEvent ? scheme.tertiary : scheme.primary,
    };
    final bits = <String>[];
    if (when != null) bits.add(DateFormat('MMM d').format(when));
    bits.add(task.status.name);
    if (areaName != null) bits.add(areaName!);
    if (actionItems > 0) {
      bits.add('$actionItems action item${actionItems == 1 ? '' : 's'}');
    }
    final trailingIcons = <Widget>[];
    if (task.documentLink != null || task.meetingLink != null) {
      trailingIcons.add(
        Icon(Icons.link, size: 16, color: scheme.onSurfaceVariant),
      );
    }
    if (task.attachmentImagePath != null) {
      trailingIcons.add(
        Icon(Icons.image_outlined, size: 16, color: scheme.onSurfaceVariant),
      );
    }
    if (hasCapture) {
      trailingIcons.add(
        Icon(
          Icons.perm_media_outlined,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
      );
    }
    return ListTile(
      leading: Icon(
        isEvent
            ? Icons.event
            : (done ? Icons.check_circle : Icons.radio_button_unchecked),
        color: color,
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(bits.join(' · ')),
      trailing: onRestore != null
          ? TextButton.icon(
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Restore'),
              onPressed: onRestore,
            )
          : (trailingIcons.isEmpty
                ? null
                : Wrap(spacing: 4, children: trailingIcons)),
      onTap: onRestore != null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TaskDetailScreen(taskId: task.id),
              ),
            ),
    );
  }
}

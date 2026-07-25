import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../common/top_menu.dart';
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
  drafts,
  archived,
  deleted,
}

/// Task vs event is a real distinction (Google Tasks vs Calendar, due-point vs
/// time-block) — kept explicit, and filterable here.
enum _TypeFilter { all, tasks, events }

/// The column a user sorts by; direction (asc/desc) is a separate toggle, the
/// way a spreadsheet header works.
enum _SortField { date, title, status, updated }

/// Sentinel for the Area filter meaning "no area set" — the Unclassified bucket.
const _unclassifiedArea = '__unclassified__';

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
  _TypeFilter _type = _TypeFilter.all;
  DateTimeRange? _dateRange; // null = any date; else an inclusive [from, to]
  String? _area; // null = any area; _unclassifiedArea = none; else an area id
  String? _source; // null = any; else 'Desktop' / 'Mobile' / 'Google'
  Map<String, String> _origins = const {}; // taskId → origin label
  _SortField _sortField = _SortField.date;
  bool _sortAsc = true;
  Set<String> _withCaptures = const {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// All four filters must pass. Split apart so Status, Type, Date and Area are
  /// independent — a user can ask for "open events in Health this week".
  bool _matches(Task t, DateTime cutoff) =>
      _matchesStatus(t, cutoff) &&
      _matchesType(t) &&
      _matchesDate(t) &&
      _matchesArea(t) &&
      _matchesSource(t);

  bool _matchesSource(Task t) => _source == null || _origins[t.id] == _source;

  bool _matchesStatus(Task t, DateTime cutoff) {
    final archived = _isArchived(t, cutoff);
    switch (_filter) {
      case _StatusFilter.all:
        return !archived;
      case _StatusFilter.drafts:
        return t.publicationState == PublicationState.draft;
      case _StatusFilter.open:
        return !archived &&
            t.publicationState == PublicationState.released &&
            (t.status == TaskStatus.created ||
                t.status == TaskStatus.started ||
                t.status == TaskStatus.inProgress);
      case _StatusFilter.done:
        return !archived && t.status == TaskStatus.completed;
      case _StatusFilter.missed:
        return !archived && t.status == TaskStatus.missed;
      case _StatusFilter.rejected:
        return !archived && t.status == TaskStatus.rejected;
      case _StatusFilter.archived:
        return archived;
      case _StatusFilter.deleted:
        return true; // the deleted provider already scopes these
    }
  }

  bool _matchesType(Task t) => switch (_type) {
    _TypeFilter.all => true,
    _TypeFilter.tasks => t.kind != TaskKind.event,
    _TypeFilter.events => t.kind == TaskKind.event,
  };

  bool _matchesArea(Task t) {
    if (_area == null) return true;
    if (_area == _unclassifiedArea) return t.areaId == null;
    return t.areaId == _area;
  }

  bool _matchesDate(Task t) {
    final range = _dateRange;
    if (range == null) return true;
    final when = t.scheduledStart ?? t.dueDate;
    if (when == null) return false;
    // Inclusive of both end days: [from 00:00, to 24:00).
    final from = _startOfDay(range.start);
    final to = _startOfDay(range.end).add(const Duration(days: 1));
    return !when.isBefore(from) && when.isBefore(to);
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
    // Date sorts keep undated items last in *both* directions — an item with no
    // date isn't "newest" or "oldest", it's simply unscheduled.
    if (_sortField == _SortField.date) {
      final da = a.scheduledStart ?? a.dueDate;
      final db = b.scheduledStart ?? b.dueDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      final c = da.compareTo(db);
      return _sortAsc ? c : -c;
    }
    final base = switch (_sortField) {
      _SortField.title => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
      _SortField.status => a.status.index.compareTo(b.status.index),
      _SortField.updated => a.updatedAt.compareTo(b.updatedAt),
      _SortField.date => 0, // handled above
    };
    return _sortAsc ? base : -base;
  }

  String _sortLabel(_SortField f) => switch (f) {
    _SortField.date => 'Date',
    _SortField.title => 'Title',
    _SortField.status => 'Status',
    _SortField.updated => 'Updated',
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
    _origins = ref.watch(taskOriginsProvider).valueOrNull ?? const {};
    final childCounts =
        ref.watch(childTaskCountsProvider).valueOrNull ?? const {};
    final q = _search.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Search tips',
            onPressed: _showSearchTips,
          ),
          const SaaraTopMenu(),
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
          // Filters reflow onto as many rows as the width needs — one tidy set
          // of controls, not a row you have to scroll sideways.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterDropdown<_StatusFilter>(
                  label: 'Status',
                  value: _filter,
                  isDefault: _filter == _StatusFilter.all,
                  options: [
                    for (final f in _StatusFilter.values) (f, _label(f)),
                  ],
                  onChanged: (f) => setState(() => _filter = f),
                ),
                _FilterDropdown<_TypeFilter>(
                  label: 'Type',
                  value: _type,
                  isDefault: _type == _TypeFilter.all,
                  options: const [
                    (_TypeFilter.all, 'All'),
                    (_TypeFilter.tasks, 'To-dos'),
                    (_TypeFilter.events, 'Events'),
                  ],
                  onChanged: (t) => setState(() => _type = t),
                ),
                _FilterDropdown<String?>(
                  label: 'Area',
                  value: _area,
                  isDefault: _area == null,
                  options: [
                    (null, 'All areas'),
                    (_unclassifiedArea, 'Unclassified'),
                    for (final a in areas) (a.id, a.displayName),
                  ],
                  onChanged: (a) => setState(() => _area = a),
                ),
                _FilterDropdown<String?>(
                  label: 'Source',
                  value: _source,
                  isDefault: _source == null,
                  options: const [
                    (null, 'Any source'),
                    ('Desktop', 'Desktop'),
                    ('Mobile', 'Mobile'),
                    ('Google', 'Google'),
                  ],
                  onChanged: (s) => setState(() => _source = s),
                ),
                _DateRangeChip(
                  range: _dateRange,
                  onPick: _pickDateRange,
                  onClear: () => setState(() => _dateRange = null),
                ),
                _SortControl(
                  label: _sortLabel(_sortField),
                  ascending: _sortAsc,
                  onField: (f) => setState(() => _sortField = f),
                  onToggle: () => setState(() => _sortAsc = !_sortAsc),
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
                          (t) => _matches(t, cutoff) && _matchesQuery(t, q),
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
    _StatusFilter.drafts => 'Drafts',
    _StatusFilter.archived => 'Archived',
    _StatusFilter.deleted => 'Deleted',
  };

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _dateRange ??
          DateTimeRange(
            start: _startOfDay(now),
            end: _startOfDay(now).add(const Duration(days: 7)),
          ),
      helpText: 'Show tasks between',
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

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

/// Shared look for every control in the filter bar: a pill that's quiet when
/// at its default and tinted when it's actively narrowing the list. Keeping the
/// shape in one place is what makes the bar read as a single system.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.child,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  final Widget child;
  final bool active;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: active ? scheme.secondaryContainer : null,
          border: Border.all(
            color: active ? scheme.secondary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: active
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              size: 18,
              color: active
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
            child: child,
          ),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

/// The Date control: opens a from–to range picker; shows the chosen span and
/// clears with an ✕. A range (not presets) is how people actually scan a
/// period — "everything between the 1st and the 15th".
class _DateRangeChip extends StatelessWidget {
  const _DateRangeChip({
    required this.range,
    required this.onPick,
    required this.onClear,
  });

  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final active = range != null;
    final fmt = DateFormat('MMM d');
    return _FilterPill(
      active: active,
      onTap: onPick,
      tooltip: 'Filter by a date range',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range_outlined),
          const SizedBox(width: 6),
          Text(
            active
                ? '${fmt.format(range!.start)} → ${fmt.format(range!.end)}'
                : 'Date',
          ),
          if (active)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close, size: 16),
              ),
            )
          else
            const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }
}

/// The Sort control: pick the column, and a separate ↑/↓ button flips the
/// direction — the spreadsheet gesture, adapted to a list.
class _SortControl extends StatelessWidget {
  const _SortControl({
    required this.label,
    required this.ascending,
    required this.onField,
    required this.onToggle,
  });

  final String label;
  final bool ascending;
  final ValueChanged<_SortField> onField;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _FilterPill(
      active: false,
      onTap: null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.swap_vert, size: 18),
          const SizedBox(width: 6),
          PopupMenuButton<_SortField>(
            tooltip: 'Sort by',
            onSelected: onField,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _SortField.date, child: Text('Date')),
              PopupMenuItem(value: _SortField.title, child: Text('Title')),
              PopupMenuItem(value: _SortField.status, child: Text('Status')),
              PopupMenuItem(value: _SortField.updated, child: Text('Updated')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact "Label: value ▾" chip that opens a menu — one per filter, so the
/// Tasks screen reads as four small controls instead of a long row of chips.
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.isDefault,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  /// When false, the control is tinted to signal an active (non-"all") filter.
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = options.firstWhere(
      (o) => o.$1 == value,
      orElse: () => options.first,
    );
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: label,
      itemBuilder: (_) => [
        for (final (v, l) in options) PopupMenuItem(value: v, child: Text(l)),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
        decoration: BoxDecoration(
          color: isDefault ? null : scheme.secondaryContainer,
          border: Border.all(
            color: isDefault ? scheme.outlineVariant : scheme.secondary,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDefault ? label : '$label: ${current.$2}',
              style: TextStyle(
                color: isDefault
                    ? scheme.onSurfaceVariant
                    : scheme.onSecondaryContainer,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isDefault
                  ? scheme.onSurfaceVariant
                  : scheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
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
    if (task.publicationState == PublicationState.draft) bits.add('draft');
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

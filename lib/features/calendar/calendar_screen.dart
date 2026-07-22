import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../home/home_screen.dart' show AddTaskFab;
import '../task_detail/task_detail_screen.dart';

/// Calendar view of tasks — month / two-week / week formats, plus a date-range
/// selection. Markers show days with tasks; tapping a task opens its lifecycle.
/// §7 calendar. Also renders **inside** the Today tab ([embedded] = true), so
/// day / week / 2-week / month all live behind a single navigation icon rather
/// than a separate screen duplicating the same task list.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    this.embedded = false,
    this.initialFormat = CalendarFormat.month,
    this.initialDate,
  });

  /// When true, returns just the calendar body — no Scaffold, app bar or FAB —
  /// for hosting inside another screen's tab.
  final bool embedded;

  /// Week / 2 weeks / month, chosen by the host's view selector.
  final CalendarFormat initialFormat;

  /// Open focused on this day instead of today — used to land the user on the
  /// day of an overlap so they can judge it in context (§8).
  final DateTime? initialDate;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focused = widget.initialDate ?? DateTime.now();
  late DateTime? _selected = widget.initialDate ?? DateTime.now();
  late CalendarFormat _format = widget.initialFormat;

  @override
  void didUpdateWidget(covariant CalendarScreen old) {
    super.didUpdateWidget(old);
    // The host's selector changed week/2-week/month — follow it.
    if (old.initialFormat != widget.initialFormat) {
      _format = widget.initialFormat;
    }
  }

  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  Widget build(BuildContext context) {
    // Load a padded window around the focused month.
    final monthStart = DateTime(_focused.year, _focused.month, 1);
    final from = monthStart.subtract(const Duration(days: 7));
    final to = DateTime(
      _focused.year,
      _focused.month + 1,
      1,
    ).add(const Duration(days: 7));
    final tasksAsync = ref.watch(tasksBetweenProvider((from, to)));
    final body = _buildBody(tasksAsync);

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar'), actions: [rangeToggle()]),
      // §7 create from wherever you are, not only from Today.
      floatingActionButton: const AddTaskFab(),
      body: body,
    );
  }

  /// Single-day ⇄ date-range selection. Exposed so the embedded host can put it
  /// in its own app bar.
  Widget rangeToggle() => IconButton(
    tooltip: _rangeMode == RangeSelectionMode.toggledOn
        ? 'Single day'
        : 'Date range',
    icon: Icon(
      _rangeMode == RangeSelectionMode.toggledOn
          ? Icons.date_range
          : Icons.today,
    ),
    onPressed: () => setState(() {
      if (_rangeMode == RangeSelectionMode.toggledOn) {
        _rangeMode = RangeSelectionMode.toggledOff;
        _rangeStart = _rangeEnd = null;
        _selected = _focused;
      } else {
        _rangeMode = RangeSelectionMode.toggledOn;
        _selected = null;
      }
    }),
  );

  Widget _buildBody(AsyncValue<List<Task>> tasksAsync) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        final byDay = <DateTime, List<Task>>{};
        for (final t in tasks) {
          final d = t.scheduledStart ?? t.dueDate;
          if (d == null) continue;
          final key = DateTime.utc(d.year, d.month, d.day);
          byDay.putIfAbsent(key, () => []).add(t);
        }
        List<Task> eventsFor(DateTime day) =>
            byDay[DateTime.utc(day.year, day.month, day.day)] ?? const [];

        return Column(
          children: [
            TableCalendar<Task>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focused,
              calendarFormat: _format,
              rangeSelectionMode: _rangeMode,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              selectedDayPredicate: (d) => isSameDay(_selected, d),
              eventLoader: eventsFor,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month',
                CalendarFormat.twoWeeks: '2 weeks',
                CalendarFormat.week: 'Week',
              },
              onDaySelected: (selected, focused) => setState(() {
                _selected = selected;
                _focused = focused;
                _rangeStart = _rangeEnd = null;
              }),
              onRangeSelected: (start, end, focused) => setState(() {
                _rangeStart = start;
                _rangeEnd = end;
                _focused = focused;
                _selected = null;
              }),
              onFormatChanged: (f) => setState(() => _format = f),
              onPageChanged: (focused) => _focused = focused,
            ),
            const Divider(height: 1),
            Expanded(child: _taskList(eventsFor, tasks)),
          ],
        );
      },
    );
  }

  Widget _taskList(List<Task> Function(DateTime) eventsFor, List<Task> all) {
    // Range mode: everything between the two dates. Else: the selected day.
    late final List<Task> items;
    late final String header;
    if (_rangeStart != null) {
      final end = _rangeEnd ?? _rangeStart!;
      items =
          all.where((t) {
            final d = t.scheduledStart ?? t.dueDate;
            if (d == null) return false;
            final day = DateTime(d.year, d.month, d.day);
            return !day.isBefore(
                  DateTime(
                    _rangeStart!.year,
                    _rangeStart!.month,
                    _rangeStart!.day,
                  ),
                ) &&
                !day.isAfter(DateTime(end.year, end.month, end.day));
          }).toList()..sort(
            (a, b) => (a.scheduledStart ?? a.dueDate!).compareTo(
              b.scheduledStart ?? b.dueDate!,
            ),
          );
      header =
          '${DateFormat.MMMd().format(_rangeStart!)} – ${DateFormat.MMMd().format(end)}';
    } else {
      final day = _selected ?? _focused;
      items = eventsFor(day);
      header = DateFormat.yMMMMEEEEd().format(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(header, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No tasks.'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _CalendarTaskTile(task: items[i]),
                ),
        ),
      ],
    );
  }
}

class _CalendarTaskTile extends StatelessWidget {
  const _CalendarTaskTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = task.scheduledStart ?? task.dueDate;

    // Events render distinctly from tasks (§9) — a coloured time-block, like a
    // calendar entry, vs a check-circle to-do.
    if (task.kind == TaskKind.event) {
      final end = when?.add(Duration(minutes: task.durationMin ?? 60));
      final range = when == null
          ? 'Event'
          : end != null
          ? '${DateFormat.jm().format(when)} – ${DateFormat.jm().format(end)}'
          : DateFormat.jm().format(when);
      return ListTile(
        leading: Container(
          width: 6,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.tertiary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(task.title),
        subtitle: Row(
          children: [
            Icon(Icons.event, size: 13, color: scheme.tertiary),
            const SizedBox(width: 4),
            Expanded(child: Text('$range · Event')),
          ],
        ),
        trailing: task.meetingLink != null
            ? Icon(Icons.videocam_outlined, color: scheme.tertiary)
            : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        ),
      );
    }

    final done = task.status == TaskStatus.completed;
    return ListTile(
      leading: Icon(
        done ? Icons.check_circle : Icons.circle_outlined,
        color: done ? Colors.green : scheme.outline,
      ),
      title: Text(
        task.title,
        style: done
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        when == null
            ? task.status.name
            : '${DateFormat.jm().format(when)} · ${task.status.name}',
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
    );
  }
}

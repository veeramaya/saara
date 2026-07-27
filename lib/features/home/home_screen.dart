import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../domain/enums.dart';
import '../../providers.dart';
import '../../services/ledger_sync_service.dart' show FolderSyncResult;
import '../../services/ocr_service.dart';
import '../capture/review_items_screen.dart';
import '../command/command_screen.dart';
import '../schedule/schedule_check_screen.dart';
import '../../core/platform.dart';
import '../settings/settings_screen.dart';
import 'package:table_calendar/table_calendar.dart' show CalendarFormat;

import '../calendar/calendar_screen.dart';
import '../evening/evening_review_screen.dart';
import '../morning/morning_brief_screen.dart';
import '../task_card/task_card_screen.dart';
import '../common/sense_animation.dart';
import 'widgets/integrity_header.dart';
import 'widgets/task_tile.dart';

/// §7.1 Home — today's timeline of task/event cards grouped by time-of-day,
/// area rings, an expanding FAB (type/talk · capture · quick-add), and a
/// rotating integrity/completion quote in the header (§15).
/// The zoom levels behind the single Today/calendar navigation icon.
enum _Zoom { today, week, twoWeeks, month }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// §7 Today and the calendar are the same information at different zooms, so
  /// they share one navigation slot. The selector below picks the zoom — no
  /// second calendar icon in the app bar, no separate screen.
  _Zoom _zoom = _Zoom.today;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final tasksAsync = ref.watch(tasksForDayProvider(day));

    // Generate recurring-task instances on load; refresh the timeline once any
    // new instances land (§4, §8).
    ref.listen(materializeRecurringProvider, (_, next) {
      next.whenData((count) {
        if (count > 0) ref.invalidate(tasksForDayProvider(day));
      });
    });
    ref.watch(materializeRecurringProvider);

    // §9 Phase 3 — pull in the other device's ledger on open. When a pass
    // actually merges something, refresh the views it touched.
    void refreshOnMerge(AsyncValue<FolderSyncResult?> next) {
      next.whenData((result) {
        if (result != null && !result.merged.isEmpty) {
          ref.invalidate(allTasksProvider);
          ref.invalidate(tasksForDayProvider);
          ref.invalidate(tasksBetweenProvider);
          ref.invalidate(unscheduledTasksProvider);
          ref.invalidate(areaScoresProvider);
          ref.invalidate(overallEffectivenessProvider);
          ref.invalidate(ledgerSyncStatusProvider);
        }
      });
    }

    ref.listen(ledgerAutoSyncProvider, (_, next) => refreshOnMerge(next));
    ref.listen(driveAutoSyncProvider, (_, next) => refreshOnMerge(next));
    ref.watch(ledgerAutoSyncProvider);
    ref.watch(driveAutoSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _zoom == _Zoom.today
              ? DateFormat('EEEE, MMM d').format(day)
              : 'Calendar',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            tooltip: 'Open your day',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MorningBriefScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.nightlight_outlined),
            tooltip: 'Complete your day',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EveningReviewScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          _ZoomSelector(
            zoom: _zoom,
            onChanged: (z) => setState(() => _zoom = z),
          ),
          Expanded(
            child: _zoom != _Zoom.today
                ? CalendarScreen(
                    embedded: true,
                    initialFormat: switch (_zoom) {
                      _Zoom.week => CalendarFormat.week,
                      _Zoom.twoWeeks => CalendarFormat.twoWeeks,
                      _ => CalendarFormat.month,
                    },
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(tasksForDayProvider(day)),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        const IntegrityHeader(),
                        const _ConflictBanner(),
                        tasksAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: SenseLoader(size: 88)),
                          ),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Could not load today: $e'),
                          ),
                          data: (tasks) {
                            if (tasks.isEmpty) {
                              return const _EmptyToday();
                            }
                            return Column(
                              children: [
                                for (final t in tasks)
                                  TaskTile(task: t, day: day),
                              ],
                            );
                          },
                        ),
                        const _UnscheduledSection(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: const AddTaskFab(),
    );
  }
}

/// §7.1 tasks saved with "No date/time". Every timeline query filters on a
/// date, so without this section they are stored but visible nowhere — which
/// reads as Save having silently failed. Hidden entirely when there are none.
class _UnscheduledSection extends ConsumerWidget {
  const _UnscheduledSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(unscheduledTasksProvider).valueOrNull ?? const [];
    if (tasks.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Unscheduled · ${tasks.length}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Saved without a date — open one to give it a time.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        for (final t in tasks)
          TaskTile(task: t, day: DateTime(today.year, today.month, today.day)),
      ],
    );
  }
}

/// §7 the single view selector — Today / Week / 2 weeks / Month — replacing the
/// old duplicate calendar icon in the app bar.
class _ZoomSelector extends StatelessWidget {
  const _ZoomSelector({required this.zoom, required this.onChanged});
  final _Zoom zoom;
  final ValueChanged<_Zoom> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final (z, label) in const [
            (_Zoom.today, 'Today'),
            (_Zoom.week, 'Week'),
            (_Zoom.twoWeeks, '2 weeks'),
            (_Zoom.month, 'Month'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: zoom == z,
                onSelected: (_) => onChanged(z),
              ),
            ),
        ],
      ),
    );
  }
}

/// §8 proactive nudge — when Saara finds schedule conflicts, invite a review.
class _ConflictBanner extends ConsumerWidget {
  const _ConflictBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scheduleConflictsProvider);
    return async.maybeWhen(
      data: (conflicts) {
        if (conflicts.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          color: scheme.tertiaryContainer,
          child: ListTile(
            leading: Icon(
              Icons.layers_outlined,
              color: scheme.onTertiaryContainer,
            ),
            title: Text(
              '${conflicts.length} overlap'
              '${conflicts.length == 1 ? '' : 's'} ahead',
              style: TextStyle(
                color: scheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Neutral by design — it's a heads-up, not a problem list (§8).
            subtitle: Text(
              'Tap to see them — keep or change, your call',
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: scheme.onTertiaryContainer,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScheduleCheckScreen()),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.spa_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nothing scheduled yet.\nGive your word — add a task.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// §7.1 FAB: type/talk a task · capture · quick-add. Capture is Phase 2 (§17);
/// shown but routed to a "coming soon" note for now.
/// §7 the "+ Task" entry point. Lives on Today, Tasks and Calendar so a task
/// can be created from wherever you happen to be looking.
class AddTaskFab extends ConsumerWidget {
  const AddTaskFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only offer "Google Meet event" when Google is actually connected (§9).
    final googleConnected =
        ref.watch(googleConnectedProvider).valueOrNull ?? false;
    return FloatingActionButton.extended(
      onPressed: () => _showAddMenu(context, googleConnected),
      icon: const Icon(Icons.add),
      label: const Text('Task'),
    );
  }

  void _showAddMenu(BuildContext context, bool googleConnected) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Type or talk a task'),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaskCardScreen()),
                );
              },
            ),
            if (googleConnected)
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('New Google Meet event'),
                subtitle: const Text('Adds a Meet link when you save'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TaskCardScreen(startWithMeet: true),
                    ),
                  );
                },
              ),
            // Picking a file works on desktop too (image_picker_windows), so
            // screenshot → task is available there; only the live camera is
            // mobile-only.
            if (supportsFilePick)
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('From a screenshot / photo'),
                subtitle: const Text('Read it into a task with AI'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _capture(context, ImageSource.gallery);
                },
              ),
            if (supportsCamera)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Scan with camera'),
                subtitle: const Text('Read it into a task with AI'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _capture(context, ImageSource.camera);
                },
              ),
            if (supportsFilePick)
              ListTile(
                leading: const Icon(Icons.checklist),
                title: const Text('Meeting summary → tasks'),
                subtitle: const Text('AI extracts every action item to review'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _captureSummary(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.record_voice_over_outlined),
              title: const Text('Tell Saara (voice/text)'),
              subtitle: const Text(
                '“add dentist Fri 4pm”, “move gym”, “mark done”',
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CommandScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.rule),
              title: const Text('Check my schedule'),
              subtitle: const Text(
                'Saara finds conflicts & suggests reschedules',
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ScheduleCheckScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attach a link or file'),
              subtitle: const Text(
                'A Google Drive/Docs link, or an image from phone',
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TaskCardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // §11/§7.6: pick/scan an image → attach it to a new card. The original image
  // is kept so it can be read on the card with "Extract with AI" (Gemini), and
  // always verified against the source. No on-device OCR (it's unreliable).
  Future<void> _capture(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? path;
    try {
      path = await const OcrService().pickImage(source);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn\'t open image: $e')),
      );
      return;
    }
    if (path == null) return; // cancelled
    // ignore: use_build_context_synchronously
    final kind = await _chooseKind(navigator.context);
    if (kind == null) return;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => TaskCardScreen(
          initialKind: kind,
          imagePath: path,
          autoExtract: true,
        ),
      ),
    );
  }

  // §11 use-case: a meeting summary / MoM screenshot → the AI proposes every
  // action item; the user reviews and batch-creates. AI-only (needs a key).
  Future<void> _captureSummary(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? path;
    try {
      path = await const OcrService().pickImage(ImageSource.gallery);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn\'t open image: $e')),
      );
      return;
    }
    if (path == null) return; // cancelled
    navigator.push(
      MaterialPageRoute(builder: (_) => ReviewItemsScreen(imagePath: path!)),
    );
  }

  /// Ask whether captured text should become a task or a calendar event (§9).
  Future<TaskKind?> _chooseKind(BuildContext context) {
    return showModalBottomSheet<TaskKind>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Create this as…'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Task'),
              subtitle: const Text('A to-do — syncs with Google Tasks'),
              onTap: () => Navigator.pop(ctx, TaskKind.task),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Event'),
              subtitle: const Text(
                'A calendar entry — syncs with Google Calendar',
              ),
              onTap: () => Navigator.pop(ctx, TaskKind.event),
            ),
          ],
        ),
      ),
    );
  }
}

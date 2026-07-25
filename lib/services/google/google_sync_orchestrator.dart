import 'package:drift/drift.dart' show Value;

import '../../data/database.dart';
import '../../domain/enums.dart';
import 'google_sync_service.dart';
import 'meeting_note_tag.dart';

/// Result of a full reconcile, per direction.
class SyncSummary {
  int imported = 0; // new Google → Saara
  int pushedNew = 0; // new Saara → Google
  int updatedLocal = 0; // Google change applied to Saara
  int updatedRemote = 0; // Saara change pushed to Google
  int deletedLocal = 0; // deleted on Google → soft-deleted in Saara
  int deletedRemote = 0; // deleted in Saara → deleted on Google
  int importedEvents = 0; // new Google Calendar events → Saara timeline

  /// Set when the Calendar half of the sync failed. Tasks can still succeed, so
  /// this is reported rather than thrown — but it must be *visible*, not
  /// swallowed: a missing Calendar scope or a disabled API otherwise looks
  /// exactly like "nothing to sync".
  String? calendarError;

  @override
  String toString() {
    final base =
        'Imported $imported task${imported == 1 ? '' : 's'} · '
        '$importedEvents calendar event${importedEvents == 1 ? '' : 's'}\n'
        'Pushed $pushedNew new · updated $updatedLocal here / $updatedRemote on Google\n'
        'Deleted $deletedLocal here / $deletedRemote on Google';
    if (calendarError == null) return base;
    return '$base\n\n⚠ Calendar sync failed: $calendarError\n'
        'Reconnect Google and make sure the Calendar permission is granted.';
  }
}

/// §9 two-way Google Tasks sync. Reconciles create / update / complete / delete
/// in both directions with **last-writer-wins** (compares Google's `updated`
/// stamp against the task's local `updated_at`), so desktop (Tasks web) and
/// mobile stay consistent. Everything is device→Google directly (§1.1).
class GoogleSyncOrchestrator {
  GoogleSyncOrchestrator({
    required this.db,
    required this.google,
    required String Function() idGenerator,
  }) : _newId = idGenerator;

  final AppDatabase db;
  final GoogleSyncService google;
  final String Function() _newId;

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  Future<SyncSummary> syncAll() async {
    final summary = SyncSummary();
    final listId = await google.defaultListId();

    final remote = await google.fetchAllTasks();
    final byId = {for (final g in remote) g.id: g};
    final linked = await db.taskDao.linkedTasks();
    final newLocal = await db.taskDao.tasksToPush();

    // --- reconcile already-linked tasks ---
    for (final s in linked) {
      final g = byId.remove(s.gcalEventId); // remove → handled

      if (g == null || g.deleted) {
        // Gone or deleted on Google → mirror the delete locally.
        if (s.deletedAt == null) {
          await db.taskDao.softDeleteFromSync(s.id);
          summary.deletedLocal++;
        }
        continue;
      }
      if (s.deletedAt != null) {
        // Deleted locally → delete on Google.
        await google.deleteTask(g.listId, g.id);
        summary.deletedRemote++;
        continue;
      }

      final localDirty = s.updatedAt.isAfter(s.lastSyncedAt ?? _epoch);
      final remoteDirty = g.updated != (s.gcalEtag ?? '');
      if (!localDirty && !remoteDirty) continue;

      final remoteWins = !localDirty || _remoteIsNewer(g, s);
      if (remoteWins && remoteDirty) {
        await _applyRemote(s, g);
        summary.updatedLocal++;
      } else if (localDirty) {
        final patched = await google.patchTask(
          listId: g.listId,
          id: g.id,
          title: s.title,
          notes: await _outgoingNotes(s),
          due: s.dueDate ?? s.scheduledStart,
          completed: s.status == TaskStatus.completed,
        );
        await db.taskDao.touchSynced(s.id, patched.updated);
        summary.updatedRemote++;
      }
    }

    // --- import Google tasks with no local link ---
    final now = DateTime.now();
    for (final g in byId.values) {
      if (g.deleted) continue;
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          id: _newId(),
          title: g.title,
          // Keep the "From meeting:" line — it's the key _relinkActionItems()
          // uses to rebuild the event→task grouping, and it reads fine to a
          // human. _outgoingNotes() strips before re-appending, so it can't
          // accumulate on repeated syncs.
          notes: Value(g.notes),
          status: Value(
            g.completed ? TaskStatus.completed : TaskStatus.created,
          ),
          scheduledStart: Value(g.due),
          dueDate: Value(g.due),
          completedAt: Value(g.completed ? now : null),
          gcalEventId: Value(g.id),
          gcalCalendarId: Value(g.listId),
          gcalEtag: Value(g.updated),
          lastSyncedAt: Value(now),
          // Arrives released: it is already in your world and you owe a
          // response. Leaving it unanswered is not neutral (§4.1b-i).
          publicationState: const Value(PublicationState.released),
          source: const Value(TaskSource.gcalSync),
          createdAt: now,
          updatedAt: now,
        ),
      );
      summary.imported++;
    }

    // --- push brand-new local tasks ---
    for (final s in newLocal) {
      final g = await google.insertTask(
        title: s.title,
        notes: await _outgoingNotes(s),
        due: s.dueDate ?? s.scheduledStart,
        listId: listId,
      );
      await db.taskDao.markSynced(
        s.id,
        googleId: g.id,
        listId: listId,
        updated: g.updated,
      );
      summary.pushedNew++;
    }

    // --- two-way Google Calendar events reconcile ---
    // Guarded: if the Calendar API isn't enabled (or its scope wasn't granted),
    // Tasks sync still succeeds — but the failure is *recorded* and shown, not
    // swallowed, so "my event won't sync" is diagnosable instead of silent.
    try {
      await _syncCalendarEvents(summary);
    } catch (e) {
      summary.calendarError = e.toString();
    }

    // Re-attach meeting action items to their event. Runs *after* the calendar
    // pass so the parent event exists locally on a freshly-synced device (§4).
    try {
      await _relinkActionItems();
    } catch (_) {}

    return summary;
  }

  /// Two-way sync of primary-calendar events (§9). Events (kind=event) are a
  /// different nature from tasks: they live on the timeline, render distinctly,
  /// and an event created in Saara is pushed to Google Calendar. Window:
  /// yesterday → +30 days. Last-writer-wins, mirroring the Tasks reconcile.
  Future<void> _syncCalendarEvents(SyncSummary summary) async {
    final now = DateTime.now();
    final from = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final to = from.add(const Duration(days: 31));
    final remote = await google.fetchCalendarEvents(timeMin: from, timeMax: to);
    final byId = {for (final e in remote) e.id: e};
    final linked = await db.taskDao.linkedEvents();
    final newLocal = await db.taskDao.eventsToPush();

    // Recurring events (created in Saara) come back as expanded instances whose
    // `recurringEventId` is our master id. Track those so we neither false-delete
    // the master nor re-import its instances.
    final remoteMasters = <String>{
      for (final e in remote)
        if (e.recurringEventId != null) e.recurringEventId!,
    };
    final linkedMasterIds = {for (final s in linked) s.gcalEventId};

    for (final s in linked) {
      final e = byId.remove(s.gcalEventId);
      final masterPresent = remoteMasters.contains(s.gcalEventId);
      if ((e == null || e.cancelled) && !masterPresent) {
        if (s.deletedAt == null) {
          await db.taskDao.softDeleteFromSync(s.id);
          summary.deletedLocal++;
        }
        continue;
      }
      if (s.deletedAt != null) {
        await google.deleteEvent(s.gcalEventId!);
        summary.deletedRemote++;
        continue;
      }
      final localDirty = s.updatedAt.isAfter(s.lastSyncedAt ?? _epoch);
      if (e != null) {
        final remoteDirty = e.updated != (s.gcalEtag ?? '');
        if (!localDirty && !remoteDirty) continue;
        final remoteWins = !localDirty || _remoteEventNewer(e, s);
        if (remoteWins && remoteDirty) {
          await _applyRemoteEvent(s, e);
          summary.updatedLocal++;
        } else if (localDirty && s.scheduledStart != null) {
          final patched = await google.patchEvent(
            id: e.id,
            title: s.title,
            notes: s.notes,
            start: s.scheduledStart!,
            durationMin: s.durationMin,
            location: s.locationName,
            rrule: s.rrule,
            meetRequestId: _wantsMeet(s) ? s.id : null,
          );
          await db.taskDao.touchSynced(s.id, patched.updated);
          if (patched.meetingLink != null && (s.meetingLink ?? '').isEmpty) {
            await _storeMeetingLink(s.id, patched.meetingLink!);
          }
          summary.updatedRemote++;
        }
      } else if (localDirty && s.scheduledStart != null) {
        // Recurring master present only via instances — patch it by id.
        final patched = await google.patchEvent(
          id: s.gcalEventId!,
          title: s.title,
          notes: s.notes,
          start: s.scheduledStart!,
          durationMin: s.durationMin,
          location: s.locationName,
          rrule: s.rrule,
          meetRequestId: _wantsMeet(s) ? s.id : null,
        );
        await db.taskDao.touchSynced(s.id, patched.updated);
        if (patched.meetingLink != null && (s.meetingLink ?? '').isEmpty) {
          await _storeMeetingLink(s.id, patched.meetingLink!);
        }
        summary.updatedRemote++;
      }
    }

    // import new remote events (skip instances of our own recurring events)
    for (final e in byId.values) {
      if (e.cancelled) continue;
      if (e.recurringEventId != null &&
          linkedMasterIds.contains(e.recurringEventId)) {
        continue;
      }
      await db.taskDao.insertTask(
        TasksCompanion.insert(
          id: _newId(),
          title: e.title,
          kind: const Value(TaskKind.event),
          scheduledStart: Value(e.start),
          dueDate: Value(e.start),
          durationMin: Value(e.durationMin),
          meetingLink: Value(e.meetingLink),
          locationName: Value(e.location),
          gcalEventId: Value(e.id),
          gcalCalendarId: const Value('primary'),
          gcalEtag: Value(e.updated),
          lastSyncedAt: Value(now),
          // Someone else put this on your calendar; you owe them an answer.
          publicationState: const Value(PublicationState.released),
          source: const Value(TaskSource.gcalEvent),
          createdAt: now,
          updatedAt: now,
        ),
      );
      summary.importedEvents++;
    }

    // push brand-new local events → Google Calendar
    for (final s in newLocal) {
      if (s.scheduledStart == null) continue; // an event needs a time
      final e = await google.insertEvent(
        title: s.title,
        notes: s.notes,
        start: s.scheduledStart!,
        durationMin: s.durationMin,
        location: s.locationName,
        rrule: s.rrule,
        meetRequestId: _wantsMeet(s) ? s.id : null,
      );
      await db.taskDao.markSynced(
        s.id,
        googleId: e.id,
        listId: 'primary',
        updated: e.updated,
      );
      // Google minted the Meet link — store it so the event shows a join link.
      if (e.meetingLink != null && (s.meetingLink ?? '').isEmpty) {
        await _storeMeetingLink(s.id, e.meetingLink!);
      }
      summary.pushedNew++;
    }
  }

  /// True when the user asked Saara to generate a Google Meet link (provider
  /// set to Meet) but none exists yet — the signal to request one on push.
  bool _wantsMeet(Task s) =>
      s.meetingProvider == MeetingProvider.meet &&
      (s.meetingLink ?? '').isEmpty;

  Future<void> _storeMeetingLink(String taskId, String link) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(meetingLink: Value(link)),
    );
  }

  /// How many stray per-date copies Saara has on Google — a dry run for the
  /// cleanup below, so the user sees the number before anything is deleted.
  Future<int> countStrayOccurrences() async =>
      (await db.taskDao.saaraPushedOccurrences()).length;

  /// One-off repair for the duplication bug: removes the per-date copies Saara
  /// pushed to Google for repeating tasks, leaving the local occurrences in
  /// place (they are correct locally — only the pushed copies were wrong).
  ///
  /// **Only rows Saara created and pushed are touched.** Anything imported from
  /// Google — the user's real calendar — is excluded by
  /// [TaskDao.saaraPushedOccurrences] and can never be deleted here. A remote
  /// copy that is already gone is treated as success, not an error.
  Future<int> cleanupStrayOccurrences() async {
    final strays = await db.taskDao.saaraPushedOccurrences();
    final listId = await google.defaultListId();
    var removed = 0;
    for (final s in strays) {
      final gid = s.gcalEventId;
      if (gid == null || gid.isEmpty) continue;
      try {
        if (s.kind == TaskKind.event) {
          await google.deleteEvent(gid);
        } else {
          await google.deleteTask(s.gcalCalendarId ?? listId, gid);
        }
        removed++;
      } catch (_) {
        // Already deleted on Google, or not reachable — unlink either way so we
        // don't keep trying, and never re-push it.
      }
      await db.taskDao.unlinkFromGoogle(s.id);
    }
    return removed;
  }

  /// Directly create/attach a Google Meet link for one event and return it.
  ///
  /// The editor calls this straight after saving a Meet event, rather than
  /// leaning on the full reconcile: last-writer-wins can decide the remote is
  /// "newer" and pull instead of pushing the Meet request, and the calendar
  /// pass swallows its errors — either of which leaves the link silently
  /// missing. This path is deterministic and throws on failure so the UI can
  /// tell the user. A freshly-created Meet conference can come back "pending"
  /// with no link yet, so we re-fetch once.
  Future<String?> ensureMeetLink(String taskId) async {
    final s = await db.taskDao.findById(taskId);
    if (s == null || s.scheduledStart == null) return null;
    if ((s.meetingLink ?? '').isNotEmpty) return s.meetingLink;

    GCalEvent e;
    if ((s.gcalEventId ?? '').isEmpty) {
      // Not on Calendar yet — create it, asking for a Meet link.
      e = await google.insertEvent(
        title: s.title,
        notes: s.notes,
        start: s.scheduledStart!,
        durationMin: s.durationMin,
        location: s.locationName,
        rrule: s.rrule,
        meetRequestId: s.id,
      );
      await db.taskDao.markSynced(
        s.id,
        googleId: e.id,
        listId: 'primary',
        updated: e.updated,
      );
    } else {
      // Already on Calendar — patch a Meet request onto it.
      e = await google.patchEvent(
        id: s.gcalEventId!,
        title: s.title,
        notes: s.notes,
        start: s.scheduledStart!,
        durationMin: s.durationMin,
        location: s.locationName,
        rrule: s.rrule,
        meetRequestId: s.id,
      );
      await db.taskDao.touchSynced(s.id, e.updated);
    }

    // The conference may still be provisioning — re-read once to get the link.
    var link = e.meetingLink;
    if ((link ?? '').isEmpty) {
      try {
        final refreshed = await google.getEvent(e.id);
        link = refreshed.meetingLink;
      } catch (_) {}
    }
    if ((link ?? '').isNotEmpty) {
      await _storeMeetingLink(s.id, link!);
      return link;
    }
    return null;
  }

  bool _remoteEventNewer(GCalEvent e, Task s) {
    final remote = DateTime.tryParse(e.updated);
    if (remote == null) return true;
    return !remote.isBefore(s.updatedAt);
  }

  Future<void> _applyRemoteEvent(Task s, GCalEvent e) async {
    final now = DateTime.now();
    await (db.update(db.tasks)..where((t) => t.id.equals(s.id))).write(
      TasksCompanion(
        title: Value(e.title),
        scheduledStart: Value(e.start),
        dueDate: Value(e.start),
        durationMin: Value(e.durationMin),
        meetingLink: Value(e.meetingLink),
        locationName: Value(e.location),
        gcalEtag: Value(e.updated),
        lastSyncedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  bool _remoteIsNewer(GTask g, Task s) {
    final remote = DateTime.tryParse(g.updated);
    if (remote == null) {
      return true; // server is the cross-device source of truth
    }
    return !remote.isBefore(s.updatedAt);
  }

  // The "which meeting did this come from" line on a child action item's
  // Google Tasks note (§4/§9) — see meeting_note_tag.dart. Local grouping stays
  // in Saara (parentEventId); Google gets readable context + the parent's event
  // id so a second device can rebuild the link. No fake hierarchy is pushed.
  static const _meetingMarker = kMeetingMarker;

  /// The note to SEND to Google. For an action item (has parentEventId) we
  /// append a `From meeting: <event> (date)` line so context is visible in
  /// Google Tasks on web/desktop/mobile. Non-child tasks push unchanged.
  Future<String?> _outgoingNotes(Task s) async {
    if (s.parentEventId == null) return s.notes;
    final base = _stripMeetingLine(s.notes);
    final event = await db.taskDao.findById(s.parentEventId!);
    if (event == null) return base;
    // Carry the parent's Google event id: for a *recurring* meeting each
    // occurrence has its own id, so items land on the right date. Titles repeat
    // and must never be the key.
    final line = buildMeetingLine(
      title: event.title,
      when: event.scheduledStart ?? event.dueDate,
      gcalEventId: event.gcalEventId,
    );
    return (base == null || base.isEmpty) ? line : '$base\n\n$line';
  }

  /// Re-attaches action items to their parent event after a sync. `parentEventId`
  /// is deliberately never sent to Google (its model has no task-under-event),
  /// so on a second device the event and its tasks arrive unrelated.
  ///
  /// Matching is by the parent's **Google event id**, which is unique per
  /// occurrence of a recurring meeting — a title would attach items to the
  /// wrong date. Title matching survives only as a fallback for items written
  /// before ids were carried.
  Future<void> _relinkActionItems() async {
    final unlinked =
        await (db.select(db.tasks)
              ..where((t) => t.deletedAt.isNull())
              ..where((t) => t.parentEventId.isNull())
              ..where((t) => t.notes.isNotNull()))
            .get();
    final orphans = unlinked
        .where((t) => t.notes!.contains(_meetingMarker))
        .toList();
    if (orphans.isEmpty) return;

    final events =
        await (db.select(db.tasks)
              ..where((t) => t.deletedAt.isNull())
              ..where((t) => t.kind.equalsValue(TaskKind.event)))
            .get();
    if (events.isEmpty) return;

    // Primary key: Google event id → local event (unique per occurrence).
    final byGcalId = <String, String>{
      for (final e in events)
        if (e.gcalEventId != null && e.gcalEventId!.isNotEmpty)
          e.gcalEventId!: e.id,
    };
    // Legacy fallback only — ambiguous when a meeting repeats.
    final byTitle = <String, String>{
      for (final e in events) e.title.trim().toLowerCase(): e.id,
    };

    for (final t in orphans) {
      String? eventId;
      final gcalId = eventIdFromNote(t.notes);
      if (gcalId != null) {
        eventId = byGcalId[gcalId];
        // An id was present but its event isn't here yet — don't guess by
        // title, or a recurring meeting attaches items to the wrong date.
        if (eventId == null) continue;
      } else {
        final title = meetingTitleFromNote(t.notes);
        if (title == null) continue;
        eventId = byTitle[title.toLowerCase()];
      }
      if (eventId == null || eventId == t.id) continue;
      await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
        TasksCompanion(parentEventId: Value(eventId)),
      );
    }
  }

  /// Removes any "From meeting: …" line we appended, so a note coming back from
  /// Google never duplicates that line into the local note (which would re-push
  /// and grow). Leaves notes without the marker byte-identical.
  String? _stripMeetingLine(String? notes) {
    if (notes == null || !notes.contains(_meetingMarker)) return notes;
    final cut = notes
        .replaceFirst(
          RegExp('\\n*${RegExp.escape(_meetingMarker)}.*\$', dotAll: true),
          '',
        )
        .trim();
    return cut.isEmpty ? null : cut;
  }

  Future<void> _applyRemote(Task s, GTask g) async {
    final newStatus = g.completed ? TaskStatus.completed : TaskStatus.created;
    if (s.status != newStatus) {
      // Keep the integrity ledger complete for sync-driven status changes (§3.3).
      await db.taskDao.recordSyncTransition(
        TaskTransitionsCompanion.insert(
          id: _newId(),
          taskId: s.id,
          fromStatus: Value(s.status),
          toStatus: newStatus,
          at: DateTime.now(),
          note: const Value('google-sync'),
        ),
      );
    }
    await db.taskDao.applyRemoteToTask(
      s.id,
      title: g.title,
      // Preserved (not stripped) — see the note on the import path above.
      notes: g.notes,
      due: _keepLocalTimeOfDay(s.scheduledStart, g.due),
      completed: g.completed,
      updated: g.updated,
    );
  }

  /// Google **Tasks** `due` is date-only — it cannot carry a time of day, so it
  /// comes back as midnight (05:30 IST). If we copied it over a task that has a
  /// real clock time locally (set in Saara, or carried in by the ledger), every
  /// sync would re-flatten it and the time would be permanently lost. So take
  /// Google's *date* but keep our *time of day*. The ledger is the source of
  /// truth for the time on a to-do; Google is only trusted for the date it
  /// can actually represent.
  static DateTime? _keepLocalTimeOfDay(DateTime? localStart, DateTime? due) {
    if (due == null) return localStart; // due cleared on Google → keep ours
    if (localStart == null) return due; // no local time → nothing to preserve
    // Take Google's calendar date, keep the local hour/minute.
    return DateTime(
      due.year,
      due.month,
      due.day,
      localStart.hour,
      localStart.minute,
      localStart.second,
    );
  }
}

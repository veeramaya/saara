import 'package:saara/services/google/google_sync_service.dart';

/// An in-memory stand-in for Google Tasks + Calendar.
///
/// The sync layer had no test seam, which is why every sync bug this project
/// hit was found in production: per-date copies multiplying into hundreds of
/// duplicates, deletes that didn't line up across devices, Meet requests
/// silently skipped. All of them are cheap to catch here and expensive to catch
/// on a phone.
///
/// It records **what was sent**, not just what came back — most of those bugs
/// were about Saara pushing something it never should have.
class FakeGoogle extends GoogleSyncService {
  FakeGoogle();

  final Map<String, GTask> tasks = {};
  final Map<String, GCalEvent> events = {};

  /// Every call made, in order — so a test can assert that a push never
  /// happened at all, which is usually the interesting claim.
  final List<String> calls = [];

  int _seq = 0;
  String _id(String prefix) => '$prefix-${_seq++}';

  /// Titles pushed to Google **Tasks**. The 208-duplicate incident would have
  /// shown up here immediately as one entry per date.
  List<String> get pushedTaskTitles =>
      tasks.values.map((t) => t.title).toList();

  List<String> get pushedEventTitles =>
      events.values.map((e) => e.title).toList();

  /// The RRULEs Saara sent — a repeating commitment should appear once, as a
  /// rule, not as many dated rows.
  final List<String?> pushedRecurrences = [];

  /// Meet conference requests, by the requestId Saara supplied.
  final List<String> meetRequests = [];

  @override
  Future<String> defaultListId() async {
    calls.add('defaultListId');
    return 'list-1';
  }

  @override
  Future<List<GTask>> fetchAllTasks() async {
    calls.add('fetchAllTasks');
    return tasks.values.toList();
  }

  @override
  Future<GTask> insertTask({
    required String title,
    String? notes,
    DateTime? due,
    bool completed = false,
    required String listId,
  }) async {
    calls.add('insertTask:$title');
    final t = GTask(
      id: _id('gt'),
      listId: listId,
      title: title,
      notes: notes,
      due: due,
      completed: completed,
      updated: DateTime(2026, 7, 22).toIso8601String(),
    );
    tasks[t.id] = t;
    return t;
  }

  @override
  Future<GTask> patchTask({
    required String listId,
    required String id,
    required String title,
    String? notes,
    DateTime? due,
    required bool completed,
  }) async {
    calls.add('patchTask:$id');
    final t = GTask(
      id: id,
      listId: listId,
      title: title,
      notes: notes,
      due: due,
      completed: completed,
      updated: DateTime(2026, 7, 22, 1).toIso8601String(),
    );
    tasks[id] = t;
    return t;
  }

  @override
  Future<void> deleteTask(String listId, String id) async {
    calls.add('deleteTask:$id');
    tasks.remove(id);
  }

  @override
  Future<List<GCalEvent>> fetchCalendarEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    calls.add('fetchCalendarEvents');
    return events.values.toList();
  }

  @override
  Future<GCalEvent> insertEvent({
    required String title,
    String? notes,
    required DateTime start,
    int? durationMin,
    String? location,
    String? rrule,
    String? meetRequestId,
  }) async {
    calls.add('insertEvent:$title');
    pushedRecurrences.add(rrule);
    if (meetRequestId != null) meetRequests.add(meetRequestId);
    final e = GCalEvent(
      id: _id('ge'),
      title: title,
      start: start,
      durationMin: durationMin,
      location: location,
      meetingLink: meetRequestId == null
          ? null
          : 'https://meet.google.com/fake-$meetRequestId',
      updated: DateTime(2026, 7, 22).toIso8601String(),
    );
    events[e.id] = e;
    return e;
  }

  @override
  Future<GCalEvent> patchEvent({
    required String id,
    required String title,
    String? notes,
    required DateTime start,
    int? durationMin,
    String? location,
    String? rrule,
    String? meetRequestId,
  }) async {
    calls.add('patchEvent:$id');
    if (meetRequestId != null) meetRequests.add(meetRequestId);
    final e = GCalEvent(
      id: id,
      title: title,
      start: start,
      durationMin: durationMin,
      location: location,
      meetingLink: meetRequestId == null
          ? events[id]?.meetingLink
          : 'https://meet.google.com/fake-$meetRequestId',
      updated: DateTime(2026, 7, 22, 1).toIso8601String(),
    );
    events[id] = e;
    return e;
  }

  @override
  Future<GCalEvent> getEvent(String id) async {
    calls.add('getEvent:$id');
    final e = events[id];
    if (e == null) throw GoogleSyncException('no such event: $id');
    return e;
  }

  @override
  Future<void> deleteEvent(String id) async {
    calls.add('deleteEvent:$id');
    events.remove(id);
  }

  /// Simulates something arriving from outside — a meeting someone else put on
  /// your calendar.
  GCalEvent seedIncomingEvent({
    required String title,
    required DateTime start,
    int durationMin = 60,
  }) {
    final e = GCalEvent(
      id: _id('incoming'),
      title: title,
      start: start,
      durationMin: durationMin,
      updated: DateTime(2026, 7, 21).toIso8601String(),
    );
    events[e.id] = e;
    return e;
  }
}

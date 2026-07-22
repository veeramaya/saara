import 'package:intl/intl.dart';

/// §4/§9 the "which meeting did this come from" line Saara appends to an action
/// item's **Google Tasks note**.
///
/// Google has no task-under-event concept and no custom-metadata field on a
/// task, so the note is the only channel available. The line carries two things:
///
///  * a human part — readable in Google Tasks on web/mobile
///  * a machine part — the parent's **Google Calendar event id**, so a second
///    device can rebuild the grouping exactly. Titles are *not* sufficient:
///    recurring meetings repeat the same title, and each occurrence must keep
///    its own action items.
///
/// The whole line is stripped for display inside Saara ([stripMeetingLine]) —
/// the app shows the parent through its own back-link instead.
const kMeetingMarker = '— From meeting:';

/// Wraps the event id so it can be parsed back out unambiguously.
const _idOpen = '⟨';
const _idClose = '⟩';

/// Builds the line to append to an outgoing Google Tasks note.
String buildMeetingLine({
  required String title,
  DateTime? when,
  String? gcalEventId,
}) {
  final date = when == null ? '' : ' (${DateFormat('d MMM').format(when)})';
  final id = (gcalEventId == null || gcalEventId.isEmpty)
      ? ''
      : ' $_idOpen$gcalEventId$_idClose';
  return '$kMeetingMarker $title$date$id';
}

/// The parent's Google Calendar event id, when present. This is the reliable
/// key — unique per *occurrence* of a recurring meeting.
String? eventIdFromNote(String? notes) {
  if (notes == null) return null;
  final i = notes.lastIndexOf(kMeetingMarker);
  if (i < 0) return null;
  final tail = notes.substring(i);
  final open = tail.indexOf(_idOpen);
  final close = tail.indexOf(_idClose, open + 1);
  if (open < 0 || close < 0) return null;
  final id = tail.substring(open + 1, close).trim();
  return id.isEmpty ? null : id;
}

/// The event title in the line — a *fallback* only, for items written before
/// ids were included. Ambiguous for recurring meetings, so [eventIdFromNote]
/// always wins.
String? meetingTitleFromNote(String? notes) {
  if (notes == null) return null;
  final i = notes.lastIndexOf(kMeetingMarker);
  if (i < 0) return null;
  var s = notes.substring(i + kMeetingMarker.length).trim();
  final idAt = s.indexOf(_idOpen);
  if (idAt >= 0) s = s.substring(0, idAt).trim();
  final p = s.lastIndexOf(' (');
  if (p > 0 && s.endsWith(')')) s = s.substring(0, p);
  s = s.trim();
  return s.isEmpty ? null : s;
}

/// Removes the appended line so Saara never shows its own sync plumbing to the
/// user. Notes without the marker come back byte-identical.
String? stripMeetingLine(String? notes) {
  if (notes == null || !notes.contains(kMeetingMarker)) return notes;
  final cut = notes
      .replaceFirst(
        RegExp('\\n*${RegExp.escape(kMeetingMarker)}.*\$', dotAll: true),
        '',
      )
      .trim();
  return cut.isEmpty ? null : cut;
}

import 'package:intl/intl.dart';

/// An **unambiguous** "now" to hand an AI prompt.
///
/// `DateTime.now().toIso8601String()` renders a *local* time with **no offset**
/// (`2026-07-19T15:42:00.000`), so a model quite reasonably reads it as UTC.
/// Every relative date ("tomorrow 5pm", "in 2 days") then lands in the wrong
/// zone — and near midnight, on the wrong day. Always send the offset.
String promptNow([DateTime? now]) {
  final n = now ?? DateTime.now();
  final off = n.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final h = off.abs().inHours.toString().padLeft(2, '0');
  final m = (off.abs().inMinutes % 60).toString().padLeft(2, '0');
  final stamp = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(n);
  return '$stamp$sign$h:$m (${n.timeZoneName}, UTC$sign$h:$m)';
}

/// Parses an ISO-8601 datetime from an AI response into **local** time.
///
/// Models very often answer in UTC (`2026-07-20T03:30:00Z`) even when told the
/// user's offset. `DateTime.parse` then returns a *UTC* DateTime, and
/// formatting that shows the UTC wall clock — so 9:00 AM IST renders as
/// 3:30 AM. `toLocal()` fixes the display without changing the instant, and is
/// a no-op for values that are already local.
DateTime? parseAiDateTime(Object? raw) {
  final s = raw?.toString().trim();
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// Appended to extraction prompts so returned datetimes come back in the user's
/// zone rather than UTC.
const kPromptTimeRule =
    'Interpret and return ALL dates/times in the user\'s local timezone shown '
    'above, and include that same offset in every ISO-8601 value you return.';

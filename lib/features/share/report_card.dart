import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../common/task_status_icon.dart';
import 'share_card_deck.dart';

/// A single-page **report summary** card for a completed task or event — the
/// glanceable "how it went" face, reused by the Day book so an album can mix
/// day cards and report cards. (The full multi-page report lives in the share
/// composer; this is the one-card digest.)
CardFrame reportSummaryCard({
  required Task task,
  required CardPalette palette,
  String? areaName,
  bool showWhen = true,
  bool showStatus = true,
  bool showOutcome = true,
}) {
  final p = palette;
  final (icon, label) = reportEyebrow(task.status);
  final when = task.scheduledStart ?? task.dueDate;
  final body = <Widget>[
    _titleText(task, p),
    if (showWhen && when != null) ..._whenBlock(when, task.durationMin, p),
    if (showStatus) ...[
      const SizedBox(height: 10),
      ReportStatusPill(status: task.status, due: task.dueDate),
    ],
    if (showOutcome &&
        (task.completedAt != null || (task.timeToCompleteMin ?? 0) > 0)) ...[
      const SizedBox(height: 8),
      if (task.completedAt != null)
        Text(
          'Completed ${DateFormat('d MMM, h:mm a').format(task.completedAt!)}',
          style: TextStyle(color: p.muted, fontSize: 13),
        ),
      if ((task.timeToCompleteMin ?? 0) > 0)
        Text(
          'Took ${_fmtDuration(task.timeToCompleteMin!)}',
          style: TextStyle(color: p.muted, fontSize: 13),
        ),
    ],
  ];
  return CardFrame(
    palette: p,
    eyebrowIcon: icon,
    eyebrow: label,
    badgeName: areaName,
    body: body,
  );
}

/// A single-page **invitation** card for the book — the forward-looking face.
CardFrame invitationSummaryCard({
  required Task task,
  required CardPalette palette,
  String? areaName,
  bool showWhen = true,
  bool showJoin = true,
  bool showLocation = true,
}) {
  final p = palette;
  final isEvent = task.kind == TaskKind.event;
  final when = task.scheduledStart ?? task.dueDate;
  final join = (task.meetingLink ?? '').trim();
  final loc = (task.locationName ?? '').trim();
  final body = <Widget>[
    _titleText(task, p),
    if (showWhen && when != null) ..._whenBlock(when, task.durationMin, p),
    if (showJoin && join.isNotEmpty) ...[
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.accent.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_rounded, size: 16, color: p.accent),
            const SizedBox(width: 8),
            Text(
              _joinLabel(join).toUpperCase(),
              style: TextStyle(
                color: p.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    ],
    if (showLocation && loc.isNotEmpty) ...[
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(Icons.place_outlined, size: 14, color: p.muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              loc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.muted, fontSize: 13),
            ),
          ),
        ],
      ),
    ],
  ];
  return CardFrame(
    palette: p,
    eyebrowIcon: isEvent ? Icons.event : Icons.check_circle_outline,
    eyebrow: isEvent ? "YOU'RE INVITED" : "I'VE COMMITTED TO",
    badgeName: areaName,
    body: body,
  );
}

Widget _titleText(Task task, CardPalette p) => Text(
  task.title,
  maxLines: 4,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: p.ink,
    fontSize: task.title.length > 46 ? 24 : 30,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  ),
);

List<Widget> _whenBlock(DateTime when, int? dur, CardPalette p) => [
  const SizedBox(height: 14),
  Text(
    DateFormat('EEEE, d MMMM').format(when),
    style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w600),
  ),
  Text(
    _timeLine(when, dur),
    style: TextStyle(color: p.muted, fontSize: 14),
  ),
];

String _joinLabel(String link) {
  final l = link.toLowerCase();
  if (l.contains('meet.google')) return 'Google Meet';
  if (l.contains('zoom.')) return 'Zoom';
  if (l.contains('teams.')) return 'Microsoft Teams';
  if (l.contains('webex')) return 'Webex';
  return 'Join meeting';
}

/// The report eyebrow (icon + label), keyed to how the word landed.
(IconData, String) reportEyebrow(TaskStatus status) {
  switch (status) {
    case TaskStatus.completed:
      return (Icons.verified_outlined, 'KEPT MY WORD');
    case TaskStatus.cancelled:
      return (Icons.remove_circle_outline, 'I FELL SHORT');
    case TaskStatus.missed:
      return (Icons.error_outline, 'MISSED');
    case TaskStatus.rejected:
      return (Icons.do_not_disturb_on_outlined, 'DECLINED');
    default:
      return (Icons.timelapse_outlined, 'WHERE THIS STANDS');
  }
}

String _timeLine(DateTime when, int? dur) => dur == null
    ? DateFormat('h:mm a').format(when)
    : '${DateFormat('h:mm a').format(when)} – '
          '${DateFormat('h:mm a').format(when.add(Duration(minutes: dur)))}';

String _fmtDuration(int min) {
  if (min < 60) return '${min}m';
  final h = min ~/ 60, m = min % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// The status word as a small pill, coloured by disposition. Public so both the
/// share composer and the Day book render it the same way.
class ReportStatusPill extends StatelessWidget {
  const ReportStatusPill({super.key, required this.status, required this.due});
  final TaskStatus status;
  final DateTime? due;

  @override
  Widget build(BuildContext context) {
    final v = taskStatusVisual(status, due, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: v.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(v.icon, size: 15, color: v.color),
          const SizedBox(width: 6),
          Text(
            taskStatusLabel(status, due).toUpperCase(),
            style: TextStyle(
              color: v.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../areas/area_icons.dart' as ai;
import '../common/task_status_icon.dart';
import 'share_channels.dart';

/// §13 share a task or event as a **card image** for committed listeners and
/// participants — over WhatsApp, mail or any messaging app.
///
/// Two directions, chosen at the top:
///  • **Invitation** — before the fact: "you're invited" / "I've committed to".
///  • **Report** — after the fact: how it went, kept or fell short.
///
/// Either way the sharer decides *which fields travel*. Only ticked fields land
/// on the card and in the message; notes, restoration and scores stay off
/// unless deliberately turned on. The card is a real widget captured through a
/// [RepaintBoundary] at 3× — no image library, no server, nothing leaves the
/// device until a share target is picked.
class InviteCardScreen extends ConsumerStatefulWidget {
  const InviteCardScreen({
    super.key,
    required this.task,
    this.areaName,
    this.areaIconName,
    this.areaColor,
    this.initialMode = ShareMode.invitation,
  });
  final Task task;
  final String? areaName;

  /// The area's own icon + colour (§3.1) — the card is themed to the area
  /// rather than to Saara, so it reads as *your* commitment, not an advert.
  final String? areaIconName;
  final String? areaColor;

  /// Which direction to open in. A "Send report" entry point can deep-link
  /// straight to [ShareMode.report]; the user can still switch in-screen.
  final ShareMode initialMode;

  @override
  ConsumerState<InviteCardScreen> createState() => _InviteCardScreenState();
}

/// Before ([invitation]) vs after ([report]) the commitment.
enum ShareMode { invitation, report }

enum _CardStyle { light, dark, brand }

/// One shareable field. Each is offered only when the task actually carries it,
/// and each mode has its own relevant subset + defaults.
enum _Field {
  when,
  duration,
  joinLink,
  location,
  detailsLink,
  notes,
  area,
  status,
  outcome,
  restoration,
}

String _fieldLabel(_Field f) => switch (f) {
  _Field.when => 'Date & time',
  _Field.duration => 'Duration',
  _Field.joinLink => 'Join link',
  _Field.location => 'Location',
  _Field.detailsLink => 'Details link',
  _Field.notes => 'Notes',
  _Field.area => 'Area',
  _Field.status => 'Status',
  _Field.outcome => 'Outcome',
  _Field.restoration => 'Restoration',
};

// Which fields each mode offers, in display order.
const _invitationFields = [
  _Field.when,
  _Field.duration,
  _Field.joinLink,
  _Field.location,
  _Field.detailsLink,
  _Field.area,
  _Field.notes,
];
const _reportFields = [
  _Field.when,
  _Field.status,
  _Field.outcome,
  _Field.duration,
  _Field.location,
  _Field.area,
  _Field.notes,
  _Field.restoration,
];

class _InviteCardScreenState extends ConsumerState<InviteCardScreen> {
  final _cardKey = GlobalKey();
  _CardStyle _style = _CardStyle.brand;
  late ShareMode _mode = widget.initialMode;
  late Set<_Field> _fields = _defaultsFor(_mode);
  bool _busy = false;

  /// Optional one-line AI flourish. Off by default — the card is complete
  /// without it, and every generation costs the user's own API credits.
  String? _tagline;
  bool _aiBusy = false;

  bool get _isEvent => widget.task.kind == TaskKind.event;
  bool _on(_Field f) => _fields.contains(f);

  /// Does the task carry any data for [f]? A field with nothing behind it is
  /// never offered — no empty "Location:" lines, no dead toggles.
  bool _has(_Field f) {
    final t = widget.task;
    switch (f) {
      case _Field.when:
        return (t.scheduledStart ?? t.dueDate) != null;
      case _Field.duration:
        return t.durationMin != null;
      case _Field.joinLink:
        return (t.meetingLink ?? '').trim().isNotEmpty;
      case _Field.location:
        return (t.locationName ?? '').trim().isNotEmpty;
      case _Field.detailsLink:
        return (t.documentLink ?? '').trim().startsWith('http');
      case _Field.notes:
        return (t.notes ?? '').trim().isNotEmpty;
      case _Field.area:
        return (widget.areaName ?? '').trim().isNotEmpty;
      case _Field.status:
        return true; // a task always has a status to report
      case _Field.outcome:
        return t.completedAt != null || t.timeToCompleteMin != null;
      case _Field.restoration:
        return (t.reviewNotes ?? '').trim().isNotEmpty;
    }
  }

  List<_Field> _offered(ShareMode m) =>
      (m == ShareMode.invitation ? _invitationFields : _reportFields)
          .where(_has)
          .toList();

  /// Sensible defaults per mode: the outward-facing facts on, the private ones
  /// (notes, restoration) off until the sharer opts in.
  Set<_Field> _defaultsFor(ShareMode m) {
    final all = _offered(m).toSet();
    final off = m == ShareMode.invitation
        ? {_Field.notes}
        : {_Field.duration, _Field.location, _Field.notes, _Field.restoration};
    return all.difference(off);
  }

  void _setMode(ShareMode m) => setState(() {
    _mode = m;
    _fields = _defaultsFor(m); // reset to the new mode's relevant defaults
  });

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 3× a 360pt card → 1080×1080, the size social platforms want.
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw 'Could not render the card.';
      final bytes = data.buffer.asUint8List();

      final safe = widget.task.title
          .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
          .trim()
          .replaceAll(' ', '-');
      final name = 'saara-${_mode == ShareMode.report ? 'report' : 'invite'}'
          '${safe.isEmpty ? '' : '-$safe'}.png';

      // Desktop has no share sheet that lists WhatsApp/mail — save the image to
      // Downloads and point the user at it, mirroring the Day Card.
      if (isDesktop) {
        final dir =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              content: Text('Card saved to ${file.path}'),
              action: SnackBarAction(
                label: 'Open folder',
                onPressed: () => launchUrl(Uri.file(dir.path)),
              ),
            ),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      // Send the card *and* the details as message text, so any join/details
      // link stays tappable — it can't be on the image itself.
      await Share.shareXFiles([XFile(file.path)], text: _messageText());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// One short line for the card, using the user's own key. Text only — see
  /// the note by the button on why this isn't image generation.
  Future<void> _generateTagline() async {
    setState(() => _aiBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final config = await ref.read(aiConfigProvider.future);
      if (!config.isConfigured) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Add an AI key in Settings → Saara AI.'),
          ),
        );
        return;
      }
      final when = widget.task.scheduledStart ?? widget.task.dueDate;
      final subject = _mode == ShareMode.report
          ? 'a short reflection to sit on a card reporting how this '
                '${_isEvent ? 'event' : 'commitment'} went'
          : 'a shareable card for this '
                '${_isEvent ? 'event invitation' : 'personal commitment'}';
      final prompt =
          'Write ONE short line (max 12 words) to sit on $subject.\n'
          'Title: ${widget.task.title}\n'
          '${widget.areaName == null ? '' : 'Area: ${widget.areaName}\n'}'
          '${when == null ? '' : 'When: ${DateFormat('EEEE d MMMM, h:mm a').format(when)}\n'}'
          '${_mode == ShareMode.report ? 'Outcome: ${taskStatusLabel(widget.task.status, widget.task.dueDate)}\n' : ''}'
          'Warm and grounded, never salesy or hyped. No hashtags, no emoji, no '
          'quotation marks. Return only the line.';
      final res = await ref
          .read(llmServiceProvider)
          .extractFromTextHealing(config, prompt: prompt);
      if (res.usedModel != null && config.apiKey != null) {
        await ref
            .read(aiConfigStoreProvider)
            .save(
              provider: config.provider,
              apiKey: config.apiKey!,
              model: res.usedModel!,
            );
        ref.invalidate(aiConfigProvider);
      }
      if (mounted) {
        setState(
          () => _tagline = res.text
              .trim()
              .replaceAll('"', '')
              .replaceAll('\n', ' '),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  /// The share as **text** — the message that accompanies the card, and the
  /// text-only share. Honours the field toggles and the chosen mode.
  ///
  /// Links live here rather than on the card — a URL printed into an image is
  /// dead, but in the message body it stays tappable in WhatsApp, mail, etc.
  String _messageText() =>
      _mode == ShareMode.report ? _reportText() : _inviteText();

  String _inviteText() {
    final t = widget.task;
    final when = t.scheduledStart ?? t.dueDate;
    final dur = t.durationMin;
    final join = (t.meetingLink ?? '').trim();
    final b = StringBuffer()
      ..writeln(_isEvent ? "You're invited" : "I've committed to")
      ..writeln()
      ..writeln(t.title);

    if (_on(_Field.when) && when != null) {
      b.writeln(DateFormat('EEEE, d MMMM yyyy').format(when));
      b.writeln(_timeLine(when, _on(_Field.duration) ? dur : null));
    }
    // The join link goes *first*, on its own, clearly labelled: it's the one
    // thing someone opening this in a hurry is looking for, so it must not be
    // buried under the venue and document lines.
    if (_on(_Field.joinLink) && join.isNotEmpty) {
      b
        ..writeln()
        ..writeln('▶ ${_joinLabel(join)}:')
        ..writeln(join);
    }
    if (_on(_Field.location) && (t.locationName ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('Where: ${t.locationName!.trim()}');
    }
    if (_on(_Field.detailsLink) &&
        (t.documentLink ?? '').trim().startsWith('http')) {
      b.writeln('Details: ${t.documentLink!.trim()}');
    }
    if (_on(_Field.notes) && (t.notes ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln(t.notes!.trim());
    }
    _appendTagline(b);
    return b.toString().trimRight();
  }

  String _reportText() {
    final t = widget.task;
    final when = t.scheduledStart ?? t.dueDate;
    final b = StringBuffer()
      ..writeln(_reportHeadline())
      ..writeln()
      ..writeln(t.title);

    if (_on(_Field.when) && when != null) {
      b.writeln(DateFormat('EEEE, d MMMM yyyy').format(when));
      b.writeln(_timeLine(when, _on(_Field.duration) ? t.durationMin : null));
    }
    if (_on(_Field.status)) {
      b.writeln('Status: ${taskStatusLabel(t.status, t.dueDate)}');
    }
    if (_on(_Field.outcome)) {
      if (t.completedAt != null) {
        b.writeln('Completed: ${DateFormat('d MMM, h:mm a').format(t.completedAt!)}');
      }
      if (t.timeToCompleteMin != null) {
        b.writeln('Took: ${_fmtDuration(t.timeToCompleteMin!)}');
      }
    }
    if (_on(_Field.location) && (t.locationName ?? '').trim().isNotEmpty) {
      b.writeln('Where: ${t.locationName!.trim()}');
    }
    if (_on(_Field.notes) && (t.notes ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln(t.notes!.trim());
    }
    if (_on(_Field.restoration) && (t.reviewNotes ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('Restoring: ${t.reviewNotes!.trim()}');
    }
    _appendTagline(b);
    return b.toString().trimRight();
  }

  void _appendTagline(StringBuffer b) {
    if (_tagline != null && _tagline!.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln(_tagline!.trim());
    }
  }

  String _reportHeadline() {
    switch (widget.task.status) {
      case TaskStatus.completed:
        return 'Kept my word';
      case TaskStatus.cancelled:
        return 'I fell short';
      case TaskStatus.missed:
        return 'I missed this';
      case TaskStatus.rejected:
        return 'Declined';
      default:
        return 'Where this stands';
    }
  }

  static String _timeLine(DateTime when, int? dur) => dur == null
      ? DateFormat('h:mm a').format(when)
      : '${DateFormat('h:mm a').format(when)} – '
            '${DateFormat('h:mm a').format(when.add(Duration(minutes: dur)))}';

  static String _fmtDuration(int min) {
    if (min < 60) return '${min}m';
    final h = min ~/ 60, m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  /// Name the join button after the platform so the recipient knows what opens.
  static String _joinLabel(String link) {
    final l = link.toLowerCase();
    if (l.contains('meet.google')) return 'Join Google Meet';
    if (l.contains('zoom.')) return 'Join Zoom';
    if (l.contains('teams.')) return 'Join Microsoft Teams';
    if (l.contains('webex')) return 'Join Webex';
    return 'Join the meeting';
  }

  Future<void> _shareText() async {
    await shareTextViaChannels(
      context,
      text: _messageText(),
      subject: _mode == ShareMode.report
          ? '${widget.task.title} — ${_reportHeadline().toLowerCase()}'
          : _isEvent
          ? "You're invited — ${widget.task.title}"
          : widget.task.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final offered = _offered(_mode);
    return Scaffold(
      appBar: AppBar(title: const Text('Share')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: _Card(
                task: widget.task,
                areaName: widget.areaName,
                areaIconName: widget.areaIconName,
                areaColor: widget.areaColor,
                tagline: _tagline,
                style: _style,
                mode: _mode,
                fields: _fields,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Direction: invitation (before) vs report (after).
          Center(
            child: SegmentedButton<ShareMode>(
              segments: const [
                ButtonSegment(
                  value: ShareMode.invitation,
                  icon: Icon(Icons.mail_outline, size: 18),
                  label: Text('Invitation'),
                ),
                ButtonSegment(
                  value: ShareMode.report,
                  icon: Icon(Icons.assignment_turned_in_outlined, size: 18),
                  label: Text('Report'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
          ),
          const SizedBox(height: 16),
          // Field selection — tick what travels. Only populated fields appear.
          Text(
            'Include',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          if (offered.isEmpty)
            Text(
              'Just the title — this ${_isEvent ? 'event' : 'task'} has no '
              'other details to add yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final f in offered)
                  FilterChip(
                    label: Text(_fieldLabel(f)),
                    selected: _on(f),
                    onSelected: (v) => setState(
                      () => v ? _fields.add(f) : _fields.remove(f),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          Center(
            child: SegmentedButton<_CardStyle>(
              segments: const [
                ButtonSegment(value: _CardStyle.brand, label: Text('Brand')),
                ButtonSegment(value: _CardStyle.light, label: Text('Light')),
                ButtonSegment(value: _CardStyle.dark, label: Text('Dark')),
              ],
              selected: {_style},
              onSelectionChanged: (s) => setState(() => _style = s.first),
            ),
          ),
          const SizedBox(height: 8),
          // Optional, opt-in flourish. Deliberately a *line of text*, not a
          // generated image: neither BYOK provider gives reliable image
          // generation, and a one-line completion costs a fraction of a cent
          // where an image would be orders of magnitude more.
          Center(
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: _aiBusy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _tagline == null ? 'Add a line with AI' : 'Rewrite with AI',
                  ),
                  onPressed: _aiBusy ? null : _generateTagline,
                ),
                if (_tagline != null)
                  TextButton(
                    onPressed: () => setState(() => _tagline = null),
                    child: const Text('Remove'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(
              _mode == ShareMode.report ? 'Share report card' : 'Share card',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _busy ? null : _share,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.notes),
            label: const Text('Share as text only'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _shareText,
          ),
          const SizedBox(height: 12),
          Text(
            'The card is a 1080×1080 image, sent with the details as message '
            'text — so a join or details link stays tappable (a link printed '
            'into an image would not be). Text-only sends just those details.\n\n'
            'Only the fields you tick are shared. Notes, restoration and your '
            'scores are never shared unless you turn them on.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The card itself — fixed 360×360 logical, captured at 3×.
class _Card extends StatelessWidget {
  const _Card({
    required this.task,
    required this.style,
    required this.mode,
    required this.fields,
    this.areaName,
    this.areaIconName,
    this.areaColor,
    this.tagline,
  });
  final Task task;
  final _CardStyle style;
  final ShareMode mode;
  final Set<_Field> fields;
  final String? areaName;
  final String? areaIconName;
  final String? areaColor;
  final String? tagline;

  static const _brand = Color(0xFFCC1A1A);

  bool _on(_Field f) => fields.contains(f);

  @override
  Widget build(BuildContext context) {
    final isEvent = task.kind == TaskKind.event;
    final isReport = mode == ShareMode.report;
    final when = task.scheduledStart ?? task.dueDate;
    final dur = task.durationMin;

    // The area's own colour leads; Saara's red is only the fallback.
    final areaTint = ai.areaColor(areaColor) ?? _brand;
    final icon = ai.areaIcon(areaIconName);

    final (bg, ink, muted, accent) = switch (style) {
      _CardStyle.brand => (
        areaTint,
        Colors.white,
        Colors.white70,
        Colors.white,
      ),
      _CardStyle.light => (
        const Color(0xFFFAF8F6),
        const Color(0xFF1B1613),
        const Color(0xFF6D635C),
        areaTint,
      ),
      _CardStyle.dark => (
        const Color(0xFF141110),
        const Color(0xFFF2ECE7),
        const Color(0xFFA99F97),
        _lighten(areaTint),
      ),
    };

    final (eyebrowIcon, eyebrow) = isReport
        ? _reportEyebrow()
        : (
            isEvent ? Icons.event : Icons.check_circle_outline,
            isEvent ? "YOU'RE INVITED" : "I'VE COMMITTED TO",
          );

    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Oversized area glyph as a watermark — the "banner" for this area.
          Positioned(
            right: -28,
            bottom: -24,
            child: Icon(icon, size: 190, color: accent.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(eyebrowIcon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  task.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: task.title.length > 46 ? 24 : 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_on(_Field.when) && when != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    DateFormat('EEEE, d MMMM').format(when),
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _InviteCardScreenState._timeLine(
                      when,
                      _on(_Field.duration) ? dur : null,
                    ),
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                ],
                // Report: status + outcome read where the join pill would sit.
                if (isReport && _on(_Field.status)) ...[
                  const SizedBox(height: 10),
                  _StatusPill(status: task.status, due: task.dueDate),
                ],
                if (isReport && _on(_Field.outcome)) ...[
                  const SizedBox(height: 8),
                  if (task.completedAt != null)
                    Text(
                      'Completed ${DateFormat('d MMM, h:mm a').format(task.completedAt!)}',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  if (task.timeToCompleteMin != null)
                    Text(
                      'Took ${_InviteCardScreenState._fmtDuration(task.timeToCompleteMin!)}',
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                ],
                // Invitation: a video-meeting's one wanted thing is the join
                // link. The URL can't live on an image (it'd be dead), so the
                // card shows a bold JOIN pill pointing to the message, where the
                // tappable link sits at the top.
                if (!isReport &&
                    _on(_Field.joinLink) &&
                    (task.meetingLink ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_rounded, size: 16, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          _joinLabelForCard(task.meetingLink!).toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap the link in the message to join',
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
                if (_on(_Field.location) &&
                    (task.locationName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 14, color: muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.locationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_on(_Field.notes) && (task.notes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 13, height: 1.25),
                  ),
                ],
                if (isReport &&
                    _on(_Field.restoration) &&
                    (task.reviewNotes ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restoring: ${task.reviewNotes!.trim()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.25,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (tagline != null && tagline!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    tagline!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const Spacer(),
                if (_on(_Field.area) && (areaName ?? '').isNotEmpty) ...[
                  Divider(color: muted.withValues(alpha: 0.3), height: 1),
                  const SizedBox(height: 12),
                  // The area is the badge — its own icon and name, not a Saara advert.
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          areaName!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Eyebrow (icon + label) for a report card, keyed to how the word landed.
  (IconData, String) _reportEyebrow() {
    switch (task.status) {
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

  /// Short platform-named label for the card's JOIN pill (kept snappy — the
  /// full "Join Google Meet" phrasing lives in the message text).
  static String _joinLabelForCard(String link) {
    final l = link.toLowerCase();
    if (l.contains('meet.google')) return 'Google Meet';
    if (l.contains('zoom.')) return 'Zoom';
    if (l.contains('teams.')) return 'Microsoft Teams';
    if (l.contains('webex')) return 'Webex';
    return 'Join meeting';
  }

  /// Slightly lift an area colour so it stays legible on the dark card.
  static Color _lighten(Color c) => Color.lerp(c, Colors.white, 0.45) ?? c;
}

/// The status word as a small pill on the report card, coloured by disposition.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.due});
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

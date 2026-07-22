import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import '../areas/area_icons.dart' as ai;
import 'share_channels.dart';

/// §13 share a task or event as a **card image** for social/messaging.
///
/// The card is a real widget captured through a [RepaintBoundary] at 3× — no
/// image library, no server, nothing leaves the device until the user picks a
/// share target.
class InviteCardScreen extends ConsumerStatefulWidget {
  const InviteCardScreen({
    super.key,
    required this.task,
    this.areaName,
    this.areaIconName,
    this.areaColor,
  });
  final Task task;
  final String? areaName;

  /// The area's own icon + colour (§3.1) — the card is themed to the area
  /// rather than to Saara, so it reads as *your* commitment, not an advert.
  final String? areaIconName;
  final String? areaColor;

  @override
  ConsumerState<InviteCardScreen> createState() => _InviteCardScreenState();
}

enum _CardStyle { light, dark, brand }

class _InviteCardScreenState extends ConsumerState<InviteCardScreen> {
  final _cardKey = GlobalKey();
  _CardStyle _style = _CardStyle.brand;
  bool _busy = false;

  /// Optional one-line AI flourish. Off by default — the card is complete
  /// without it, and every generation costs the user's own API credits.
  String? _tagline;
  bool _aiBusy = false;

  bool get _isEvent => widget.task.kind == TaskKind.event;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 3× a 360pt card → 1080×1080, the size social platforms want.
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw 'Could not render the card.';

      final dir = await getTemporaryDirectory();
      final safe = widget.task.title
          .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
          .trim()
          .replaceAll(' ', '-');
      final file = File('${dir.path}/saara-$safe.png');
      await file.writeAsBytes(data.buffer.asUint8List());

      // Send the card *and* the details as message text, so any join/details
      // link stays tappable — it can't be on the image itself.
      await Share.shareXFiles([XFile(file.path)], text: _inviteText());
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
      final prompt =
          'Write ONE short line (max 12 words) to sit on a shareable card for '
          'this ${_isEvent ? 'event invitation' : 'personal commitment'}.\n'
          'Title: ${widget.task.title}\n'
          '${widget.areaName == null ? '' : 'Area: ${widget.areaName}\n'}'
          '${when == null ? '' : 'When: ${DateFormat('EEEE d MMMM, h:mm a').format(when)}\n'}'
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

  /// The invite as **text**. Used two ways: as the message that accompanies the
  /// card image, and on its own for a text-only share.
  ///
  /// Links live here rather than on the card — a URL printed into an image is
  /// dead, but in the message body it stays tappable in WhatsApp, mail, etc.
  String _inviteText() {
    final t = widget.task;
    final when = t.scheduledStart ?? t.dueDate;
    final dur = t.durationMin;
    final join = (t.meetingLink ?? '').trim();
    final b = StringBuffer()
      ..writeln(_isEvent ? "You're invited" : "I've committed to")
      ..writeln()
      ..writeln(t.title);

    if (when != null) {
      b.writeln(DateFormat('EEEE, d MMMM yyyy').format(when));
      b.writeln(
        dur == null
            ? DateFormat('h:mm a').format(when)
            : '${DateFormat('h:mm a').format(when)} – '
                  '${DateFormat('h:mm a').format(when.add(Duration(minutes: dur)))}',
      );
    }
    // The join link goes *first*, on its own, clearly labelled: it's the one
    // thing someone opening this in a hurry is looking for, so it must not be
    // buried under the venue and document lines.
    if (join.isNotEmpty) {
      b
        ..writeln()
        ..writeln('▶ ${_joinLabel(join)}:')
        ..writeln(join);
    }
    if ((t.locationName ?? '').trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln('Where: ${t.locationName!.trim()}');
    }
    if ((t.documentLink ?? '').trim().isNotEmpty &&
        (t.documentLink!.startsWith('http'))) {
      b.writeln('Details: ${t.documentLink!.trim()}');
    }
    if (_tagline != null && _tagline!.trim().isNotEmpty) {
      b
        ..writeln()
        ..writeln(_tagline!.trim());
    }
    return b.toString().trimRight();
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
      text: _inviteText(),
      subject: _isEvent
          ? "You're invited — ${widget.task.title}"
          : widget.task.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share as card')),
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
              ),
            ),
          ),
          const SizedBox(height: 24),
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
            label: const Text('Share card'),
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
            'Only the title, time, place and links are shared — notes, captures '
            'and your scores never are.',
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
    this.areaName,
    this.areaIconName,
    this.areaColor,
    this.tagline,
  });
  final Task task;
  final _CardStyle style;
  final String? areaName;
  final String? areaIconName;
  final String? areaColor;
  final String? tagline;

  static const _brand = Color(0xFFCC1A1A);

  @override
  Widget build(BuildContext context) {
    final isEvent = task.kind == TaskKind.event;
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
                    Icon(
                      isEvent ? Icons.event : Icons.check_circle_outline,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEvent ? "YOU'RE INVITED" : 'I\'VE COMMITTED TO',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
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
                if (when != null) ...[
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
                    dur == null
                        ? DateFormat('h:mm a').format(when)
                        : '${DateFormat('h:mm a').format(when)} – '
                              '${DateFormat('h:mm a').format(when.add(Duration(minutes: dur)))}',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                ],
                // A video-meeting has one thing the recipient wants: the join
                // link. The URL can't live on an image (it'd be dead), so the
                // card shows a bold JOIN pill that points them to the message,
                // where the tappable link sits at the top.
                if ((task.meetingLink ?? '').trim().isNotEmpty) ...[
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
                if ((task.locationName ?? '').trim().isNotEmpty) ...[
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
                        (areaName ?? '').toUpperCase(),
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
            ),
          ),
        ],
      ),
    );
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

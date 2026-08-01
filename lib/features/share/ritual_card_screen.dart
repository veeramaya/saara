import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/daily_quote.dart';
import 'share_channels.dart';

/// §13 One day, two faces. The **front** is the morning declaration — the word
/// you gave; the **back** is the evening close — what you honored and how you
/// restored. Sharing the close only makes sense with the declaration beside it,
/// so the shared image carries both faces at once (§1 — the people you gave your
/// word to are the mirror).
class DayCardData {
  const DayCardData({
    required this.day,
    required this.morningQuote,
    required this.eveningQuote,
    required this.declaration,
    this.declarationSub,
    this.closed = false,
    this.honor,
    this.restoring,
    this.restorationWords,
  });

  final DateTime day;
  final DailyQuote morningQuote;
  final DailyQuote eveningQuote;

  /// Front face — "3 commitments today" and, if any, "1 with my word on it".
  final String declaration;
  final String? declarationSub;

  /// Whether the day has been closed yet. When false (a morning share) the back
  /// simply says the day is still open.
  final bool closed;

  /// Back face — "Kept my word 5 times today", "Restoring 2", and the one line
  /// of restoration the user wrote at close.
  final String? honor;
  final String? restoring;
  final String? restorationWords;
}

class RitualCardScreen extends StatefulWidget {
  const RitualCardScreen({super.key, required this.data});
  final DayCardData data;

  @override
  State<RitualCardScreen> createState() => _RitualCardScreenState();
}

class _RitualCardScreenState extends State<RitualCardScreen> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  DayCardData get _d => widget.data;

  Future<void> _shareCard() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw 'Could not render the card.';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/saara-day.png');
      await file.writeAsBytes(data.buffer.asUint8List());
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

  Future<void> _shareText() async {
    await shareTextViaChannels(
      context,
      text: _messageText(),
      subject: 'My day — via Saara',
    );
  }

  /// The invitation that travels with the card: the declaration, the close, and
  /// the restoration — first-person, naming the reader as a witness.
  String _messageText() {
    final date = DateFormat('EEEE, d MMMM').format(_d.day);
    final b = StringBuffer()
      ..writeln('My day — $date')
      ..writeln()
      ..writeln('🌅 Opening: ${_d.declaration}');
    if (_d.declarationSub != null) b.writeln('   ${_d.declarationSub}');
    if (_d.closed) {
      b.writeln('🌙 Closing: ${_d.honor ?? "a day's honest close."}');
      if (_d.restoring != null) b.writeln('   ${_d.restoring}');
      if (_d.restorationWords != null && _d.restorationWords!.isNotEmpty) {
        b.writeln('   “${_d.restorationWords}”');
      }
    }
    b
      ..writeln()
      ..writeln(
        "You're one of the people I've given my word to — thank you for being "
        'my mirror.',
      )
      ..writeln('— via Saara');
    return b.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share your day')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: _FlipCard(
                  front: _DayFace(data: _d, open: true),
                  back: _DayFace(data: _d, open: false),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tap the card to flip — open on one side, close on the other.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 20),
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
                onPressed: _busy ? null : _shareCard,
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
                'The card is shared as one image showing both faces — so the '
                'close is always read with the morning it belongs to. Only '
                "what's on the card is shared; your tasks, notes and scores "
                'never are.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          // The share target: both faces stacked into one image. Kept in the
          // tree (so it lays out and paints its own layer) but translated far
          // off-screen so it never shows behind the preview.
          Positioned(
            left: 0,
            top: 0,
            child: Transform.translate(
              offset: const Offset(-5000, 0),
              child: RepaintBoundary(
                key: _captureKey,
                child: _DayComposite(data: _d),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tap-to-flip card: [front] on one side, [back] on the other, with a 3D
/// rotation about the Y axis.
class _FlipCard extends StatefulWidget {
  const _FlipCard({required this.front, required this.back});
  final Widget front;
  final Widget back;

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_ctrl.isAnimating) return;
    _ctrl.value < 0.5 ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * math.pi;
          final showFront = angle <= math.pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? widget.front
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.back,
                  ),
          );
        },
      ),
    );
  }
}

/// Both faces stacked — the single shareable image.
class _DayComposite extends StatelessWidget {
  const _DayComposite({required this.data});
  final DayCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E0E12),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DayFace(data: data, open: true),
          const SizedBox(height: 10),
          _DayFace(data: data, open: false),
        ],
      ),
    );
  }
}

/// One face of the day — sunrise for the open, dusk for the close.
class _DayFace extends StatelessWidget {
  const _DayFace({required this.data, required this.open});
  final DayCardData data;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final (top, bottom, ink, muted, accent) = open
        ? (
            const Color(0xFFF4A24C),
            const Color(0xFFCC5A2E),
            Colors.white,
            Colors.white70,
            Colors.white,
          )
        : (
            const Color(0xFF2B2E5B),
            const Color(0xFF15162B),
            const Color(0xFFF2ECE7),
            const Color(0xFFB9B4CC),
            const Color(0xFFE7C46B),
          );
    final quote = open ? data.morningQuote : data.eveningQuote;

    return Container(
      width: 360,
      height: 340,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Icon(
              open ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 150,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      open
                          ? Icons.wb_twilight_rounded
                          : Icons.bedtime_rounded,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      open ? 'OPENING MY DAY' : 'CLOSING MY DAY',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM').format(data.day),
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                  ],
                ),
                const Spacer(),
                ..._body(ink, muted),
                const SizedBox(height: 14),
                Text(
                  '“${quote.text}”',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '— ${quote.author}',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
                const Spacer(),
                Divider(color: muted.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'SAARA',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Give your word. Keep it.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
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

  /// The middle block differs by face: the declaration on the front; honor,
  /// restoring and the restoration line on the back (or "still open" if the day
  /// hasn't been closed yet — a morning share).
  List<Widget> _body(Color ink, Color muted) {
    final headlineStyle = TextStyle(
      color: ink,
      fontSize: 26,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );
    final subStyle = TextStyle(
      color: muted,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );

    if (open) {
      return [
        Text(
          data.declaration,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: headlineStyle,
        ),
        if (data.declarationSub != null) ...[
          const SizedBox(height: 6),
          Text(data.declarationSub!, style: subStyle),
        ],
      ];
    }

    if (!data.closed) {
      return [
        Text('The day is still open.', style: headlineStyle),
        const SizedBox(height: 6),
        Text("I'll close it tonight.", style: subStyle),
      ];
    }

    return [
      Text(
        data.honor ?? "A day's honest close.",
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: headlineStyle,
      ),
      if (data.restoring != null) ...[
        const SizedBox(height: 6),
        Text(data.restoring!, style: subStyle),
      ],
      if (data.restorationWords != null &&
          data.restorationWords!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          '“${data.restorationWords}”',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 14,
            height: 1.3,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ];
  }
}

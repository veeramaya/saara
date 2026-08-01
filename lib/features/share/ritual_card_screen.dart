import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/daily_quote.dart';
import 'share_channels.dart';

/// §13 The data behind a shareable ritual card — computed by the Open/Close
/// screens at share time and handed in whole, so this screen stays a pure view.
class RitualShareData {
  const RitualShareData({
    required this.morning,
    required this.quote,
    required this.day,
    required this.headline,
    this.detail,
  });

  /// True for "Open your day", false for "Close your day".
  final bool morning;
  final DailyQuote quote;
  final DateTime day;

  /// The one big line — e.g. "3 commitments today" or "Kept my word 5 times".
  final String headline;

  /// An optional grounding second line — e.g. "1 with my word on it" or
  /// "Restoring 2". Kept honest: a broken word is named, not hidden.
  final String? detail;
}

/// §13 Share the day's ritual as a **card image** to your committed listeners —
/// the people you gave your word to are the mirror (§1). Rendered on-device
/// through a [RepaintBoundary]; nothing leaves until you pick a share target.
class RitualCardScreen extends StatefulWidget {
  const RitualCardScreen({super.key, required this.data});
  final RitualShareData data;

  @override
  State<RitualCardScreen> createState() => _RitualCardScreenState();
}

class _RitualCardScreenState extends State<RitualCardScreen> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  RitualShareData get _d => widget.data;

  Future<void> _shareCard() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw 'Could not render the card.';

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/saara-${_d.morning ? 'open' : 'close'}-day.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      // The card is the image; the message text carries the invitation so it
      // reads as a person reaching out, not a forwarded picture.
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
      subject: _d.morning ? 'Opening my day' : 'Closing my day',
    );
  }

  /// The invitation that travels with the card. Warm, first-person, and it
  /// names the reader as a witness — that's what makes someone jump in.
  String _messageText() {
    final date = DateFormat('EEEE, d MMMM').format(_d.day);
    final b = StringBuffer()
      ..writeln(_d.morning ? 'Opening my day 🌅  $date' : 'Closing my day 🌙  $date')
      ..writeln()
      ..writeln(_d.headline);
    if (_d.detail != null && _d.detail!.trim().isNotEmpty) {
      b.writeln(_d.detail!.trim());
    }
    b
      ..writeln()
      ..writeln('“${_d.quote.text}”')
      ..writeln('— ${_d.quote.author}')
      ..writeln()
      ..writeln(
        _d.morning
            ? "You're one of the people I've given my word to — here to keep me "
                  'honest today.'
            : 'Thank you for witnessing my word today.',
      )
      ..writeln('— via Saara');
    return b.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_d.morning ? 'Share your open' : 'Share your close'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: _RitualCard(data: _d),
            ),
          ),
          const SizedBox(height: 24),
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
            'The card is an image sent with your note as message text, so it '
            'lands well in WhatsApp, mail or anywhere. Only what you see here is '
            'shared — your tasks, notes and scores never are.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// The card itself — fixed 360×420 logical, captured at 3× → 1080×1260.
class _RitualCard extends StatelessWidget {
  const _RitualCard({required this.data});
  final RitualShareData data;

  @override
  Widget build(BuildContext context) {
    // Two curated palettes: a warm sunrise to open, a deep dusk to close.
    final (top, bottom, ink, muted, accent) = data.morning
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

    return Container(
      width: 360,
      height: 420,
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
            right: -26,
            top: -20,
            child: Icon(
              data.morning ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 168,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      data.morning
                          ? Icons.wb_twilight_rounded
                          : Icons.bedtime_rounded,
                      size: 16,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.morning ? 'OPENING MY DAY' : 'CLOSING MY DAY',
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('d MMM').format(data.day),
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.headline,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (data.detail != null && data.detail!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    data.detail!.trim(),
                    style: TextStyle(
                      color: muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  '“${data.quote.text}”',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '— ${data.quote.author}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const Spacer(),
                Divider(color: muted.withValues(alpha: 0.3), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'SAARA',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
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
                          fontSize: 11,
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
}

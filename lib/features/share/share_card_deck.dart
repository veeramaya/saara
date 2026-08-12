import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform.dart';
import '../areas/area_icons.dart' as ai;

/// Shared "shareable card" toolkit (§13). Every share surface — a task/event
/// invitation or report, the committed-listener weekly report, an event's full
/// report — is built from the same pieces so they read as one family:
///
///  • [CardStyle] / [CardPalette] — the three looks and their resolved colours.
///  • [CardFrame] — one 360×360 card: watermark, eyebrow, body, area badge.
///  • [PagedViewer] — the in-app viewer: swipe or tap through the pages.
///  • [ReportComposite] — every page stacked into the single shareable image.
///  • [shareOrSaveCardImage] — capture the composite and hand it off (mobile
///    share sheet) or save it to Downloads (desktop).

enum CardStyle { light, dark, brand }

/// The resolved colours for a card, derived once from the style + area colour.
class CardPalette {
  const CardPalette({
    required this.bg,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.icon,
  });

  final Color bg, ink, muted, accent;
  final IconData icon;

  static const brand = Color(0xFFCC1A1A);

  factory CardPalette.of(CardStyle style, String? areaColor, String? areaIcon) {
    // The area's own colour leads; Saara's red is only the fallback.
    final tint = ai.areaColor(areaColor) ?? brand;
    final (bg, ink, muted, accent) = switch (style) {
      CardStyle.brand => (tint, Colors.white, Colors.white70, Colors.white),
      CardStyle.light => (
        const Color(0xFFFAF8F6),
        const Color(0xFF1B1613),
        const Color(0xFF6D635C),
        tint,
      ),
      CardStyle.dark => (
        const Color(0xFF141110),
        const Color(0xFFF2ECE7),
        const Color(0xFFA99F97),
        Color.lerp(tint, Colors.white, 0.45) ?? tint,
      ),
    };
    return CardPalette(
      bg: bg,
      ink: ink,
      muted: muted,
      accent: accent,
      icon: ai.areaIcon(areaIcon),
    );
  }
}

/// A 360×360 card shell: watermark, an eyebrow at the top, the given [body] in
/// the middle, and an optional badge at the foot.
class CardFrame extends StatelessWidget {
  const CardFrame({
    super.key,
    required this.palette,
    required this.eyebrowIcon,
    required this.eyebrow,
    required this.body,
    this.badgeName,
  });

  final CardPalette palette;
  final IconData eyebrowIcon;
  final String eyebrow;
  final List<Widget> body;

  /// The foot badge (usually the area) — omitted when null/empty.
  final String? badgeName;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Oversized area glyph as a watermark — the "banner" for this area.
          Positioned(
            right: -28,
            bottom: -24,
            child: Icon(
              p.icon,
              size: 190,
              color: p.accent.withValues(alpha: 0.10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(eyebrowIcon, size: 16, color: p.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ...body,
                const Spacer(),
                if ((badgeName ?? '').isNotEmpty) ...[
                  Divider(color: p.muted.withValues(alpha: 0.3), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(p.icon, size: 16, color: p.accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          badgeName!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.accent,
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
}

/// The in-app viewer: swipe (or tap) through the pages, with a dot indicator
/// and an "n / N" counter. Preview only — the shared image is the stacked
/// [ReportComposite].
class PagedViewer extends StatelessWidget {
  const PagedViewer({
    super.key,
    required this.controller,
    required this.pages,
    required this.page,
    required this.onPageChanged,
    required this.dotColor,
  });

  final PageController controller;
  final List<Widget> pages;
  final int page;
  final ValueChanged<int> onPageChanged;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 360,
          height: 360,
          child: GestureDetector(
            // Tap to advance (wrapping), as well as swipe — a flip-card feel.
            onTap: () {
              final next = (page + 1) % pages.length;
              controller.animateToPage(
                next,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            },
            child: PageView(
              controller: controller,
              onPageChanged: onPageChanged,
              children: [for (final pg in pages) Center(child: pg)],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == page ? 9 : 7,
                height: i == page ? 9 : 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == page
                      ? dotColor
                      : dotColor.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${page + 1} / ${pages.length}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Every page stacked — the single shareable image for a multi-page report.
class ReportComposite extends StatelessWidget {
  const ReportComposite({super.key, required this.pages, required this.style});
  final List<Widget> pages;
  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    final bg = style == CardStyle.light
        ? const Color(0xFFEDE9E5)
        : const Color(0xFF0E0E12);
    return Container(
      color: bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < pages.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            pages[i],
          ],
        ],
      ),
    );
  }
}

/// Capture whatever [captureKey] wraps (a single card or a [ReportComposite])
/// to a PNG at 3×, then hand it off: the OS share sheet on mobile (with [text]
/// as the message body), or a save to Downloads on desktop. Throws on a render
/// failure so the caller can surface it.
Future<void> shareOrSaveCardImage(
  BuildContext context, {
  required GlobalKey captureKey,
  required String text,
  required String fileBase,
}) async {
  final boundary =
      captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) throw 'Could not render the card.';
  final bytes = data.buffer.asUint8List();
  final name = '$fileBase.png';

  if (isDesktop) {
    final dir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    if (context.mounted) {
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
  // Send the card *and* the details as message text, so any link stays
  // tappable — it can't be on the image itself.
  await Share.shareXFiles([XFile(file.path)], text: text);
}

/// The Brand / Light / Dark selector, shared by every card screen.
class CardStyleSelector extends StatelessWidget {
  const CardStyleSelector({
    super.key,
    required this.style,
    required this.onChanged,
  });
  final CardStyle style;
  final ValueChanged<CardStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CardStyle>(
      segments: const [
        ButtonSegment(value: CardStyle.brand, label: Text('Brand')),
        ButtonSegment(value: CardStyle.light, label: Text('Light')),
        ButtonSegment(value: CardStyle.dark, label: Text('Dark')),
      ],
      selected: {style},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// A safe, sensible file-name fragment from an arbitrary title.
String cardFileSlug(String title) => title
    .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), '')
    .trim()
    .replaceAll(RegExp(r'\s+'), '-');

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/reliability.dart';
import '../../domain/sense_interpreter.dart';

/// Shared line-art drawing primitives for the sense animations (loader +
/// completion). Kept small and self-contained; colours are passed in so both
/// widgets tint to the theme.
class _Draw {
  _Draw(this.c, this.brand, this.ink, this.muted);
  final Canvas c;
  final Color brand, ink, muted;

  Paint _s(double w, [double a = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..color = brand.withValues(alpha: a)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = w
    ..isAntiAlias = true;

  void actor(double x, double baseY, double s, int face, double t) {
    final shoulderY = baseY - 70 * s, hipY = baseY - 34 * s;
    c.drawLine(Offset(x, shoulderY), Offset(x, hipY), _s(2.6 * s));
    final sw = math.sin(t * 2.6) * 0.35,
        sw2 = math.sin(t * 2.6 + math.pi) * 0.35;
    _limb(x, shoulderY, math.pi / 2 + 0.5 * face + sw, 24 * s, 2.6 * s);
    _limb(x, shoulderY, math.pi / 2 - 0.5 * face + sw2, 24 * s, 2.6 * s);
    _limb(x, hipY, math.pi / 2 + 0.18 + sw2 * 0.6, 28 * s, 2.6 * s);
    _limb(x, hipY, math.pi / 2 - 0.18 + sw * 0.6, 28 * s, 2.6 * s);
    final y = baseY - 92 * s, r = 14 * s, p = _s(2.2 * s);
    c.drawCircle(Offset(x, y), r, p);
    c.drawCircle(Offset(x + face * r * 0.34, y - r * 0.18), r * 0.12, p);
    c.drawArc(
      Rect.fromCircle(
        center: Offset(x + face * r * 0.3, y + r * 0.42),
        radius: r * 0.26,
      ),
      -0.5,
      1.4,
      false,
      p,
    );
  }

  void _limb(double px, double py, double a, double len, double w) {
    final mx = px + math.cos(a) * len * 0.55,
        my = py + math.sin(a) * len * 0.55;
    final ex = mx + math.cos(a + 0.35) * len * 0.5,
        ey = my + math.sin(a + 0.35) * len * 0.5;
    c.drawPath(
      Path()
        ..moveTo(px, py)
        ..lineTo(mx, my)
        ..lineTo(ex, ey),
      _s(w),
    );
  }

  void world(double x, double y, double r, double t) {
    c.drawCircle(Offset(x, y), r, _s(2.2 * (r / 26)));
    final rx = math.cos(t * 0.6).abs() * r * 0.7 + 2;
    final f = _s(1.5, 0.5);
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: r * 2),
      f,
    );
    c.drawLine(Offset(x - r, y), Offset(x + r, y), f);
  }

  void glyph(String s, Offset o, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  void text(String s, Offset center, double size, Color color, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: w),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void fruit(Offset o, double s) {
    final p = _s(1.8 * s);
    c.drawCircle(o, 6 * s, p);
    c.drawLine(o + Offset(0, -6 * s), o + Offset(0, -11 * s), p);
  }

  void breeze(double cx, double cy, double width, double t) {
    final p = _s(1.6, 0.5);
    for (var k = 0; k < 3; k++) {
      final y = cy + (k - 1) * 10, off = (t * 70 + k * 40) % (width + 80) - 40;
      final path = Path();
      var first = true;
      for (var px = cx - width / 2; px < cx + width / 2; px += 7) {
        final yy = y + math.sin((px + off) * 0.05 + k) * 6;
        first ? path.moveTo(px, yy) : path.lineTo(px, yy);
        first = false;
      }
      c.drawPath(path, p);
    }
  }

  void bloom(Offset o, double t) {
    for (var i = 0; i < 3; i++) {
      final p = (t * 0.9 + i * 0.33) % 1;
      final col = HSVColor.fromAHSV(
        (1 - p) * 0.9,
        (t * 90 + i * 70) % 360,
        0.82,
        0.9,
      ).toColor();
      c.drawCircle(
        o,
        4 + p * 20,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = col
          ..isAntiAlias = true,
      );
    }
  }

  void aroma(Offset from, Offset to, double t) {
    final dot = Paint()
      ..color = muted
      ..isAntiAlias = true;
    for (var p = 0.0; p <= 1; p += 0.06) {
      final px = from.dx + (to.dx - from.dx) * p + math.sin(p * 8 + t * 3) * 5;
      final py = from.dy + (to.dy - from.dy) * p;
      c.drawCircle(Offset(px, py), 1.2, dot);
    }
  }

  /// A reliability ring filling to [pct] (0..100), with the level + score inside.
  void ring(Offset o, double r, double pct, {String? plusLabel}) {
    c.drawCircle(o, r, _s(2, 0.18));
    c.drawArc(
      Rect.fromCircle(center: o, radius: r),
      -math.pi / 2,
      (pct / 100).clamp(0, 1) * math.pi * 2,
      false,
      _s(5),
    );
    text('${pct.round()}%', o + const Offset(0, -6), 22, ink, FontWeight.w700);
    text(
      reliabilityLevelName(pct),
      o + const Offset(0, 14),
      11,
      brand,
      FontWeight.w600,
    );
    if (plusLabel != null) {
      text(plusLabel, o + Offset(0, r + 16), 13, brand, FontWeight.w700);
    }
  }

  /// The sense's signature effect around a small actor at the left.
  void sense(Size size, double t, SenseKind kind) {
    final s = math.min(size.width, size.height) / 220;
    final baseY = size.height * 0.74, cx = size.width / 2;
    actor(size.width * 0.28, baseY, s, 1, t);
    final hx = size.width * 0.28, hy = baseY - 92 * s;
    switch (kind) {
      case SenseKind.touch:
        breeze(cx + 20, size.height * 0.45, size.width * 0.7, t);
        break;
      case SenseKind.taste:
        final a = (t % 1.4) / 1.4;
        fruit(Offset(cx + 46 - a * 34, size.height * 0.42), s * 1.4);
        break;
      case SenseKind.smell:
        aroma(Offset(cx + 44, size.height * 0.62), Offset(hx + 12, hy + 2), t);
        break;
      case SenseKind.sight:
        bloom(Offset(hx + 6, hy - 3), t);
        break;
      case SenseKind.sound:
      case SenseKind.word:
        final a = (t % 1.5) / 1.5;
        final x = hx + 16 + a * size.width * 0.42;
        final y = hy - 8 - math.sin(a * math.pi) * 26;
        glyph(a > 0.55 ? '♪' : 'A', Offset(x, y), 18, brand);
        break;
    }
  }
}

/// A calm looping sense animation for loading states (§8 loaders).
class SenseLoader extends StatefulWidget {
  const SenseLoader({super.key, this.sense = SenseKind.word, this.size = 96});
  final SenseKind sense;
  final double size;

  @override
  State<SenseLoader> createState() => _SenseLoaderState();
}

class _SenseLoaderState extends State<SenseLoader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) => _t.value = e.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _LoaderPainter(
          _t,
          widget.sense,
          scheme.primary,
          scheme.onSurface,
          scheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.t, this.sense, this.brand, this.ink, this.muted)
    : super(repaint: t);
  final ValueListenable<double> t;
  final SenseKind sense;
  final Color brand, ink, muted;

  @override
  void paint(Canvas canvas, Size size) {
    final d = _Draw(canvas, brand, ink, muted);
    d.world(size.width / 2, size.height * 0.34, size.width * 0.14, t.value);
    d.sense(size, t.value, sense);
  }

  @override
  bool shouldRepaint(_LoaderPainter old) =>
      old.brand != brand || old.sense != sense;
}

/// Plays the task's contextual sense, then resolves into the reliability ring
/// with "+1 · <area>". Auto-dismisses. Used on task completion (§8/§13).
Future<void> showCompletionCelebration(
  BuildContext context, {
  required SenseKind sense,
  required String areaName,
  required double overallPct,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CompletionDialog(
      sense: sense,
      areaName: areaName,
      overallPct: overallPct,
    ),
  );
}

class _CompletionDialog extends StatefulWidget {
  const _CompletionDialog({
    required this.sense,
    required this.areaName,
    required this.overallPct,
  });
  final SenseKind sense;
  final String areaName;
  final double overallPct;

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((e) {
      final t = e.inMicroseconds / 1e6;
      _t.value = t;
      if (t > 3.0 && !_closed) {
        _closed = true;
        if (mounted) Navigator.of(context).maybePop();
      }
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 220,
              child: CustomPaint(
                painter: _CompletionPainter(
                  _t,
                  widget.sense,
                  widget.areaName,
                  widget.overallPct,
                  scheme.primary,
                  scheme.onSurface,
                  scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Word kept.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionPainter extends CustomPainter {
  _CompletionPainter(
    this.t,
    this.sense,
    this.area,
    this.pct,
    this.brand,
    this.ink,
    this.muted,
  ) : super(repaint: t);
  final ValueListenable<double> t;
  final SenseKind sense;
  final String area;
  final double pct;
  final Color brand, ink, muted;

  @override
  void paint(Canvas canvas, Size size) {
    final d = _Draw(canvas, brand, ink, muted);
    final time = t.value;
    if (time < 1.3) {
      d.sense(size, time, sense);
    } else {
      final prog = ((time - 1.3) / 1.0).clamp(0.0, 1.0);
      final shown = pct * prog;
      d.ring(
        Offset(size.width / 2, size.height / 2),
        52,
        shown,
        plusLabel: '+1 · $area',
      );
    }
  }

  @override
  bool shouldRepaint(_CompletionPainter old) => old.brand != brand;
}

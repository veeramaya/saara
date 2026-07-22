import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/reliability.dart';
import '../../../providers.dart';

/// §7.1 Home header — the "Integrity works." animation. A line-art two-person
/// conversation (word → world, cycling through the senses) with the tagline set
/// into it and a reliability ladder. The ladder marker is a **live gauge**: it
/// climbs to your real Today reliability (falling back to all-time), so the
/// brand animation doubles as your current standing. Drawn in code (no image /
/// Rive / Lottie), tints to the theme.
class IntegrityHeader extends ConsumerStatefulWidget {
  const IntegrityHeader({super.key, this.height = 236});

  final double height;

  @override
  ConsumerState<IntegrityHeader> createState() => _IntegrityHeaderState();
}

class _IntegrityHeaderState extends ConsumerState<IntegrityHeader>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Continuous, unbounded clock so aperiodic parts (ladder climb, sense cycle)
    // never jump at a loop boundary. TickerMode pauses this when the Home tab is
    // offstage or the app is backgrounded, so it costs nothing when unseen.
    _ticker = createTicker((elapsed) {
      _t.value = elapsed.inMicroseconds / 1e6;
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
    // Live reliability for the ladder marker: prefer Today; if nothing is
    // committed today, fall back to all-time; if there's no ledger at all,
    // leave it null so the ladder shows a gentle idle climb instead of 0%.
    final summary = ref.watch(reportSummaryProvider).valueOrNull;
    double? target;
    String? targetLabel;
    if (summary != null) {
      if (summary.todayCommitted > 0) {
        target = summary.todayEffectiveness / 100;
        targetLabel = 'today';
      } else if (summary.allCommitted > 0) {
        target = summary.allEffectiveness / 100;
        targetLabel = 'overall';
      }
    }
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: CustomPaint(
        painter: _ScenePainter(
          t: _t,
          brand: scheme.primary,
          ink: scheme.onSurface,
          muted: scheme.onSurface.withValues(alpha: 0.5),
          target: target,
          targetLabel: targetLabel,
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.t,
    required this.brand,
    required this.ink,
    required this.muted,
    this.target,
    this.targetLabel,
  }) : super(repaint: t);

  final ValueListenable<double> t;
  final Color brand;
  final Color ink;
  final Color muted;

  /// Real reliability (0..1) to rest the marker at, or null when there's no
  /// ledger yet (idle demo climb).
  final double? target;

  /// "today" / "overall" — the window [target] came from, shown by the marker.
  final String? targetLabel;

  static const _cycle = 15.0; // 5 senses × 3s
  static const _seg = 3.0;
  static const _glyphs = ['A', 'अ', 'O', 'ॐ', 'व', 'M'];

  Paint _stroke(double width, [double alpha = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..color = brand.withValues(alpha: alpha)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final time = t.value;
    final s = math.min(w, h) / 360;
    final baseY = h * 0.60, headY = baseY - 92 * s;
    final lx = w * 0.20,
        rx = w * 0.80,
        wx = w * 0.5,
        wy = h * 0.22,
        wr = 30 * s;
    final tc = time % _cycle;
    final phase = (tc / _seg).floor();
    final cycleIdx = (time / _cycle).floor();
    final spkLeft = cycleIdx % 2 == 0;

    _breeze(canvas, wx, wy + wr * 0.4, w * 0.7, time, phase == 3 ? 0.24 : 0.1);
    _worldRing(canvas, wx, wy, wr, time);
    _body(canvas, lx, baseY, s, 1, time, phase == 3);
    _body(canvas, rx, baseY, s, -1, time, phase == 3);

    // Sight — colour bloom at the eyes.
    if (phase == 0) {
      for (final x in [lx, rx]) {
        final face = x < wx ? 1 : -1;
        _bloom(canvas, x + face * 15 * s * 0.34, headY - 15 * s * 0.18, time);
      }
    }

    // Sound — letters from the speaker's mouth become a note at the listener's
    // ear. Derived deterministically from time (no cross-frame state).
    if (phase == 1) {
      for (var k = 0; k < 6; k++) {
        final st = _seg + k * 0.55; // spawn offset within the cycle
        if (st >= 2 * _seg) break;
        if (tc < st || tc > st + 2.2) continue;
        final a = (tc - st) / 2.2;
        final mx = (spkLeft ? lx : rx) + (spkLeft ? 1 : -1) * 9 * s;
        final my = headY + 6 * s;
        final ex = (spkLeft ? rx : lx) - (spkLeft ? -1 : 1) * 7 * s;
        final ey = headY;
        final cx = (mx + ex) / 2, cy = math.min(my, ey) - 46 * s;
        final x = _q(mx, cx, ex, a), y = _q(my, cy, ey, a);
        final note = a > 0.58;
        final al = a < 0.1 ? a / 0.1 : (a > 0.85 ? (1 - a) / 0.15 : 1.0);
        _glyph(
          canvas,
          note ? '♪' : _glyphs[k % _glyphs.length],
          x,
          y,
          (note ? 18 : 15) * s,
          al.clamp(0, 1).toDouble(),
        );
      }
    }

    // Taste — a fruit travels from the world to the speaker's mouth.
    if (tc >= 6 && tc <= 8) {
      final a = ((tc - 6) / 2).clamp(0.0, 1.0);
      final e = a < 0.5 ? 2 * a * a : 1 - math.pow(-2 * a + 2, 2) / 2;
      final spkX = spkLeft ? lx : rx;
      final mx = spkX + (spkX < wx ? 1 : -1) * 9 * s, my = headY + 6 * s;
      _fruit(
        canvas,
        wx + (mx - wx) * e,
        (wy + wr * 0.6) + (my - (wy + wr * 0.6)) * e,
        s,
      );
    }

    // Smell — an aroma wisp from the world to the speaker's nose.
    if (phase == 4) {
      final spkX = spkLeft ? lx : rx;
      _aroma(
        canvas,
        wx,
        wy + wr * 0.5,
        spkX + (spkX < wx ? 1 : -1) * 11 * s,
        headY + 1 * s,
        time,
      );
    }

    // Tagline, set into the animation.
    _text(
      canvas,
      'Integrity works.',
      Offset(w / 2, h * 0.74),
      math.max(16, w * 0.028),
      brand,
      FontWeight.w700,
    );

    // The framework itself: the reliability ladder.
    _ladder(canvas, w * 0.12, w * 0.88, h * 0.90, time, w);
  }

  double _q(double p0, double p1, double p2, double a) =>
      (1 - a) * (1 - a) * p0 + 2 * (1 - a) * a * p1 + a * a * p2;

  void _limb(
    Canvas c,
    double px,
    double py,
    double ang,
    double len,
    double width,
  ) {
    final mx = px + math.cos(ang) * len * 0.55,
        my = py + math.sin(ang) * len * 0.55;
    final ex = mx + math.cos(ang + 0.35) * len * 0.5,
        ey = my + math.sin(ang + 0.35) * len * 0.5;
    c.drawPath(
      Path()
        ..moveTo(px, py)
        ..lineTo(mx, my)
        ..lineTo(ex, ey),
      _stroke(width),
    );
  }

  void _body(
    Canvas c,
    double x,
    double baseY,
    double s,
    int face,
    double t,
    bool action,
  ) {
    final shoulderY = baseY - 70 * s, hipY = baseY - 34 * s;
    c.drawLine(Offset(x, shoulderY), Offset(x, hipY), _stroke(2.6 * s));
    final amp = action ? 1.0 : 0.45;
    final sw = math.sin(t * 2.6) * 0.5 * amp,
        sw2 = math.sin(t * 2.6 + math.pi) * 0.5 * amp;
    _limb(c, x, shoulderY, math.pi / 2 + 0.5 * face + sw, 25 * s, 2.6 * s);
    _limb(c, x, shoulderY, math.pi / 2 - 0.5 * face + sw2, 25 * s, 2.6 * s);
    _limb(c, x, hipY, math.pi / 2 + 0.18 + sw2 * 0.7, 30 * s, 2.6 * s);
    _limb(c, x, hipY, math.pi / 2 - 0.18 + sw * 0.7, 30 * s, 2.6 * s);
    _head(c, x, baseY - 92 * s, 15 * s, face, s);
  }

  void _head(Canvas c, double x, double y, double r, int face, double s) {
    final p = _stroke(2.2 * s);
    c.drawCircle(Offset(x, y), r, p);
    c.drawCircle(Offset(x + face * r * 0.34, y - r * 0.18), r * 0.12, p);
    c.drawLine(
      Offset(x + face * r * 0.5, y + r * 0.06),
      Offset(x + face * r * 0.72, y + r * 0.14),
      p,
    );
    c.drawArc(
      Rect.fromCircle(
        center: Offset(x + face * r * 0.30, y + r * 0.42),
        radius: r * 0.26,
      ),
      -0.5,
      1.4,
      false,
      p,
    );
    c.drawArc(
      Rect.fromCircle(center: Offset(x - face * r * 0.62, y), radius: r * 0.2),
      -1.1,
      2.2,
      false,
      p,
    );
  }

  void _worldRing(Canvas c, double x, double y, double r, double t) {
    c.drawCircle(Offset(x, y), r, _stroke(2.2 * (r / 30)));
    final rx = (math.cos(t * 0.6)).abs() * r * 0.7 + 2;
    final faint = _stroke(1.6, 0.55);
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: r * 2),
      faint,
    );
    c.drawLine(Offset(x - r, y), Offset(x + r, y), faint);
  }

  void _bloom(Canvas c, double x, double y, double t) {
    for (var i = 0; i < 3; i++) {
      final p = (t * 0.9 + i * 0.33) % 1;
      final hue = (t * 90 + i * 70) % 360;
      final col = HSVColor.fromAHSV(
        (1 - p) * 0.9,
        hue.toDouble(),
        0.82,
        0.9,
      ).toColor();
      c.drawCircle(
        Offset(x, y),
        4 + p * 22,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = col
          ..isAntiAlias = true,
      );
    }
  }

  void _fruit(Canvas c, double x, double y, double s) {
    final p = _stroke(1.8 * s);
    c.drawCircle(Offset(x, y), 6 * s, p);
    c.drawLine(Offset(x, y - 6 * s), Offset(x, y - 11 * s), p);
    c.save();
    c.translate(x + 5 * s, y - 10 * s);
    c.rotate(-0.6);
    c.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8 * s, height: 4.4 * s),
      p,
    );
    c.restore();
  }

  void _breeze(
    Canvas c,
    double cx,
    double cy,
    double width,
    double t,
    double alpha,
  ) {
    final p = _stroke(1.5, alpha);
    for (var k = 0; k < 3; k++) {
      final y = cy + (k - 1) * 8, off = (t * 60 + k * 40) % (width + 120) - 60;
      final path = Path();
      var first = true;
      for (var px = cx - width / 2; px < cx + width / 2; px += 8) {
        final yy = y + math.sin((px + off) * 0.03 + k) * 7;
        first ? path.moveTo(px, yy) : path.lineTo(px, yy);
        first = false;
      }
      c.drawPath(path, p);
    }
  }

  void _aroma(Canvas c, double x0, double y0, double x1, double y1, double t) {
    final dot = Paint()
      ..color = muted
      ..isAntiAlias = true;
    for (var p = 0.0; p <= 1; p += 0.05) {
      final px = x0 + (x1 - x0) * p + math.sin(p * 8 + t * 3) * 6;
      final py = y0 + (y1 - y0) * p;
      c.drawCircle(Offset(px, py), 1.2, dot);
    }
  }

  void _glyph(
    Canvas c,
    String s,
    double x,
    double y,
    double size,
    double alpha,
  ) {
    _text(
      c,
      s,
      Offset(x, y),
      size,
      brand.withValues(alpha: alpha),
      FontWeight.w600,
    );
  }

  void _ladder(Canvas c, double x0, double x1, double y, double t, double w) {
    final wd = x1 - x0, rise = math.min(38, wd * 0.05);
    final axis = _stroke(1.4, 0.28);
    c.drawLine(Offset(x0, y), Offset(x1, y), axis);
    for (final b in [10, 30, 50, 70, 85]) {
      final X = x0 + wd * b / 100;
      c.drawLine(Offset(X, y - 4), Offset(X, y + 4), axis);
    }
    // Per-band labels only where there's room (tablet); phones show just the
    // current level near the marker.
    if (w > 520) {
      const bands = [
        ['Beginner', 5.0],
        ['Learner', 20.0],
        ['Amateur', 40.0],
        ['Professional', 60.0],
        ['Champion', 78.0],
        ['Masterful', 93.0],
      ];
      for (final b in bands) {
        _text(
          c,
          b[0] as String,
          Offset(x0 + wd * (b[1] as double) / 100, y + 13),
          math.max(8, wd * 0.0135),
          muted,
          FontWeight.w600,
        );
      }
    }
    // The marker: a live gauge that climbs once to the real value and rests
    // there. With no ledger yet, it does a gentle looping demo climb instead.
    final double p;
    if (target == null) {
      p = (t * 0.06) % 1; // idle demo climb
    } else {
      final k = (t / 2.5).clamp(0.0, 1.0); // ~2.5s ease-in on first show
      final ease = 1 - math.pow(1 - k, 3).toDouble(); // easeOutCubic
      p = (target! * ease).clamp(0.0, 1.0);
    }
    final line = _stroke(2, 0.55);
    final path = Path();
    var first = true;
    for (var q = 0.0; q <= p + 0.0001; q += 0.012) {
      final X = x0 + wd * q, Y = y - 4 - math.pow(q, 0.85) * rise;
      first ? path.moveTo(X, Y) : path.lineTo(X, Y);
      first = false;
    }
    c.drawPath(path, line);
    final mX = x0 + wd * p, mY = y - 4 - math.pow(p, 0.85) * rise;
    // Gentle pulse once rested, so the live marker still feels alive.
    final pulse = target == null ? 0.0 : math.sin(t * 2) * 0.6;
    c.drawCircle(
      Offset(mX, mY),
      3.6 + pulse,
      Paint()
        ..color = brand
        ..isAntiAlias = true,
    );
    final name = reliabilityLevelName(p * 100);
    final label = targetLabel == null
        ? name
        : '$name · ${(p * 100).round()}% $targetLabel';
    final size = math.max(9.0, wd * 0.017);
    // Keep the centred label on-screen even when the marker sits at either end.
    final half = label.length * size * 0.30;
    final labelX = mX.clamp(half + 4, w - half - 4);
    _text(c, label, Offset(labelX, mY - 14), size, ink, FontWeight.w700);
  }

  void _text(
    Canvas c,
    String s,
    Offset center,
    double size,
    Color color,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.brand != brand ||
      old.ink != ink ||
      old.muted != muted ||
      old.target != target ||
      old.targetLabel != targetLabel;
}

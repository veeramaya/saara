import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/reliability.dart';
import '../../../providers.dart';

/// §7.1 Home header — the **"Author your Life"** journey. The Person travels the
/// widening circles of your life — **Personal · Private · Peers · Public** —
/// clearing the barriers in the way and gathering a **halo of Potential** as
/// their reliability climbs, until every circle closes: whole and complete,
/// which is what *integrity* means (Latin *integer*, whole).
///
/// It is a **live gauge**, not decoration: on open it plays your climb up to
/// your real Today reliability (falling back to all-time) and rests there, so
/// the header always shows where you actually stand. Drawn in code (no image /
/// Rive / Lottie), tints to the theme, and scales to any width.
class IntegrityHeader extends ConsumerStatefulWidget {
  const IntegrityHeader({super.key});

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
    // Continuous clock. TickerMode pauses it when the Home tab is offstage or
    // the app is backgrounded, so it costs nothing unseen.
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

    // Live reliability for the resting point: prefer Today; else all-time; else
    // null → a gentle idle demo of the whole journey.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final side = math.min(w, 320.0);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Author your Life',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: w,
                height: side,
                child: CustomPaint(
                  painter: _JourneyPainter(
                    t: _t,
                    brand: scheme.primary,
                    ink: scheme.onSurface,
                    muted: scheme.onSurface.withValues(alpha: 0.5),
                    target: target,
                    targetLabel: targetLabel,
                  ),
                ),
              ),
              // The finish line — the payoff, fading in when the journey rests
              // at your standing, sharing the animation's own timing.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: ValueListenableBuilder<double>(
                  valueListenable: _t,
                  builder: (context, time, _) {
                    final o = _computePhase(time, target ?? 0.9).payoff;
                    return Opacity(
                      opacity: o,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Integrity is a path to being whole and complete '
                            'in all the spaces of your life.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saara enables that for you.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.t,
    required this.brand,
    required this.ink,
    required this.muted,
    this.target,
    this.targetLabel,
  }) : super(repaint: t);

  final ValueListenable<double> t;
  final Color brand, ink, muted;
  final double? target;
  final String? targetLabel;

  static const _names = ['Personal', 'Private', 'Peers', 'Public'];
  static const _barr = [
    0.75,
    2.35,
    3.95,
    5.4,
  ]; // barrier angle offsets from top
  static const _tau = math.pi * 2;
  static const _top = -math.pi / 2;

  Paint _s(double w, [double a = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..color = brand.withValues(alpha: a)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = w
    ..isAntiAlias = true;

  double _easeOut(double x) {
    x = x.clamp(0, 1);
    return 1 - math.pow(1 - x, 3).toDouble();
  }

  double _angDiff(double a, double b) {
    var d = a - b;
    while (d > math.pi) {
      d -= _tau;
    }
    while (d < -math.pi) {
      d += _tau;
    }
    return d;
  }

  void _glow(Canvas c, Offset o, double r, double a) {
    if (a <= 0 || r <= 0) return;
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          o,
          r,
          [
            brand.withValues(alpha: a),
            brand.withValues(alpha: a * 0.4),
            brand.withValues(alpha: 0),
          ],
          const [0.0, 0.55, 1.0],
        ),
    );
  }

  void _text(
    Canvas c,
    String s,
    Offset center,
    double size,
    Color color,
    FontWeight w, [
    double a = 1,
  ]) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color.withValues(alpha: a),
          fontSize: size,
          fontWeight: w,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _figure(Canvas c, double s, double power) {
    final p = _s(2.4 * s);
    final headY = -9 * s, hipY = 5 * s;
    c.drawCircle(Offset(0, headY), 3.6 * s, p);
    c.drawLine(Offset(0, headY + 3.6 * s), Offset(0, hipY), p);
    final arm = 0.15 + power * 1.2, sy = headY + 6 * s;
    c.drawLine(
      Offset(0, sy),
      Offset(-math.cos(arm) * 9 * s, sy - math.sin(arm) * 9 * s),
      p,
    );
    c.drawLine(
      Offset(0, sy),
      Offset(math.cos(arm) * 9 * s, sy - math.sin(arm) * 9 * s),
      p,
    );
    c.drawLine(Offset(0, hipY), Offset(-3.4 * s, hipY + 10 * s), p);
    c.drawLine(Offset(0, hipY), Offset(3.4 * s, hipY + 10 * s), p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = t.value;
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h * 0.44;
    final r3 = math.min(w, h) * 0.38;
    final k = r3 / 186;
    final rings = [r3 * 0.29, r3 * 0.53, r3 * 0.76, r3];
    double font(double base) => math.max(8.5, base * k);

    // The journey loops, slowly, pausing at each space so every stage can sink
    // in: climb → hold at your standing (payoff appears) → fade → begin again.
    // Timing lives in _computePhase so the payoff text below can share it.
    final effTarget = target ?? 0.9;
    final ph = _computePhase(time, effTarget);
    final p = ph.p;
    final sceneA = ph.sceneA;

    final whole = p >= 0.999;
    final int ringIndex;
    final double local;
    if (whole) {
      ringIndex = 3;
      local = 1;
    } else {
      ringIndex = (p * 4).floor().clamp(0, 3);
      local = (p * 4 - ringIndex).clamp(0, 1);
    }
    final overall = p;
    final th = _top + local * _tau;
    final centre = Offset(cx, cy);

    // Group the whole scene under one opacity so the loop can fade in/out.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Color.fromRGBO(0, 0, 0, sceneA.clamp(0, 1)),
    );

    // rings: faint base + brand fill for the cleared portion + label
    for (var i = 0; i < 4; i++) {
      final rect = Rect.fromCircle(center: centre, radius: rings[i]);
      canvas.drawArc(rect, _top, _tau, false, _s(1.6 * k, 0.26));
      final fill = i < ringIndex || whole
          ? 1.0
          : (i == ringIndex ? local : 0.0);
      if (fill > 0) {
        canvas.drawArc(
          rect,
          _top,
          fill * _tau,
          false,
          _s((fill > 0.999 ? 4.6 : 4) * k),
        );
      }
      final active = i == ringIndex && !whole;
      _text(
        canvas,
        _names[i],
        Offset(cx, cy - rings[i] - 12 * k),
        font(active ? 12.5 : 11),
        active ? brand : muted,
        active ? FontWeight.w700 : FontWeight.w600,
        active ? 1 : 0.82,
      );
    }

    // barriers on the current ring — solid ahead, faint once cleared — + the hop
    double hop = 0;
    if (!whole) {
      for (final o in _barr) {
        final b = _top + o, past = _angDiff(th, b) > 0;
        final c1 = rings[ringIndex] - 5 * k, c2 = rings[ringIndex] + 10 * k;
        canvas.drawLine(
          Offset(cx + math.cos(b) * c1, cy + math.sin(b) * c1),
          Offset(cx + math.cos(b) * c2, cy + math.sin(b) * c2),
          _s(2.6 * k, past ? 0.22 : 0.75),
        );
        final d = _angDiff(th, b).abs();
        if (d < 0.4) hop = math.max(hop, 20 * k * (1 - (d / 0.4) * (d / 0.4)));
      }
    }

    final rr = rings[ringIndex] + hop;
    final px = cx + math.cos(th) * rr, py = cy + math.sin(th) * rr;
    final s = (0.95 + overall * 1.05) * k;
    final hx = px, hy = py - 9 * s;

    // completion — the halo blooms to fill the whole space: the phenomenon
    if (whole) {
      final bloom = _easeOut(((p - 0.9) / 0.1).clamp(0, 1));
      final pulse = 0.9 + 0.1 * math.sin(time * 1.5);
      _glow(canvas, centre, (46 + bloom * 300) * k, 0.2 * bloom * pulse);
    }
    // the Person's halo — grows with Potential
    _glow(
      canvas,
      Offset(hx, hy),
      (10 + overall * 34) * k,
      0.18 + 0.16 * overall,
    );

    canvas.save();
    canvas.translate(px, py);
    _figure(canvas, s, overall);
    canvas.restore();

    // a crisp halo ring above the head, opening as Potential grows
    final headR = 3.6 * s;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(hx, hy - headR - 3 * k),
        width: 2 * (5 + overall * 7) * k,
        height: 2 * (2 + overall * 3) * k,
      ),
      _s((1.4 + overall * 1.4) * k, 0.3 + 0.5 * overall),
    );

    // the dynamic label sinking in: at each level pause, name it in the centre
    if (ph.pauseLevel != null && ph.levelEmphasis > 0) {
      _text(
        canvas,
        ph.pauseLevel!,
        centre,
        font(22),
        brand,
        FontWeight.w800,
        ph.levelEmphasis,
      );
    }

    // readout below the rings — the standing, shown once (no clutter on the head)
    final by = cy + r3 + 20 * k;
    if (target == null) {
      _text(
        canvas,
        'Begin your journey',
        Offset(cx, by),
        font(12.5),
        muted,
        FontWeight.w600,
      );
    } else {
      _text(
        canvas,
        '${reliabilityLevelName(p * 100)} · ${_names[ringIndex]}',
        Offset(cx, by),
        font(13.5),
        ink,
        FontWeight.w700,
      );
      _text(
        canvas,
        '${(p * 100).round()}% $targetLabel',
        Offset(cx, by + font(13.5)),
        font(11),
        muted,
        FontWeight.w600,
      );
    }

    canvas.restore(); // close the opacity group
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.brand != brand ||
      old.ink != ink ||
      old.muted != muted ||
      old.target != target ||
      old.targetLabel != targetLabel;
}

/// The looping timeline, shared by the painter and the payoff text so they stay
/// in lock-step. Deliberately unhurried: the Person climbs to the live standing
/// [tgt], **pausing at each reliability *level* it reaches** — Learner, Amateur,
/// Professional, Champion, Masterful — and naming it, so the *dynamic* label
/// sinks in (the *spaces* are static ring labels, always visible). Then it holds
/// at the top while the payoff shows, fades, and begins again.
class _Phase {
  const _Phase(
    this.p,
    this.sceneA,
    this.payoff,
    this.pauseLevel,
    this.levelEmphasis,
  );
  final double p; // journey progress 0..1
  final double sceneA; // group opacity for the fade in/out
  final double payoff; // opacity of the finish-line payoff text
  final String? pauseLevel; // the level name to surface during a pause
  final double levelEmphasis; // 0..1 how strongly to show pauseLevel
}

double _easeIO(double x) {
  x = x.clamp(0, 1).toDouble();
  return x * x * (3 - 2 * x);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

// The reliability levels the journey pauses on, as fractions of the whole path.
const _levelP = [0.20, 0.40, 0.60, 0.78, 0.93];
const _levelN = ['Learner', 'Amateur', 'Professional', 'Champion', 'Masterful'];

_Phase _computePhase(double time, double tgt) {
  const speed = 0.12; // journey-fraction per second while moving (unhurried)
  const pauseDur = 1.9; // the "let it sink in" pause at each level
  const holdDur = 3.0, fadeDur = 1.6, fadeIn = 0.8;

  // Build move/pause segments up to the standing, naming each level pause.
  final p0 = <double>[], p1 = <double>[], dur = <double>[];
  final nm = <String?>[];
  final isPause = <bool>[];
  void seg(double a, double b, double d, bool pause, String? name) {
    p0.add(a);
    p1.add(b);
    dur.add(d);
    isPause.add(pause);
    nm.add(name);
  }

  var cur = 0.0;
  for (var i = 0; i < _levelP.length; i++) {
    if (_levelP[i] >= tgt - 1e-6) break;
    seg(cur, _levelP[i], (_levelP[i] - cur) / speed, false, null);
    seg(_levelP[i], _levelP[i], pauseDur, true, _levelN[i]);
    cur = _levelP[i];
  }
  seg(
    cur,
    tgt,
    (tgt - cur) / speed,
    false,
    null,
  ); // final climb to the standing

  var climbDur = 0.0;
  for (final d in dur) {
    climbDur += d;
  }

  final period = climbDur + holdDur + fadeDur;
  final cyc = time % period;

  var p = tgt, sceneA = 1.0, payoff = 0.0, emph = 0.0;
  String? pauseLevel;
  if (cyc < climbDur) {
    var acc = 0.0;
    p = 0;
    for (var i = 0; i < dur.length; i++) {
      if (cyc < acc + dur[i]) {
        final u = (cyc - acc) / dur[i];
        if (isPause[i]) {
          p = p0[i];
          pauseLevel = nm[i];
          emph = math.min(u / 0.25, (1 - u) / 0.25).clamp(0, 1).toDouble();
        } else {
          p = _lerp(p0[i], p1[i], _easeIO(u));
        }
        break;
      }
      acc += dur[i];
      p = p1[i];
    }
  } else if (cyc < climbDur + holdDur) {
    p = tgt;
    payoff = _easeIO((cyc - climbDur) / 0.6); // fade the payoff in at the top
  } else {
    p = tgt;
    payoff = 1;
    sceneA = 1 - (cyc - climbDur - holdDur) / fadeDur;
  }
  if (cyc < fadeIn) sceneA = cyc / fadeIn;

  sceneA = sceneA.clamp(0, 1).toDouble();
  return _Phase(
    p.clamp(0, 1).toDouble(),
    sceneA,
    (payoff * sceneA).clamp(0, 1).toDouble(),
    pauseLevel,
    (emph * sceneA).clamp(0, 1).toDouble(),
  );
}

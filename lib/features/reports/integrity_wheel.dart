import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../areas/area_detail_screen.dart';
import '../areas/area_icons.dart';

/// §13 "integrity wheel" — each Area is a wedge whose fill radius is its score
/// (measurable-result progress, or task-completion where none). Tap a wedge to
/// drill into that area. Deterministic; computed from the ledger + logs.
class IntegrityWheel extends ConsumerWidget {
  const IntegrityWheel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(areaScoresProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(height: 100, child: Center(child: Text('$e'))),
      data: (scores) {
        if (scores.isEmpty) {
          return const SizedBox.shrink();
        }
        final scheme = Theme.of(context).colorScheme;
        final segments = [
          for (final s in scores)
            _Segment(
              label: s.area.displayName,
              score: s.score,
              color: areaColor(s.area.color) ?? scheme.primary,
              areaId: s.area.id,
            ),
        ];
        final overall =
            scores.fold<double>(0, (a, s) => a + s.score) / scores.length;

        final unanswered = scores.fold<int>(0, (a, s) => a + s.unanswered);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return GestureDetector(
                    onTapUp: (d) {
                      final hit = _hitTest(
                        d.localPosition,
                        size,
                        segments.length,
                      );
                      if (hit != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AreaDetailScreen(areaId: segments[hit].areaId),
                          ),
                        );
                      }
                    },
                    child: CustomPaint(
                      painter: _WheelPainter(
                        segments: segments,
                        overall: overall,
                        onSurface: scheme.onSurface,
                        outline: scheme.outlineVariant,
                        labelStyle: Theme.of(context).textTheme.labelSmall!,
                        centerStyle: Theme.of(context).textTheme.titleLarge!,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Sits *beside* the number, never inside it. Folding these in would
            // be Saara deciding your silence was a failure; leaving them out
            // entirely would make silence free — and the safest way to protect
            // a score would be to never answer at all (§4.1).
            if (unanswered > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$unanswered commitment${unanswered == 1 ? '' : 's'} '
                        'still unanswered — not counted either way',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // Maps a tap to a wedge index (or null if outside the wheel).
  int? _hitTest(Offset p, Size size, int n) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 * 0.68;
    final v = p - center;
    if (v.distance > maxR) return null;
    // Angle from top (-pi/2), clockwise, normalized to [0, 2pi).
    var a = math.atan2(v.dy, v.dx) + math.pi / 2;
    if (a < 0) a += 2 * math.pi;
    final seg = 2 * math.pi / n;
    return (a / seg).floor().clamp(0, n - 1);
  }
}

class _Segment {
  _Segment({
    required this.label,
    required this.score,
    required this.color,
    required this.areaId,
  });
  final String label;
  final double score;
  final Color color;
  final String areaId;
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.segments,
    required this.overall,
    required this.onSurface,
    required this.outline,
    required this.labelStyle,
    required this.centerStyle,
  });

  final List<_Segment> segments;
  final double overall;
  final Color onSurface;
  final Color outline;
  final TextStyle labelStyle;
  final TextStyle centerStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2 * 0.68;
    final n = segments.length;
    final seg = 2 * math.pi / n;
    const start = -math.pi / 2;

    // Guide rings at 25/50/75/100%.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = outline.withValues(alpha: 0.5);
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(center, maxR * f, ring);
    }

    for (var i = 0; i < n; i++) {
      final a0 = start + i * seg;
      final s = segments[i];
      final fillR = maxR * s.score.clamp(0.0, 1.0);

      // Faint full wedge (the "possible") and the filled wedge (the "actual").
      final bg = Paint()..color = s.color.withValues(alpha: 0.12);
      canvas.drawPath(_wedge(center, maxR, a0, seg), bg);
      if (fillR > 0) {
        final fg = Paint()..color = s.color.withValues(alpha: 0.85);
        canvas.drawPath(_wedge(center, fillR, a0, seg), fg);
      }
      // Wedge separators.
      final sep = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline;
      canvas.drawLine(
        center,
        center + Offset(math.cos(a0) * maxR, math.sin(a0) * maxR),
        sep,
      );

      // Label + percentage just outside the wedge.
      final mid = a0 + seg / 2;
      final lp =
          center +
          Offset(math.cos(mid) * (maxR + 14), math.sin(mid) * (maxR + 14));
      _text(canvas, '${s.label}\n${(s.score * 100).round()}%', lp, mid);
    }

    // Center disc with overall %.
    canvas.drawCircle(
      center,
      maxR * 0.28,
      Paint()..color = onSurface.withValues(alpha: 0.06),
    );
    _center(canvas, '${(overall * 100).round()}%', center);
  }

  Path _wedge(Offset c, double r, double a0, double sweep) {
    return Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), a0, sweep, false)
      ..close();
  }

  void _text(Canvas canvas, String text, Offset at, double angle) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(color: onSurface),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    // Anchor: left of center on the left half, right on the right half.
    final onRight = math.cos(angle) >= 0;
    final dx = onRight ? at.dx : at.dx - tp.width;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  void _center(Canvas canvas, String text, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: centerStyle.copyWith(color: onSurface),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.segments != segments || old.overall != overall;
}

import 'package:flutter/material.dart';

/// §7.1 Home header — a quiet brand mark instead of a quote (deliberately
/// neutral: no attributed voice, no editorial bias). A minimal, gender-neutral
/// human figure inside a ring — a person, whole and complete. Drawn in code so
/// it's crisp at any size and tints to the current theme; the reading is left
/// to the viewer.
class WholenessHeader extends StatelessWidget {
  const WholenessHeader({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size, size),
        painter: _WholenessPainter(
          figure: scheme.primary,
          ring: scheme.primary.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _WholenessPainter extends CustomPainter {
  const _WholenessPainter({required this.figure, required this.ring});

  final Color figure;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, size.height / 2);

    // The ring — whole and complete.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..color = ring
      ..isAntiAlias = true;
    canvas.drawCircle(c, w * 0.44, ringPaint);

    // The figure — head + shoulders, no gendered features.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = figure
      ..isAntiAlias = true;

    // Head.
    canvas.drawCircle(Offset(c.dx, c.dy - w * 0.11), w * 0.10, fill);

    // Shoulders — the top half of a disc (a calm dome) beneath the head.
    final shoulderR = w * 0.22;
    final shoulderCenter = Offset(c.dx, c.dy + w * 0.21);
    final shoulders = Path()
      ..moveTo(shoulderCenter.dx - shoulderR, shoulderCenter.dy)
      ..arcToPoint(
        Offset(shoulderCenter.dx + shoulderR, shoulderCenter.dy),
        radius: Radius.circular(shoulderR),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(shoulders, fill);
  }

  @override
  bool shouldRepaint(_WholenessPainter old) =>
      old.figure != figure || old.ring != ring;
}

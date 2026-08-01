import 'package:flutter/material.dart';

import '../../domain/daily_quote.dart';

/// A gentle "message for the day" shown at the top of the Open/Close rituals.
/// The quote is chosen deterministically from today's date (see [quoteForDay]),
/// so it costs nothing to sync and reads the same on every device.
class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key, required this.morning});

  /// True on "Open your day" (energising set), false on "Close your day"
  /// (reflective set).
  final bool morning;

  @override
  Widget build(BuildContext context) {
    final q = quoteForDay(DateTime.now(), morning: morning);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  morning
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  morning ? 'A word for the day' : 'A word to close on',
                  style: text.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '“${q.text}”',
              style: text.titleMedium?.copyWith(
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${q.author}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

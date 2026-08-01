import 'package:flutter/material.dart';

import '../../domain/world_days.dart';

/// "What's special in the world today" — the ritual's context layer, shown at
/// the top of Open/Close your day in place of a generic quote. Bundled and
/// date-deterministic (see [worldDayFor]); costs nothing to sync, works offline.
/// On a day the set doesn't mark, it shows a gentle, ordinary-day line rather
/// than nothing — Saara is about your word, and this is only context beside it.
class WorldTodayCard extends StatelessWidget {
  const WorldTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final world = worldDayFor(DateTime.now());
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final title = world?.title ?? 'An ordinary day';
    final note =
        world?.note ?? 'Nothing the world marks — a fine day to keep your word.';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The world today',
                    style: text.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

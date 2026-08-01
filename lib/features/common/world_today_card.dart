import 'package:flutter/material.dart';

import '../../domain/holidays_india.dart';
import '../../domain/world_days.dart';

/// "What's special today" — the ritual's context layer, shown at the top of
/// Open/Close your day. It prefers a **Central-Government gazetted holiday** (an
/// informational reference, attributed — never a claim about *your* day), and
/// otherwise a bundled world observance. Both are date-deterministic and offline.
/// On an unmarked day it shows a gentle ordinary-day line — Saara is about your
/// word, and this is only context beside it.
class WorldTodayCard extends StatelessWidget {
  const WorldTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final holiday = holidayOn(now); // region IN (the only seeded list today)
    final world = worldDayFor(now);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final String emoji;
    final String label;
    final String title;
    final String note;
    if (holiday != null) {
      emoji = '🎉';
      label = 'Holiday · per Govt of India';
      title = holiday.name;
      note = holiday.tentative
          ? 'The date is subject to moon sighting. Your calendar is yours to set.'
          : 'Have you planned anything around it?';
    } else if (world != null) {
      emoji = '🌍';
      label = 'The world today';
      title = world.title;
      note = world.note;
    } else {
      emoji = '🌍';
      label = 'The world today';
      title = 'An ordinary day';
      note = 'Nothing the world marks — a fine day to keep your word.';
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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

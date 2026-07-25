import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers.dart';
import 'add_area_screen.dart';
import 'area_detail_screen.dart';
import 'area_icons.dart';
import 'unclassified_tasks_screen.dart';
import '../common/top_menu.dart';

/// §3.1 — broad life areas are capped so the wheel stays legible and focused.
const _maxAreas = 10;

/// §7.5 / §20.1 Areas — a 2-column card grid. Tapping a card opens the area
/// detail (purpose + tasks; measurable results land in the next chunk).
class AreasScreen extends ConsumerWidget {
  const AreasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(activeAreasProvider);

    final count = areasAsync.valueOrNull?.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Areas'),
        actions: const [SaaraTopMenu()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add area'),
        onPressed: () {
          if (count >= _maxAreas) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Up to $_maxAreas areas — keep it focused.'),
              ),
            );
            return;
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddAreaScreen(nextSortOrder: count),
            ),
          );
        },
      ),
      body: areasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (areas) {
          if (areas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No areas yet.', textAlign: TextAlign.center),
              ),
            );
          }
          // An extra tile for area-less tasks, shown only when some exist, so
          // they're never stranded off the wheel (§7.5).
          final unclassified =
              ref.watch(unclassifiedTasksProvider).valueOrNull ?? const [];
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 150, // fixed height → no overflow, always scrolls
            ),
            itemCount: areas.length + (unclassified.isEmpty ? 0 : 1),
            itemBuilder: (_, i) => i < areas.length
                ? _AreaCard(area: areas[i])
                : _UnclassifiedCard(count: unclassified.length),
          );
        },
      ),
    );
  }
}

/// The Unclassified tile — a dashed-feeling, muted card that opens the triage
/// list. Deliberately set apart from real areas: it's a to-do, not a category.
class _UnclassifiedCard extends StatelessWidget {
  const _UnclassifiedCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UnclassifiedTasksScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  color: scheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unclassified',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count to file',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});
  final Area area;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = areaColor(area.color) ?? scheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AreaDetailScreen(areaId: area.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(areaIcon(area.icon), color: accent, size: 22),
              ),
              // §3.1: display_name everywhere; base_category as a muted subtitle.
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    area.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    area.baseCategory.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

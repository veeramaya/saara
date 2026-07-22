import '../../domain/enums.dart';

/// Starter Areas seeded on first launch (until onboarding §20.3 lets the user
/// pick/rename their own). Plain data — no Drift-generated types — so it stays
/// codegen-free and unit-testable. `displayName` is what shows/speaks
/// everywhere (§3.1); `baseCategory` drives parser keywords, health mapping, and
/// report grouping, and appears only as a small subtitle chip.
///
/// Users can rename or archive any of these later. Stable ids keep first-run
/// seeding idempotent.
class DefaultArea {
  const DefaultArea({
    required this.id,
    required this.displayName,
    required this.baseCategory,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  final String id;
  final String displayName;
  final BaseCategory baseCategory;
  final String icon; // Material icon name — mapped to IconData in the UI
  final String color; // #RRGGBB
  final int sortOrder;
}

const List<DefaultArea> kDefaultAreas = [
  DefaultArea(
    id: 'seed-health',
    displayName: 'Health',
    baseCategory: BaseCategory.health,
    icon: 'favorite',
    color: '#2E7D32',
    sortOrder: 0,
  ),
  DefaultArea(
    id: 'seed-exercise',
    displayName: 'Exercise',
    baseCategory: BaseCategory.health, // health-verifiable (steps, active min)
    icon: 'fitness_center',
    color: '#00897B',
    sortOrder: 1,
  ),
  DefaultArea(
    id: 'seed-career',
    displayName: 'Career',
    baseCategory: BaseCategory.work,
    icon: 'work',
    color: '#1565C0',
    sortOrder: 2,
  ),
  DefaultArea(
    id: 'seed-finance',
    displayName: 'Finance',
    baseCategory: BaseCategory.finance,
    icon: 'savings',
    color: '#6D4C41',
    sortOrder: 3,
  ),
  DefaultArea(
    id: 'seed-relationships',
    displayName: 'Relationships',
    baseCategory: BaseCategory.relationships,
    icon: 'group',
    color: '#AD1457',
    sortOrder: 4,
  ),
  DefaultArea(
    id: 'seed-leisure',
    displayName: 'Leisure',
    baseCategory: BaseCategory.custom,
    icon: 'beach_access',
    color: '#F9A825',
    sortOrder: 5,
  ),
];

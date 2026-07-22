import 'package:flutter/material.dart';

/// Maps Area `icon` names to [IconData], and parses the stored `#RRGGBB`
/// colour. Kept as an explicit map so Flutter can tree-shake icons (dynamic
/// IconData construction isn't allowed). This is also the picker library for
/// custom areas (§3.1 / §20.3) — leadership, service, family oneness, etc.
const areaIconChoices = <String, IconData>{
  'favorite': Icons.favorite,
  'fitness_center': Icons.fitness_center,
  'work': Icons.work,
  'savings': Icons.savings,
  'group': Icons.group,
  'beach_access': Icons.beach_access,
  'emoji_events': Icons.emoji_events, // leadership / championship
  'volunteer_activism': Icons.volunteer_activism, // serving a community
  'diversity_3': Icons.diversity_3, // oneness / togetherness
  'family_restroom': Icons.family_restroom, // family
  'self_improvement': Icons.self_improvement, // being / spirituality
  'school': Icons.school, // learning
  'psychology': Icons.psychology, // mind / growth
  'handshake': Icons.handshake, // relationships / trust
  'lightbulb': Icons.lightbulb, // creativity
  'spa': Icons.spa, // wellbeing
  'rocket_launch': Icons.rocket_launch, // ambition
  'menu_book': Icons.menu_book, // study
  'nature_people': Icons.nature_people, // nature / balance
  'star': Icons.star, // purpose
};

/// Brand-aligned colour choices for custom areas.
const areaColorChoices = <String>[
  '#CC1A1A',
  '#0E7A5F',
  '#2563EB',
  '#B45309',
  '#7C3AED',
  '#0891B2',
  '#DB2777',
  '#4B5563',
];

IconData areaIcon(String? name) =>
    areaIconChoices[name] ?? Icons.circle_outlined;

Color? areaColor(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length != 6) return null;
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

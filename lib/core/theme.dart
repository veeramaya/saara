import 'package:flutter/material.dart';

/// §20 UI design system — Material 3 (Material You). Deep teal brand seed
/// (§20.1: "calm, trustworthy"), used as the fallback when Android 12+ dynamic
/// color from the wallpaper isn't available. Full light/dark support.
class SaaraTheme {
  const SaaraTheme._();

  /// §20.1 brand seed color — Realmaya brand red (realmaya.com theme-color
  /// #CC1A1A). Material 3 derives the full light/dark tonal scheme from it.
  static const Color seed = Color(0xFFCC1A1A);

  static ThemeData light([ColorScheme? dynamicScheme]) => _build(
    dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
  );

  static ThemeData dark([ColorScheme? dynamicScheme]) => _build(
    dynamicScheme ??
        ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true, // §20 requirement
      colorScheme: scheme,
      // §20.1 card-first layout: consistent 12–16 dp corners.
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

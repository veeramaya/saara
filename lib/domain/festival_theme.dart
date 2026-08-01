import 'package:flutter/material.dart';

/// A small, tasteful accent per festival — the "doodle on the card" the card and
/// the world-today card take on automatically on a gazetted day. Bundled and
/// painted on-device (offline); shown only on the day, always attributed to the
/// Govt of India list. Keyword-matched so a new gazetted name still resolves to
/// a sensible default rather than nothing.
({String emoji, Color color}) festivalTheme(String name) {
  final n = name.toLowerCase();
  if (n.contains('diwali') || n.contains('deepavali')) {
    return (emoji: '🪔', color: const Color(0xFFE8A33D));
  }
  if (n.contains('holi')) {
    return (emoji: '🎨', color: const Color(0xFFE0479E));
  }
  if (n.contains('christmas')) {
    return (emoji: '🎄', color: const Color(0xFF2E9E5B));
  }
  if (n.contains('republic') || n.contains('independence')) {
    return (emoji: '🇮🇳', color: const Color(0xFFFF9933));
  }
  if (n.contains('id-') ||
      n.contains('eid') ||
      n.contains('bakrid') ||
      n.contains('muharram') ||
      n.contains('milad')) {
    return (emoji: '🌙', color: const Color(0xFF4AA5A0));
  }
  if (n.contains('gandhi')) {
    return (emoji: '🕊️', color: const Color(0xFF7C8B99));
  }
  if (n.contains('good friday')) {
    return (emoji: '✝️', color: const Color(0xFF8A6DAE));
  }
  if (n.contains('navami') ||
      n.contains('janmashtami') ||
      n.contains('dussehra') ||
      n.contains('mahavir') ||
      n.contains('buddha') ||
      n.contains('guru nanak')) {
    return (emoji: '🪔', color: const Color(0xFFD98A3D));
  }
  return (emoji: '🎉', color: const Color(0xFFE8A33D));
}

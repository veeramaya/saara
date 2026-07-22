// Generates the Saara launcher-icon source images (§20.2). Run with:
//   dart run tool/gen_icon.dart
// then: dart run flutter_launcher_icons
//
// The mark is an original geometric device — a broken ring enclosing a
// checkmark: the ring = wholeness/integrity ("Saara" = whole & complete), the
// check = a commitment given and kept (§1). Deliberately unlike orb/sparkle/
// waveform assistant logos. Drawn per-pixel with analytic anti-aliasing.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

// Brand palette (§20.1) — Realmaya brand red #CC1A1A (realmaya.com).
const _brandR = 0xCC, _brandG = 0x1A, _brandB = 0x1A;
const _size = 1024;
const _c = _size / 2; // center

double _smoothstep(double edge0, double edge1, double x) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Distance from point p to segment a→b.
double _distToSegment(
    double px, double py, double ax, double ay, double bx, double by) {
  final dx = bx - ax, dy = by - ay;
  final len2 = dx * dx + dy * dy;
  var t = len2 == 0 ? 0.0 : ((px - ax) * dx + (py - ay) * dy) / len2;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}

/// Coverage (0..1) of the white mark at a pixel, given a scale factor.
double _markCoverage(double x, double y, double scale) {
  final d = math.sqrt((x - _c) * (x - _c) + (y - _c) * (y - _c));

  // Ring (annulus) with a gap at the top-right for an "open"/growing feel.
  final outer = 300.0 * scale, inner = 232.0 * scale;
  final insideOuter = _smoothstep(outer + 1.0, outer - 1.0, d);
  final outsideInner = _smoothstep(inner - 1.0, inner + 1.0, d);
  var ring = insideOuter * outsideInner;
  // Carve a wedge gap centered at -45° (top-right).
  final ang = math.atan2(y - _c, x - _c); // -pi..pi
  const gapCenter = -math.pi / 4;
  var da = (ang - gapCenter).abs();
  if (da > math.pi) da = 2 * math.pi - da;
  final gap = _smoothstep(0.34, 0.40, da); // 0 inside gap, 1 outside
  ring *= gap;

  // Checkmark inside the ring.
  final thick = 62.0 * scale, h = thick / 2;
  double s(double v) => _c + (v - _c) * scale; // scale about center
  final dCheck = math.min(
    _distToSegment(x, y, s(430), s(520), s(478), s(582)),
    _distToSegment(x, y, s(478), s(582), s(628), s(430)),
  );
  final check = _smoothstep(h + 1.0, h - 1.0, dCheck);

  return math.max(ring, check);
}

Image _render({required bool withBackground, required double scale}) {
  final img = Image(width: _size, height: _size, numChannels: 4);
  for (var y = 0; y < _size; y++) {
    for (var x = 0; x < _size; x++) {
      final cov = _markCoverage(x + 0.5, y + 0.5, scale);
      if (withBackground) {
        // Solid teal, white mark composited on top.
        final r = (_brandR * (1 - cov) + 255 * cov).round();
        final g = (_brandG * (1 - cov) + 255 * cov).round();
        final b = (_brandB * (1 - cov) + 255 * cov).round();
        img.setPixelRgba(x, y, r, g, b, 255);
      } else {
        // Transparent background, white mark (for adaptive foreground).
        img.setPixelRgba(x, y, 255, 255, 255, (cov * 255).round());
      }
    }
  }
  return img;
}

void main() {
  Directory('assets/icon').createSync(recursive: true);

  // Full icon (iOS + legacy Android): teal background, mark at full size.
  File('assets/icon/ic_launcher.png')
      .writeAsBytesSync(encodePng(_render(withBackground: true, scale: 1.0)));

  // Adaptive foreground: white mark on transparent, scaled to sit inside the
  // 66% safe zone (Android crops the outer edge to the launcher's mask shape).
  File('assets/icon/ic_foreground.png')
      .writeAsBytesSync(encodePng(_render(withBackground: false, scale: 0.82)));

  stdout.writeln('Wrote assets/icon/ic_launcher.png and ic_foreground.png');
}

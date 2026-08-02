import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../core/app_links.dart';

/// A newer published version and where to get it.
class UpdateInfo {
  const UpdateInfo(this.version, this.url);
  final String version;
  final String url;
}

/// Tells the user when a new Saara is out — the only channel that matters on
/// **desktop**, which has no store to auto-update. It reads the latest published
/// version from the public GitHub Releases endpoint and compares it to the
/// running one.
///
/// Privacy: it sends **no user data** — a plain GET of a public version string,
/// like checking a webpage. It fails silent on every error (offline, rate limit,
/// parse) so a version check can never disrupt the app.
class UpdateChecker {
  const UpdateChecker();

  /// Reflects each published release automatically — no file to maintain.
  static const _latestApi =
      'https://api.github.com/repos/veeramaya/saara/releases/latest';

  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.realmaya.saara';

  Future<UpdateInfo?> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final res = await http
          .get(
            Uri.parse(_latestApi),
            headers: const {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final latest = (json['tag_name'] as String? ?? '')
          .trim()
          .replaceFirst(RegExp(r'^v'), '');
      if (latest.isEmpty || !_isNewer(latest, info.version)) return null;
      return UpdateInfo(latest, Platform.isAndroid ? _playUrl : kDesktopDownloadUrl);
    } catch (_) {
      return null;
    }
  }

  /// True when [latest] is a higher major.minor.patch than [current].
  static bool _isNewer(String latest, String current) {
    final a = _parts(latest), b = _parts(current);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int> _parts(String v) {
    final nums = v
        .split('.')
        .map((s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    while (nums.length < 3) {
      nums.add(0);
    }
    return nums.sublist(0, 3);
  }
}

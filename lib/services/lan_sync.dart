import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'app_settings.dart';
import 'ledger_sync_service.dart';

/// §9 device-to-device sync over the **local Wi-Fi network** — no cloud, no
/// Google, no file to move by hand. One device shows a QR code; the other scans
/// it and does a single round-trip that merges *both* directions at once.
///
/// The QR carries the host's LAN address, an ephemeral port, and a one-time
/// token. The token is also the transfer's encryption key: the bundle is
/// passphrase-encrypted with it (reusing [LedgerSyncService.exportEncrypted]),
/// so a device that never saw the QR can neither read nor push anything, even
/// on the same network.
///
/// Foreground-only by nature: the server runs only while the "Sync over Wi-Fi"
/// screen is open, matching how the user actually syncs — both apps open on the
/// same Wi-Fi for a moment, then done.

/// What the QR encodes. Compact keys keep the code small and easy to scan.
class LanPairing {
  const LanPairing({
    required this.host,
    required this.port,
    required this.token,
    required this.name,
  });

  final String host;
  final int port;
  final String token;
  final String name; // the host device's label, shown to the scanner

  String encode() =>
      json.encode({'v': 1, 'h': host, 'p': port, 't': token, 'n': name});

  /// Parse a scanned QR payload, or null if it isn't a Saara pairing code.
  static LanPairing? tryDecode(String raw) {
    try {
      final m = json.decode(raw);
      if (m is! Map || m['v'] != 1) return null;
      final host = m['h']?.toString();
      final port = m['p'] is int ? m['p'] as int : int.tryParse('${m['p']}');
      final token = m['t']?.toString();
      if (host == null || port == null || token == null) return null;
      return LanPairing(
        host: host,
        port: port,
        token: token,
        name: m['n']?.toString() ?? 'the other device',
      );
    } catch (_) {
      return null;
    }
  }
}

/// The device showing the QR. Serves exactly one endpoint — `POST /sync` — which
/// merges the caller's bundle in and hands ours back in the response, so a
/// single request syncs both ways.
class LanSyncServer {
  LanSyncServer(this._sync, this._settings);

  final LedgerSyncService _sync;
  final AppSettings _settings;

  HttpServer? _server;

  /// Called after a successful exchange, with what the peer's bundle merged in
  /// and the peer's device label — so the host UI can say "Synced with Mobile".
  void Function(MergeSummary merged, String peerName)? onSynced;

  /// Bind to the LAN and return the pairing the QR should encode. Throws a
  /// friendly message if no Wi-Fi address is found.
  Future<LanPairing> start() async {
    final token = _randomToken();
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    final host = await _lanIp();
    final name = _settings.thisDeviceLabel;

    server.listen((req) => _handle(req, token, name));
    return LanPairing(host: host, port: server.port, token: token, name: name);
  }

  Future<void> _handle(HttpRequest req, String token, String myName) async {
    try {
      if (req.method != 'POST' || req.uri.path != '/sync') {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      if (req.headers.value('x-saara-token') != token) {
        req.response.statusCode = HttpStatus.forbidden;
        await req.response.close();
        return;
      }
      final peerName =
          req.headers.value('x-saara-device') ?? 'the other device';
      final body = await utf8.decoder.bind(req).join();
      final merged = await _sync.importEncrypted(body, token); // pull peer in
      final mine = await _sync.exportEncrypted(token); // hand ours back
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.set('x-saara-device', myName)
        ..headers.contentType = ContentType.text
        ..write(mine);
      await req.response.close();
      onSynced?.call(merged, peerName);
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.internalServerError;
        await req.response.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

/// The device that scanned the QR. Drives the one round-trip exchange.
class LanSyncClient {
  LanSyncClient(this._sync, this._settings);

  final LedgerSyncService _sync;
  final AppSettings _settings;

  /// Push our bundle to [pairing]'s host and merge the host's bundle back.
  /// Returns what merged in from the host and the host's label.
  Future<({MergeSummary merged, String peerName})> syncWith(
    LanPairing pairing,
  ) async {
    final mine = await _sync.exportEncrypted(pairing.token);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.postUrl(
        Uri.parse('http://${pairing.host}:${pairing.port}/sync'),
      );
      req.headers
        ..set('x-saara-token', pairing.token)
        ..set('x-saara-device', _settings.thisDeviceLabel)
        ..contentType = ContentType.text;
      req.write(mine);
      final resp = await req.close();
      if (resp.statusCode != HttpStatus.ok) {
        throw HttpException(
          'The other device refused the sync '
          '(${resp.statusCode}). Re-show the code and try again.',
        );
      }
      final body = await utf8.decoder.bind(resp).join();
      final merged = await _sync.importEncrypted(body, pairing.token);
      return (
        merged: merged,
        peerName: resp.headers.value('x-saara-device') ?? pairing.name,
      );
    } finally {
      client.close(force: true);
    }
  }
}

String _randomToken() {
  final r = Random.secure();
  return List<int>.generate(
    24,
    (_) => r.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// This device's private-network IPv4 address, so the peer on the same Wi-Fi
/// can reach it. Prefers a private range (192.168/10./172.16–31); a link-local
/// or public address is a last resort.
Future<String> _lanIp() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  String? fallback;
  for (final ni in interfaces) {
    for (final a in ni.addresses) {
      if (_isPrivate(a.address)) return a.address;
      fallback ??= a.address;
    }
  }
  if (fallback != null) return fallback;
  throw const SocketException(
    'No Wi-Fi network found. Connect both devices to the same Wi-Fi.',
  );
}

bool _isPrivate(String ip) {
  if (ip.startsWith('192.168.')) return true;
  if (ip.startsWith('10.')) return true;
  final m = RegExp(r'^172\.(\d+)\.').firstMatch(ip);
  if (m != null) {
    final second = int.tryParse(m.group(1)!) ?? 0;
    return second >= 16 && second <= 31;
  }
  return false;
}

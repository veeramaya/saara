import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// §9 Google OAuth for **desktop**. `google_sign_in` has no Windows/Linux
/// implementation, so desktop uses Google's documented *installed-app* flow:
/// a loopback redirect to `127.0.0.1` + PKCE.
///
/// Nothing leaves the device except the direct call to Google with the user's
/// own OAuth client — there is no Realmaya server in the path (§1.4). Tokens
/// live in the OS keychain (DPAPI on Windows) via flutter_secure_storage.
class DesktopGoogleAuth {
  DesktopGoogleAuth({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kClientId = 'gauth_client_id';
  static const _kClientSecret = 'gauth_client_secret';
  static const _kRefresh = 'gauth_refresh';
  static const _kAccess = 'gauth_access';
  static const _kExpiry = 'gauth_expiry';
  static const _kEmail = 'gauth_email';

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _userInfo = 'https://www.googleapis.com/oauth2/v3/userinfo';

  // ── Client credentials (the user's own "Desktop app" OAuth client) ────────

  Future<void> saveClient({
    required String clientId,
    String? clientSecret,
  }) async {
    // A refresh token belongs to the client that issued it. Swapping in a new
    // client id/secret leaves the old token looking valid (isConnected stays
    // true) while every refresh fails with invalid_grant — sync appears
    // connected but silently does nothing. Drop the tokens so the UI honestly
    // shows "Connect" and asks for consent once.
    final previous = await _storage.read(key: _kClientId);
    final changed = previous != null && previous != clientId.trim();
    if (changed) await signOut();

    await _storage.write(key: _kClientId, value: clientId.trim());
    await _storage.write(
      key: _kClientSecret,
      value: (clientSecret ?? '').trim().isEmpty ? null : clientSecret!.trim(),
    );
  }

  Future<String?> clientId() => _storage.read(key: _kClientId);
  Future<String?> clientSecret() => _storage.read(key: _kClientSecret);
  Future<String?> connectedEmail() => _storage.read(key: _kEmail);

  Future<bool> get isConfigured async {
    final id = await clientId();
    return id != null && id.trim().isNotEmpty;
  }

  Future<bool> get isConnected async =>
      (await _storage.read(key: _kRefresh))?.isNotEmpty ?? false;

  // ── Sign-in (loopback + PKCE) ─────────────────────────────────────────────

  /// Opens the system browser for consent and completes the code exchange.
  /// Returns the signed-in email. Throws [DesktopAuthException] on failure.
  Future<String> signIn(List<String> scopes) async {
    final id = await clientId();
    if (id == null || id.trim().isEmpty) {
      throw DesktopAuthException(
        'No Google desktop client ID set. Add one in Settings → Google sync.',
      );
    }
    final secret = await clientSecret();

    // A loopback listener on an ephemeral port is the redirect target.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}';
    final verifier = _randomString(64);
    final challenge = base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final state = _randomString(24);

    final authUrl = Uri.parse(_authEndpoint).replace(
      queryParameters: {
        'client_id': id,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline', // we need a refresh token
        'prompt': 'consent',
        'state': state,
      },
    );

    try {
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw DesktopAuthException('Could not open the browser for sign-in.');
      }

      // Wait for Google to redirect back to the loopback listener.
      final request = await server.first.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw DesktopAuthException('Sign-in timed out.'),
      );
      final params = request.uri.queryParameters;
      final code = params['code'];
      final error = params['error'];

      await _respond(
        request,
        error == null && code != null
            ? 'Saara is connected. You can close this tab.'
            : 'Sign-in failed: ${error ?? 'no authorization code'}.',
      );

      if (error != null) throw DesktopAuthException('Google returned: $error');
      if (code == null) throw DesktopAuthException('No authorization code.');
      if (params['state'] != state) {
        throw DesktopAuthException('State mismatch — sign-in aborted.');
      }

      await _exchange(
        clientId: id,
        clientSecret: secret,
        code: code,
        verifier: verifier,
        redirect: redirect,
      );
      return await _fetchAndStoreEmail();
    } finally {
      await server.close(force: true);
    }
  }

  Future<void> signOut() async {
    for (final k in [_kRefresh, _kAccess, _kExpiry, _kEmail]) {
      await _storage.delete(key: k);
    }
  }

  // ── Tokens ────────────────────────────────────────────────────────────────

  /// A valid access token, refreshing when the cached one is stale. Null when
  /// the user hasn't connected yet.
  Future<String?> accessToken() async {
    final cached = await _storage.read(key: _kAccess);
    final expiryRaw = await _storage.read(key: _kExpiry);
    final expiry = expiryRaw == null ? null : DateTime.tryParse(expiryRaw);
    // 60s safety margin so a token can't expire mid-request.
    if (cached != null &&
        expiry != null &&
        DateTime.now().isBefore(expiry.subtract(const Duration(seconds: 60)))) {
      return cached;
    }
    return _refresh();
  }

  Future<String?> _refresh() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null || refresh.isEmpty) return null;
    final id = await clientId();
    if (id == null) return null;
    final secret = await clientSecret();

    final res = await _http.post(
      Uri.parse(_tokenEndpoint),
      body: {
        'client_id': id,
        if (secret != null && secret.isNotEmpty) 'client_secret': secret,
        'refresh_token': refresh,
        'grant_type': 'refresh_token',
      },
    );
    if (res.statusCode >= 400) {
      // Refresh token revoked/expired — force a fresh consent next time.
      await signOut();
      throw DesktopAuthException(
        'Google sign-in expired. Connect again in Settings.',
      );
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    return _storeTokens(data);
  }

  Future<void> _exchange({
    required String clientId,
    required String? clientSecret,
    required String code,
    required String verifier,
    required String redirect,
  }) async {
    final res = await _http.post(
      Uri.parse(_tokenEndpoint),
      body: {
        'client_id': clientId,
        if (clientSecret != null && clientSecret.isNotEmpty)
          'client_secret': clientSecret,
        'code': code,
        'code_verifier': verifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirect,
      },
    );
    if (res.statusCode >= 400) {
      throw DesktopAuthException(
        'Token exchange failed (${res.statusCode}): ${res.body}',
      );
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final refresh = data['refresh_token']?.toString();
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refresh);
    }
    await _storeTokens(data);
  }

  Future<String?> _storeTokens(Map<String, dynamic> data) async {
    final access = data['access_token']?.toString();
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    if (access == null) return null;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(
      key: _kExpiry,
      value: DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
    );
    return access;
  }

  Future<String> _fetchAndStoreEmail() async {
    final token = await accessToken();
    if (token == null) return '';
    final res = await _http.get(
      Uri.parse(_userInfo),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode >= 400) return '';
    final email =
        (json.decode(res.body) as Map<String, dynamic>)['email']?.toString() ??
        '';
    if (email.isNotEmpty) await _storage.write(key: _kEmail, value: email);
    return email;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _respond(HttpRequest request, String message) async {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(
        '<!doctype html><meta charset="utf-8">'
        '<title>Saara</title>'
        '<body style="font-family:system-ui;display:grid;place-items:center;'
        'height:100vh;margin:0;background:#faf8f6;color:#1b1613">'
        '<div style="text-align:center">'
        '<h2 style="color:#cc1a1a;margin:0 0 8px">Saara</h2>'
        '<p>$message</p></div></body>',
      );
    await request.response.close();
  }

  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  void close() => _http.close();
}

class DesktopAuthException implements Exception {
  DesktopAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

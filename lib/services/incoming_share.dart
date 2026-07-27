import 'package:flutter/services.dart';

/// §9 Share-to-Saara bridge. The native side (MainActivity.kt) receives a
/// ledger file shared or opened from another app (WhatsApp, Files, email) and
/// holds its text; Flutter pulls it here on launch and on resume, then runs the
/// normal ledger import. Android-only — desktop/iOS return null quietly.
class IncomingShare {
  static const _channel = MethodChannel('saara/incoming_share');

  /// The text of a ledger file shared into Saara since we last asked, or null.
  /// The native side clears it once returned, so it is delivered exactly once.
  static Future<String?> consume() async {
    try {
      final text = await _channel.invokeMethod<String>('consumeSharedText');
      return (text != null && text.isNotEmpty) ? text : null;
    } on MissingPluginException {
      return null; // no native handler (desktop)
    } on PlatformException {
      return null;
    }
  }
}

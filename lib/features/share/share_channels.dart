import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// §13 pick a delivery channel for shared **text**.
///
/// The OS share sheet only lists *installed* apps — on Windows that means
/// Outlook / Teams / Zoom and never WhatsApp or Gmail. These two are offered
/// explicitly through their web handoff URLs, which work on every platform and
/// open the native app on mobile.
///
/// Images can't go this way (a URL can only carry text), so a card image still
/// uses the OS sheet — see the note where it's called.
Future<void> shareTextViaChannels(
  BuildContext context, {
  required String text,
  String? subject,

  /// Pre-fills the Gmail "to" field when the recipient is known.
  String? toEmail,

  /// Pre-fills the WhatsApp recipient when a number is known.
  String? toPhone,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('WhatsApp'),
            onTap: () {
              Navigator.pop(ctx);
              final digits = (toPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              launchUrl(
                Uri.parse(
                  'https://wa.me/$digits?text=${Uri.encodeComponent(text)}',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Gmail'),
            onTap: () {
              Navigator.pop(ctx);
              launchUrl(
                Uri.parse(
                  'https://mail.google.com/mail/?view=cm&fs=1'
                  '&to=${Uri.encodeComponent(toEmail ?? '')}'
                  '&su=${Uri.encodeComponent(subject ?? '')}'
                  '&body=${Uri.encodeComponent(text)}',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy to clipboard'),
            onTap: () async {
              Navigator.pop(ctx);
              await Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Other apps…'),
            subtitle: const Text('Your device\'s share sheet'),
            onTap: () {
              Navigator.pop(ctx);
              Share.share(text, subject: subject);
            },
          ),
        ],
      ),
    ),
  );
}

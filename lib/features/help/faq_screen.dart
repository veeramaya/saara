import 'package:flutter/material.dart';

/// §14 / §20.2 Help & FAQ — plain answers about what Saara does and how it
/// treats your data. Grounded in the app's real behaviour: local-first,
/// on-device encryption, device→Google-direct sync, and no Realmaya server.
/// Re-openable from Settings; the Privacy tile lands here too.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & FAQ')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          8 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Local-first by design: your record lives on your device, '
                    'encrypted. There is no Realmaya server and no telemetry.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          for (final section in _faq) _FaqSection(section: section),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection({required this.section});
  final _Section section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Row(
            children: [
              Icon(section.icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        for (final qa in section.items)
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              qa.q,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            children: [
              Text(
                qa.a,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
      ],
    );
  }
}

class _Section {
  const _Section(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<_Qa> items;
}

class _Qa {
  const _Qa(this.q, this.a);
  final String q, a;
}

const _faq = <_Section>[
  _Section('Features', Icons.auto_awesome_outlined, [
    _Qa(
      'What is Saara?',
      'A local-first integrity companion. You give your word — tasks and '
          'events — Saara helps you keep it and keeps an honest score of '
          'whether you did. The people you gave your word to are the mirror. '
          'It is not an information house; it is here to help you declare, '
          'commit, and honour.',
    ),
    _Qa(
      'Task or event — what\'s the difference?',
      'A task is a to-do with an end date/time (it can have a duration) and '
          'syncs with Google Tasks. An event is time-blocked and syncs both '
          'ways with Google Calendar — create it in Saara and it appears '
          'there. Both can repeat; a repeating series syncs as one rule, and '
          'each device expands its own dates.',
    ),
    _Qa(
      'How is my score worked out?',
      'Binary and honest: kept = +1, not kept = 0. Kept ÷ committed is your '
          'effectiveness — per area and overall — and places you on a '
          'reliability ladder from Beginner to Masterful. The number is a '
          'compass, not a verdict.',
    ),
    _Qa(
      'What are areas?',
      'The spaces of your life — Health, Career, Relationships, Finance, '
          'Growth, Leisure — each carrying its own score, so you see the shape '
          'of your reliability, not one flat number.',
    ),
    _Qa(
      'Measurable results and money?',
      'Attach a number so "done" is unambiguous — "walk 8,000 steps". Money '
          'is just a measurable in currency — "save ₹5,000 this month". Hit '
          'the number, it counts; fall short, it doesn\'t. No grey zone.',
    ),
    _Qa(
      'How do I capture quickly?',
      'Type it, paste a message, dictate with the mic, or photograph a note '
          'or invite. With your own AI key, Saara reads it into fields you '
          'verify against the original. Without a key, the built-in parser '
          'still handles dates and recurrence.',
    ),
    _Qa(
      'Open and close your day (the daily ritual)?',
      'A gentle practice: in the morning, declare your word for the day; in '
          'the evening, honor what you kept, restore what you didn\'t in a '
          'line of your own, and close. It becomes a shareable Day Card — one '
          'face for the open, one for the close.',
    ),
    _Qa(
      'Reminders and arrival prompts?',
      'Turn on a per-task reminder for a heads-up before it starts. Add a '
          'location and "notify me when I arrive" for an on-the-spot nudge. '
          'Location is used only for tasks you attach it to.',
    ),
    _Qa(
      'What are the "overlaps" Saara flags?',
      'When two timed items share the clock, Saara surfaces the overlap as '
          'information, never a verdict — people genuinely multitask. Keep '
          'both, or move one to a suggested free slot. Your call, and it '
          'remembers what you decided.',
    ),
  ]),
  _Section('Sync & your devices', Icons.devices_outlined, [
    _Qa(
      'How does syncing work?',
      'Two independent ways. Google: two-way with Google Tasks and Calendar, '
          'device → Google directly. And device-to-device: keep phone and '
          'desktop in step over Wi-Fi (one shows a QR, the other scans) or via '
          'a ledger file — this carries what Google can\'t, like your areas, '
          'history and provenance, and never goes through Google.',
    ),
    _Qa(
      'When two devices disagree, which wins?',
      'The most recently updated version of a row wins — last-writer-wins by '
          'update time. Your history is never overwritten: the ledger of what '
          'happened is append-only and merged as a union, so every device '
          'keeps every entry.',
    ),
    _Qa(
      'If I delete something, does it delete on my other device?',
      'Yes. A delete is a tombstone that travels with the sync, including for '
          'items re-imported from Google under new ids and for individual '
          'recurring dates. Deletes are soft — they move to Trash and can be '
          'restored.',
    ),
    _Qa(
      'I see duplicates / phantom overlaps. How do I fix them?',
      'An older sync could leave duplicate copies that overlap themselves. '
          'Settings → Remove duplicate tasks cleans them up (restorable from '
          'Trash), keeping the best-attested copy. Run it on each device, then '
          'sync.',
    ),
    _Qa(
      'Where was a task created?',
      'Search shows each task\'s origin — "This device", the other device\'s '
          'name, or "Google" — and you can filter to just the ones created on '
          'this device. It reads from the ledger, so it reflects true origin.',
    ),
  ]),
  _Section('Sharing & listeners', Icons.ios_share_outlined, [
    _Qa(
      'Who can I share with, and how?',
      'Your committed listeners and the people on a task — over your own '
          'WhatsApp or mail. Nothing carries Saara branding; it reads as your '
          'commitment, not an advert.',
    ),
    _Qa(
      'Invitation vs report card?',
      'An invitation is before the fact ("you\'re invited" / "I\'ve committed '
          'to"); a report is after ("kept my word" / "fell short"). Both are '
          'flip cards — if the details don\'t fit one face they roll onto the '
          'next, so nothing is clipped.',
    ),
    _Qa(
      'What is the share book?',
      'A filtered album of your cards — choose the type (report or '
          'invitation), the range, an area, and which outcomes — exported as '
          'one self-contained web page (a flipbook). It opens in any browser, '
          'works offline, and nothing is uploaded. Reach it from Share-your-'
          'day or the Committed listeners screen.',
    ),
    _Qa(
      'What exactly gets shared on a card?',
      'Only the fields you tick. Notes, review notes, and your scores stay '
          'off unless you deliberately turn them on. You see a live preview '
          'before anything leaves the device.',
    ),
  ]),
  _Section('Privacy & security', Icons.lock_outline, [
    _Qa(
      'Where is my data stored?',
      'On your device only, in an encrypted database (SQLCipher). The '
          'encryption key is held in the operating system\'s secure store '
          '(Android Keystore / iOS Keychain / Windows credential store), not '
          'in the app.',
    ),
    _Qa(
      'Does Realmaya (or anyone) see my data?',
      'No. There is no Realmaya server, no account to sign up for, and no '
          'telemetry or analytics. Your record never leaves your device except '
          'to services you connect yourself (Google, or your AI provider), and '
          'only for what you asked.',
    ),
    _Qa(
      'How does Google sync stay private?',
      'Your device talks to Google directly — there is no middle server. Saara '
          'uses only the scopes it needs: your Calendar events, your Tasks, '
          'and a private app-data folder on your Drive for the encrypted '
          'device-to-device sync file. You can disconnect Google at any time.',
    ),
    _Qa(
      'How does the AI work — is my data sent anywhere?',
      'Only if you add your own AI key (Gemini or Claude). Then the text you '
          'ask it to read goes straight from your device to that provider under '
          'your key — never through Realmaya. No key means no AI calls; the '
          'deterministic parser still works offline.',
    ),
    _Qa(
      'What about contacts and phone numbers?',
      'A participant\'s number is read from your address book when you add '
          'them and stored on your device to call or message them later. It '
          'travels only between your own devices via the encrypted sync — never '
          'through Google.',
    ),
    _Qa(
      'Does Saara track my location?',
      'No background tracking. Location is used only if you attach a place to '
          'a task and enable an arrival reminder. Saara never auto-detects '
          'your location or region — you choose your region explicitly.',
    ),
    _Qa(
      'Is the device-to-device sync file safe in a cloud folder?',
      'Yes. The ledger sync file is passphrase-encrypted (AES with PBKDF2 key '
          'stretching), so even if it lands in a shared or cloud folder it is '
          'unreadable without your passphrase.',
    ),
  ]),
  _Section('Your data & control', Icons.tune_outlined, [
    _Qa(
      'Can I export everything?',
      'Yes — Settings → Export all my data writes a local .zip of every task, '
          'area and capture, and you choose where it goes. It never leaves '
          'your device unless you send it.',
    ),
    _Qa(
      'How do deletes and restore work?',
      'Deleting moves an item to Trash, where you can restore it. A permanent '
          'reset of local data is available in Settings for when you want a '
          'clean slate.',
    ),
    _Qa(
      'What permissions does Saara ask for, and why?',
      'Notifications for reminders; optional location for arrival prompts; '
          'optional contacts for people on a task; optional microphone and '
          'camera for voice and photo capture. Each is used only for its '
          'feature, and the app works without granting the optional ones.',
    ),
  ]),
];

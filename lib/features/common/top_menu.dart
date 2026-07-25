import 'package:flutter/material.dart';

import '../evening/evening_review_screen.dart';
import '../morning/morning_brief_screen.dart';
import '../settings/settings_screen.dart';

/// §20.1 the app's cross-tab overflow menu. The daily rituals and Settings used
/// to live only on the Today app bar; this puts them one tap away from *every*
/// tab, so a user in Tasks or Areas isn't stranded from Settings.
class SaaraTopMenu extends StatelessWidget {
  const SaaraTopMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More',
      onSelected: (i) {
        final Widget screen = switch (i) {
          0 => const MorningBriefScreen(),
          1 => const EveningReviewScreen(),
          _ => const SettingsScreen(),
        };
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.wb_sunny_outlined),
            title: Text('Open your day'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.nightlight_outlined),
            title: Text('Complete your day'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

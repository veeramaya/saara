import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/agent/saara_agent_screen.dart';
import 'features/areas/areas_screen.dart';
import 'features/coach/coach_screen.dart';
import 'features/home/home_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/search/task_search_screen.dart';
import 'providers.dart';

/// Root widget. §20.1 bottom NavigationBar: Today · Tasks · Areas · Progress ·
/// Saara. Tasks is the global searchable list (§7); Saara is the conversational
/// agent (§6/§19). Settings opens from the gear icon on the Today app bar.
class SaaraApp extends StatelessWidget {
  const SaaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saara',
      debugShowCheckedModeBanner: false,
      theme: SaaraTheme.light(),
      darkTheme: SaaraTheme.dark(),
      themeMode: ThemeMode.system, // §20.1 respects system setting
      // Force 12-hour AM/PM everywhere. Saara talks in "6:15 PM" throughout
      // (agenda slots, timers, reports), so a 24-hour picker inherited from the
      // OS locale made entry ambiguous against the rest of the UI.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
      home: const _RootShell(),
    );
  }
}

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell>
    with WidgetsBindingObserver {
  int _index = 0;
  Timer? _syncTimer;
  DateTime? _lastAutoSync;

  @override
  void initState() {
    super.initState();
    // Foreground auto-sync (§9): on open, on resume, and periodically while
    // open. Background (app closed) sync is the WorkManager job (opt-in).
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowCoach());
    _syncTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _autoSync(),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoSync();
  }

  /// First-run coach flow (§20.2) — shown once until dismissed; re-openable
  /// from Settings → How Saara works.
  Future<void> _maybeShowCoach() async {
    try {
      final settings = ref.read(appSettingsProvider);
      if (await settings.coachSeen()) return;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CoachScreen(onDone: settings.setCoachSeen),
          fullscreenDialog: true,
        ),
      );
    } catch (_) {
      // coach is non-critical — never block the app if it fails
    }
  }

  /// Silent Google Tasks reconcile if connected. Debounced so rapid
  /// resume/open events don't stack.
  Future<void> _autoSync() async {
    final now = DateTime.now();
    if (_lastAutoSync != null &&
        now.difference(_lastAutoSync!) < const Duration(seconds: 45)) {
      return;
    }
    _lastAutoSync = now;
    try {
      // Ask *are we connected*, not "is there an account object". Desktop has
      // no GoogleSignInAccount (it uses the loopback flow), so the old
      // `restore() == null` check silently disabled auto-sync there entirely —
      // desktop-created tasks never reached the phone.
      if (!await ref.read(googleSyncServiceProvider).isConnected()) return;
      await ref.read(googleSyncOrchestratorProvider).syncAll();
      await ref.read(appSettingsProvider).setLastSync(DateTime.now());
      if (!mounted) return;
      ref.invalidate(
        tasksForDayProvider(DateTime(now.year, now.month, now.day)),
      );
    } catch (_) {
      // silent — auto-sync must never disrupt the UI
    }
  }

  static const _tabs = <Widget>[
    HomeScreen(),
    TaskSearchScreen(),
    AreasScreen(),
    ReportsScreen(),
    SaaraAgentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          // Today + calendar share this slot — the screen toggles between the
          // day's list and week / 2-week / month (§7).
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large),
            label: 'Areas',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Saara',
          ),
        ],
      ),
    );
  }
}

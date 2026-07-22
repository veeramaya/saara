import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../../core/platform.dart';
import '../../providers.dart';
import '../../services/google/auto_sync.dart';
import '../../services/google/google_sync_service.dart';

/// §9 Google Tasks sync UI: connect, import Google Tasks → Saara, push Saara
/// tasks → Google (they appear in the Calendar app's Tasks layer). All traffic
/// is device→Google directly; Realmaya sees none of it (§1.1).
class GoogleSyncScreen extends ConsumerStatefulWidget {
  const GoogleSyncScreen({super.key});

  @override
  ConsumerState<GoogleSyncScreen> createState() => _GoogleSyncScreenState();
}

class _GoogleSyncScreenState extends ConsumerState<GoogleSyncScreen> {
  GoogleSignInAccount? _account;
  // Desktop (loopback OAuth) state — mobile uses [_account] instead.
  String? _desktopEmail;
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();

  /// Connected on either platform.
  bool get _connected => isDesktop ? _desktopEmail != null : _account != null;
  bool _busy = false;
  bool _autoSync = false;
  DateTime? _lastSync;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restore();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(appSettingsProvider);
    final on = await settings.autoSyncEnabled();
    final last = await settings.lastSyncAt();
    if (mounted) {
      setState(() {
        _autoSync = on;
        _lastSync = last;
      });
    }
  }

  @override
  void dispose() {
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(googleSyncServiceProvider);
      if (isDesktop) {
        _clientId.text = await service.desktopAuth.clientId() ?? '';
        _clientSecret.text = await service.desktopAuth.clientSecret() ?? '';
        final email = await service.desktopAuth.connectedEmail();
        final live = await service.desktopAuth.isConnected;
        if (mounted) {
          setState(() => _desktopEmail = live ? (email ?? 'Connected') : null);
        }
      } else {
        final acct = await service.restore();
        if (mounted) setState(() => _account = acct);
      }
    } catch (_) {
      // silent restore failure is fine — user can connect manually
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Tasks sync')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Connect your Google account to import your Google Tasks and push '
            'Saara tasks back — they show in the Google Calendar app\'s Tasks '
            'layer. Everything goes device → Google directly.',
          ),
          const SizedBox(height: 20),
          if (!_connected) ...[
            if (isDesktop) ...[
              TextField(
                controller: _clientId,
                decoration: const InputDecoration(
                  labelText: 'Google desktop client ID',
                  helperText:
                      'Cloud Console → Credentials → OAuth client ID → '
                      'Application type: Desktop app',
                  helperMaxLines: 3,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clientSecret,
                decoration: const InputDecoration(
                  labelText: 'Client secret',
                  helperText:
                      'Shown beside the client ID in Cloud Console. '
                      'Google requires it for Desktop-app clients even with '
                      'PKCE. Stored in the OS keychain, never sent anywhere '
                      'but Google.',
                  helperMaxLines: 4,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: Text(
                isDesktop ? 'Connect Google (opens browser)' : 'Connect Google',
              ),
              onPressed: _busy ? null : _connect,
            ),
          ] else ...[
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(_desktopEmail ?? _account!.email),
                subtitle: Text(
                  isDesktop
                      ? 'Connected'
                      : (_account!.displayName ?? 'Connected'),
                ),
                trailing: TextButton(
                  onPressed: _busy ? null : _disconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Sync now'),
              onPressed: _busy ? null : _sync,
            ),
            const SizedBox(height: 8),
            Text(
              'Two-way: creates, edits, completions, and deletes flow both ways '
              '(last edit wins). Deleting on one side deletes on the other.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_lastSync != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Last synced ${DateFormat.MMMd().add_jm().format(_lastSync!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const Divider(height: 32),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoSync,
              title: const Text('Auto-sync'),
              subtitle: const Text(
                'On open + in the background (~30 min) while connected',
              ),
              onChanged: _busy ? null : _toggleAutoSync,
            ),
            const Divider(height: 32),
            // One-off repair for the duplication bug (§9). Shows the count and
            // requires confirmation — nothing is deleted unseen.
            Text(
              'Clean up duplicates',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'An earlier version pushed one copy per date for repeating tasks, '
              'which piled up in Google. This removes only those copies.\n\n'
              'Events you did not create in Saara are never touched — anything '
              'imported from your Google Calendar is excluded.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.cleaning_services_outlined),
              label: const Text('Check for duplicate copies'),
              onPressed: _busy ? null : _cleanupDuplicates,
            ),
          ],
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _status!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = null;
    });
    try {
      final service = ref.read(googleSyncServiceProvider);
      if (isDesktop) {
        // Save the user's own "Desktop app" OAuth client, then run the
        // loopback + PKCE flow (opens the system browser).
        await service.desktopAuth.saveClient(
          clientId: _clientId.text.trim(),
          clientSecret: _clientSecret.text.trim(),
        );
        final email = await service.connectDesktop();
        setState(() => _desktopEmail = email.isEmpty ? 'Connected' : email);
      } else {
        final acct = await service.connect();
        setState(() => _account = acct);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    try {
      await ref.read(googleSyncServiceProvider).disconnect();
      setState(() {
        _account = null;
        _desktopEmail = null;
        _status = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleAutoSync(bool on) async {
    setState(() => _autoSync = on);
    await ref.read(appSettingsProvider).setAutoSync(on);
    try {
      if (on) {
        await enableBackgroundSync();
      } else {
        await disableBackgroundSync();
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Background sync unavailable: $e');
    }
  }

  Future<void> _sync() => _run(() async {
    final s = await ref.read(googleSyncOrchestratorProvider).syncAll();
    await ref.read(appSettingsProvider).setLastSync(DateTime.now());
    if (mounted) setState(() => _lastSync = DateTime.now());
    return s.toString();
  });

  /// Counts the stray per-date copies first and asks before deleting anything.
  /// The count is the user's chance to say "that number looks wrong" *before*
  /// a single item is removed.
  Future<void> _cleanupDuplicates() async {
    final orch = ref.read(googleSyncOrchestratorProvider);
    setState(() => _busy = true);
    int count;
    try {
      count = await orch.countStrayOccurrences();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not check: $e';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (count == 0) {
      setState(() => _status = 'Nothing to clean up — no duplicate copies.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove duplicate copies?'),
        content: Text(
          'Saara will delete $count per-date cop${count == 1 ? 'y' : 'ies'} it '
          'pushed to Google for repeating tasks.\n\n'
          'Your repeating tasks stay in Saara. Nothing you created directly in '
          'Google Calendar is touched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove $count'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _run(() async {
      final removed = await orch.cleanupStrayOccurrences();
      return 'Removed $removed duplicate cop'
          '${removed == 1 ? 'y' : 'ies'} from Google.';
    });
  }

  Future<void> _run(Future<String> Function() op) async {
    setState(() {
      _busy = true;
      _status = null;
      _error = null;
    });
    try {
      final msg = await op();
      // New/changed tasks — refresh today's timeline.
      final now = DateTime.now();
      ref.invalidate(
        tasksForDayProvider(DateTime(now.year, now.month, now.day)),
      );
      if (mounted) setState(() => _status = msg);
    } on GoogleSyncException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

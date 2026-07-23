import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/platform.dart';
import '../../providers.dart';
import '../../services/feedback_service.dart';
import '../../services/notification_service.dart';
import '../coach/coach_screen.dart';
import '../google/google_sync_screen.dart';
import '../import/import_screen.dart';
import '../listeners/listeners_screen.dart';
import 'ai_settings_screen.dart';
import 'storage_screen.dart';

/// §8 / §14 Settings. Phase 1 surface: notification times, per-task reminder
/// default, Excel task import, feedback-to-maker mailto, and an on-device AI status
/// line (§6 Tier 1 — reported as "Not supported" until Phase 3 wiring). Google
/// account/scopes, storage meter, and export-all land with their phases (§17).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 0); // §7.3 default
  TimeOfDay _evening = const TimeOfDay(hour: 21, minute: 0); // §7.4 default
  bool _exporting = false;
  bool _resetting = false;
  bool _ledgerBusy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _sectionTitle('Daily rhythm'),
          ListTile(
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Morning brief'),
            subtitle: const Text('Open your day'),
            trailing: Text(_morning.format(context)),
            onTap: () => _pickTime(isMorning: true),
          ),
          ListTile(
            leading: const Icon(Icons.nightlight_outlined),
            title: const Text('Evening review'),
            subtitle: const Text('Complete your day'),
            trailing: Text(_evening.format(context)),
            onTap: () => _pickTime(isMorning: false),
          ),

          const Divider(),
          _sectionTitle('Intelligence'),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('Saara AI (your key)'),
            subtitle: const Text('Bring your own Gemini or Claude key'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AiSettingsScreen())),
          ),

          const Divider(),
          _sectionTitle('Import'),
          ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: const Text('Import tasks'),
            subtitle: const Text('Offline migration from an Excel or CSV file'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ImportScreen())),
          ),
          // Mobile uses google_sign_in; desktop uses the loopback OAuth flow.
          if (supportsGoogleSignIn || isDesktop)
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Google Tasks sync'),
              subtitle: const Text(
                'Import & push tasks; shows in Google Calendar',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GoogleSyncScreen()),
              ),
            ),
          if (supportsHealth)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Sync from Health Connect'),
              subtitle: const Text('Auto-score steps / sleep / weight results'),
              onTap: _syncHealth,
            ),

          const Divider(),
          _sectionTitle('Sharing'),
          ListTile(
            leading: const Icon(Icons.hearing_outlined),
            title: const Text('Committed listeners'),
            subtitle: const Text('People who witness you keeping your word'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ListenersScreen())),
          ),

          const Divider(),
          _sectionTitle('Data'),
          ListTile(
            leading: const Icon(Icons.sd_storage_outlined),
            title: const Text('Storage'),
            subtitle: const Text(
              'What photos, video & audio are using — and '
              'reclaim space',
            ),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const StorageScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: const Text('Export all my data'),
            subtitle: const Text(
              'A local .zip of every task, area & capture — '
              'you choose where it goes',
            ),
            trailing: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _exporting ? null : _exportData,
          ),
          // §9 device-to-device sync through a file, not the cloud.
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('Sync between my devices'),
            subtitle: const Text(
              'Export a ledger file, import one from another device — '
              'your record travels, never through Google',
            ),
            trailing: _ledgerBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _ledgerBusy ? null : _ledgerSyncSheet,
          ),
          ListTile(
            leading: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Reset local data'),
            subtitle: const Text(
              'Start this device over — use only if sync has gone wrong',
            ),
            trailing: _resetting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: _resetting ? null : _resetLocalData,
          ),

          const Divider(),
          _sectionTitle('About & feedback'),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('How Saara works'),
            subtitle: const Text('A quick tour of every feature'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CoachScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('Send feedback to the maker'),
            subtitle: const Text(
              'Opens your email app — nothing is sent '
              'automatically',
            ),
            onTap: _sendFeedback,
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy'),
            subtitle: Text('Local-first · zero data collection · no telemetry'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Future<void> _pickTime({required bool isMorning}) async {
    final initial = isMorning ? _morning : _evening;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (isMorning) {
        _morning = picked;
      } else {
        _evening = picked;
      }
    });

    // Reschedule the corresponding daily agent notification (§8).
    final service = NotificationService.instance;
    await service.requestPermission();
    if (isMorning) {
      await service.scheduleDailyAgent(
        id: NotificationService.morningId,
        hour: picked.hour,
        minute: picked.minute,
        title: 'Open your day',
        body: 'Your plan is ready. Commit to today.',
      );
    } else {
      await service.scheduleDailyAgent(
        id: NotificationService.eveningId,
        hour: picked.hour,
        minute: picked.minute,
        title: 'Complete your day',
        body: 'Give each task its disposition.',
      );
    }
  }

  /// §10 pull steps/sleep/weight from Health Connect and refresh health results.
  Future<void> _syncHealth() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Syncing from Health…')),
    );
    try {
      final n = await ref.refresh(healthSyncProvider.future);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            n < 0
                ? 'Health access not granted — allow it in Health Connect.'
                : n == 0
                ? 'No health-source results yet. Add one in an Area (e.g. "8000 steps").'
                : 'Synced $n health result${n == 1 ? '' : 's'}.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Health sync failed: $e')),
        );
      }
    }
  }

  /// §9 device-to-device sync. Two plain choices: send this device's record out
  /// as a file, or pull one in. No cloud, no account — the file is the channel,
  /// and where it travels (USB, a synced folder, AirDrop) is the user's call.
  Future<void> _ledgerSyncSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Your record — tasks, history and areas — moves as a file. '
                'It never goes through Google. Export on one device, import on '
                'the other; do it either way, as often as you like.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Export a ledger file'),
              subtitle: const Text('Share it to your other device'),
              onTap: () => Navigator.pop(ctx, 'export'),
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Import a ledger file'),
              subtitle: const Text(
                'Merge another device\'s record into this one',
              ),
              onTap: () => Navigator.pop(ctx, 'import'),
            ),
            const Divider(),
            FutureBuilder<bool>(
              future: ref.read(ledgerFolderSyncProvider).isConfigured,
              builder: (context, snap) {
                final on = snap.data ?? false;
                return ListTile(
                  leading: Icon(
                    on ? Icons.folder_shared : Icons.folder_open_outlined,
                  ),
                  title: Text(
                    on ? 'Automatic folder sync — on' : 'Set up automatic sync',
                  ),
                  subtitle: Text(
                    on
                        ? 'Saara syncs through your folder on open. Tap to '
                              'change or turn off.'
                        : 'Pick a folder both devices can see (a synced drive, '
                              'OneDrive…) and Saara keeps them in step',
                  ),
                  onTap: () =>
                      Navigator.pop(ctx, on ? 'folder-manage' : 'folder-on'),
                );
              },
            ),
          ],
        ),
      ),
    );
    if (choice == 'export') await _ledgerExport();
    if (choice == 'import') await _ledgerImport();
    if (choice == 'folder-on') await _folderSyncEnable();
    if (choice == 'folder-manage') await _folderSyncManage();
  }

  Future<void> _folderSyncEnable() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder both devices can see',
    );
    if (dir == null || !mounted) return;
    final passphrase = await _askPassphrase(creating: true);
    if (passphrase == null || passphrase.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ledgerBusy = true);
    try {
      final result = await ref
          .read(ledgerFolderSyncProvider)
          .enable(dir, passphrase);
      _refreshAfterMerge();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text('Folder sync on. $result'),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not set up: $e')));
    } finally {
      if (mounted) setState(() => _ledgerBusy = false);
    }
  }

  Future<void> _folderSyncManage() async {
    final path = await ref.read(ledgerFolderSyncProvider).folderPath();
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Automatic folder sync'),
        content: Text('Syncing through:\n$path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'off'),
            child: const Text('Turn off'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'now'),
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
    if (choice == 'off') {
      await ref.read(ledgerFolderSyncProvider).disable();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder sync turned off.')),
        );
      }
    } else if (choice == 'now') {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _ledgerBusy = true);
      try {
        final result = await ref.read(ledgerFolderSyncProvider).syncNow();
        _refreshAfterMerge();
        if (mounted && result != null) {
          messenger.showSnackBar(SnackBar(content: Text(result.toString())));
        }
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      } finally {
        if (mounted) setState(() => _ledgerBusy = false);
      }
    }
  }

  void _refreshAfterMerge() {
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    ref.invalidate(tasksForDayProvider);
    ref.invalidate(tasksBetweenProvider);
    ref.invalidate(scheduleConflictsProvider);
    ref.invalidate(activeAreasProvider);
    ref.invalidate(areaScoresProvider);
    ref.invalidate(overallEffectivenessProvider);
  }

  /// Ask for the passphrase that protects the ledger file. The same one is set
  /// on both devices; it is what makes the file safe to leave in a cloud folder.
  Future<String?> _askPassphrase({required bool creating}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ledger passphrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              creating
                  ? 'Set a passphrase to protect this file. You will type the '
                        'same one when you import it on your other device. If '
                        'you lose it, the file cannot be read — there is no '
                        'recovery.'
                  : 'Enter the passphrase this file was exported with.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passphrase',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (v) => Navigator.pop(ctx, v),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(creating ? 'Export' : 'Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _ledgerExport() async {
    // No password by default — a manual transfer between your own devices does
    // not need one. Offer it for when the file will sit somewhere shared.
    final protect =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Export ledger file'),
            content: const Text(
              'Add a password? Skip it for a quick transfer to your own '
              'device. Add one if the file will sit in a shared or cloud '
              'folder where others could open it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Skip — no password'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add a password'),
              ),
            ],
          ),
        ) ??
        false;
    if (!mounted) return;

    String? passphrase;
    if (protect) {
      passphrase = await _askPassphrase(creating: true);
      if (passphrase == null || passphrase.isEmpty || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ledgerBusy = true);
    try {
      final sync = ref.read(ledgerSyncServiceProvider);
      final content = passphrase == null
          ? await sync.exportJson()
          : await sync.exportEncrypted(passphrase);
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final file = File('${dir.path}/saara-ledger-$stamp.saara');
      await file.writeAsString(content);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Saara ledger',
        text: passphrase == null
            ? 'My Saara record — import this on your other device.'
            : 'My Saara record — import this with the password you set.',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _ledgerBusy = false);
    }
  }

  Future<void> _ledgerImport() async {
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose a Saara ledger file',
      type: FileType.any,
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _ledgerBusy = true);
    try {
      final content = await File(path).readAsString();
      final sync = ref.read(ledgerSyncServiceProvider);
      // Only a protected file asks for a password; a plain one just imports.
      String? passphrase;
      if (sync.isEncrypted(content)) {
        setState(() => _ledgerBusy = false);
        passphrase = await _askPassphrase(creating: false);
        if (passphrase == null || passphrase.isEmpty || !mounted) return;
        setState(() => _ledgerBusy = true);
      }
      final summary = await sync.importFile(content, passphrase: passphrase);
      // Everything on screen may have changed — rebuild the graph.
      ref.invalidate(allTasksProvider);
      ref.invalidate(unscheduledTasksProvider);
      ref.invalidate(tasksForDayProvider);
      ref.invalidate(tasksBetweenProvider);
      ref.invalidate(scheduleConflictsProvider);
      ref.invalidate(activeAreasProvider);
      ref.invalidate(areaScoresProvider);
      ref.invalidate(overallEffectivenessProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            summary.isEmpty
                ? 'Already up to date — nothing new to merge.'
                : summary.toString(),
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally {
      if (mounted) setState(() => _ledgerBusy = false);
    }
  }

  /// §1.1 wipe this device's data. Destructive and irreversible, so the flow is
  /// deliberately two steps: an explainer that states plainly what survives and
  /// what does not (and offers Export first), then a typed confirmation.
  ///
  /// The honesty that matters: because Saara is local-first and Realmaya stores
  /// nothing, the integrity ledger, captures and review notes have **no copy
  /// anywhere**. Only Google-synced tasks and events come back.
  Future<void> _resetLocalData() async {
    final scheme = Theme.of(context).colorScheme;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset local data?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'When to use this\n'
                'Only if this device has got into a bad state — duplicated '
                'tasks, items that keep coming back, or sync you can\'t '
                'straighten out. It is not needed for normal use.',
              ),
              const SizedBox(height: 14),
              Text(
                'What comes back',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              const Text(
                'Tasks and events that were synced to Google return the next '
                'time you connect and sync.',
              ),
              const SizedBox(height: 14),
              Text(
                'What is gone for good',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.error,
                ),
              ),
              const Text(
                'These live only on this device — Realmaya keeps no copy, so '
                'nothing can restore them:\n'
                '• your integrity history (every start, completion and miss)\n'
                '• captures — photos, audio and video\n'
                '• private event review notes\n'
                '• areas and measurable results\n'
                '• anything never synced to Google\n\n'
                'You will also need to reconnect Google and re-enter your AI '
                'key. This cannot be undone.',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Export your data first — it takes a moment and keeps a copy '
                  'of everything above.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _exportData();
            },
            child: const Text('Export first'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    // Second gate: typing the word makes this a decision, not a mis-tap.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TypeToConfirmDialog(word: 'RESET'),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resetting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(resetServiceProvider).wipeLocalData();
      // Everything on screen is now stale — rebuild the whole graph.
      ref.invalidate(allTasksProvider);
      ref.invalidate(unscheduledTasksProvider);
      ref.invalidate(deletedTasksProvider);
      ref.invalidate(tasksForDayProvider);
      ref.invalidate(tasksBetweenProvider);
      ref.invalidate(scheduleConflictsProvider);
      ref.invalidate(activeAreasProvider);
      ref.invalidate(areaScoresProvider);
      ref.invalidate(overallEffectivenessProvider);
      ref.invalidate(childTaskCountsProvider);
      ref.invalidate(aiConfigProvider);
      ref.invalidate(googleConnectedProvider);
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 6),
          content: Text(
            'This device has been reset. Connect Google in Settings to bring '
            'your synced tasks back.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Reset failed: $e')));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  /// §1.1 build the export zip and hand it to the OS share sheet. Nothing
  /// leaves the device unless the user picks a destination.
  Future<void> _exportData() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      final path = await ref.read(exportServiceProvider).exportZip();
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Saara data export',
        text: 'My Saara data export (tasks, areas, captures).',
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _sendFeedback() async {
    final info = await PackageInfo.fromPlatform();
    final ok = await const FeedbackService().sendFeedback(
      appVersion: '${info.version}+${info.buildNumber}',
      platformVersion:
          '${Platform.operatingSystem} '
          '${Platform.operatingSystemVersion}',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found to open.')),
      );
    }
  }
}

/// A last gate for an irreversible action: the user types the word to proceed.
/// Deliberate friction — a reset that can be triggered by a stray tap is a
/// reset that will eventually happen by accident.
class _TypeToConfirmDialog extends StatefulWidget {
  const _TypeToConfirmDialog({required this.word});
  final String word;

  @override
  State<_TypeToConfirmDialog> createState() => _TypeToConfirmDialogState();
}

class _TypeToConfirmDialogState extends State<_TypeToConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final ok = _controller.text.trim().toUpperCase() == widget.word;
      if (ok != _matches) setState(() => _matches = ok);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Last check'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type ${widget.word} to erase this device\'s data.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: widget.word,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: const Text('Erase'),
        ),
      ],
    );
  }
}

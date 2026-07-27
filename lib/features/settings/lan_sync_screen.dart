import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/platform.dart';
import '../../providers.dart';
import '../../services/lan_sync.dart';

/// §9 Sync over Wi-Fi. One device **shows a code**, the other **scans** it; a
/// single exchange merges both ways. No cloud, no account, no file to move —
/// just both devices on the same network for a moment. The host runs a local
/// server only while this screen is open.
class LanSyncScreen extends ConsumerStatefulWidget {
  const LanSyncScreen({super.key});

  @override
  ConsumerState<LanSyncScreen> createState() => _LanSyncScreenState();
}

enum _Mode { choose, host, scan }

class _LanSyncScreenState extends ConsumerState<LanSyncScreen> {
  _Mode _mode = _Mode.choose;

  LanSyncServer? _server;
  LanPairing? _pairing;
  String? _hostError;
  String? _hostStatus; // set when a peer completes a sync against us

  bool _scanBusy = false;
  bool _scanHandled = false;

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  Future<void> _startHost() async {
    setState(() {
      _mode = _Mode.host;
      _hostError = null;
      _hostStatus = null;
      _pairing = null;
    });
    final server = LanSyncServer(
      ref.read(ledgerSyncServiceProvider),
      ref.read(appSettingsProvider),
    );
    server.onSynced = (merged, peerName) {
      if (!mounted) return;
      _refreshAfterMerge();
      setState(() {
        _hostStatus = merged.isEmpty
            ? 'Synced with $peerName — already up to date'
            : 'Synced with $peerName — $merged';
      });
    };
    try {
      final pairing = await server.start();
      if (!mounted) {
        await server.stop();
        return;
      }
      setState(() {
        _server = server;
        _pairing = pairing;
      });
    } catch (e) {
      await server.stop();
      if (mounted) setState(() => _hostError = _friendly(e));
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanHandled) return;
    LanPairing? pairing;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null) continue;
      pairing = LanPairing.tryDecode(raw);
      if (pairing != null) break;
    }
    if (pairing == null) return; // not a Saara code — keep scanning
    _scanHandled = true;
    setState(() => _scanBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final client = LanSyncClient(
        ref.read(ledgerSyncServiceProvider),
        ref.read(appSettingsProvider),
      );
      final result = await client.syncWith(pairing);
      _refreshAfterMerge();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            result.merged.isEmpty
                ? 'Synced with ${result.peerName} — already up to date'
                : 'Synced with ${result.peerName} — ${result.merged}',
          ),
        ),
      );
      navigator.pop();
    } catch (e) {
      _scanHandled = false; // let them try again
      if (mounted) {
        setState(() => _scanBusy = false);
        messenger.showSnackBar(SnackBar(content: Text(_friendly(e))));
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
    ref.invalidate(ledgerSyncStatusProvider);
    ref.invalidate(unclassifiedTasksProvider);
    ref.invalidate(syncFreshnessProvider);
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('No Wi-Fi')) {
      return 'No Wi-Fi found. Connect both devices to the same Wi-Fi and try '
          'again.';
    }
    if (s.contains('refused') || s.contains('Connection')) {
      return 'Couldn\'t reach the other device. Check both are on the same '
          'Wi-Fi (some networks block device-to-device — a phone hotspot works '
          'well).';
    }
    return 'Sync failed: $s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync over Wi-Fi'),
        leading: _mode == _Mode.choose
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _server?.stop();
                  _server = null;
                  _scanHandled = false;
                  setState(() {
                    _mode = _Mode.choose;
                    _pairing = null;
                    _hostStatus = null;
                    _scanBusy = false;
                  });
                },
              ),
      ),
      body: switch (_mode) {
        _Mode.choose => _chooser(context),
        _Mode.host => _hostView(context),
        _Mode.scan => _scanView(context),
      },
    );
  }

  Widget _chooser(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Keep this device and your other one in step over the same Wi-Fi. '
          'One shows a code, the other scans it — that\'s the whole thing.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _bigAction(
          icon: Icons.qr_code_2,
          title: 'Show a code',
          subtitle: 'This device waits; scan it from the other one',
          onTap: _startHost,
        ),
        const SizedBox(height: 12),
        if (isDesktop)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Scanning needs a camera, so on the desktop use "Show a code" and '
              'scan it with your phone.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          _bigAction(
            icon: Icons.qr_code_scanner,
            title: 'Scan a code',
            subtitle: 'Point at the code shown on the other device',
            onTap: () => setState(() {
              _scanHandled = false;
              _scanBusy = false;
              _mode = _Mode.scan;
            }),
          ),
      ],
    );
  }

  Widget _bigAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 34, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hostView(BuildContext context) {
    final theme = Theme.of(context);
    if (_hostError != null) {
      return _centered(
        icon: Icons.wifi_off,
        title: 'Can\'t start',
        message: _hostError!,
        action: FilledButton(onPressed: _startHost, child: const Text('Retry')),
      );
    }
    if (_pairing == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              // A light quiet-zone card so the code scans in any theme.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _pairing!.encode(),
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'On your other device, open Saara → Settings → Sync between my '
                'devices → Sync over Wi-Fi → Scan a code, and point it here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This device: ${_pairing!.host}:${_pairing!.port}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_hostStatus != null) ...[
          const SizedBox(height: 24),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hostStatus!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _scanView(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(onDetect: _onDetect),
        // A simple viewfinder.
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white70, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        if (_scanBusy)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: Text(
            _scanBusy ? 'Syncing…' : 'Point at the code on your other device',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 6, color: Colors.black)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }
}

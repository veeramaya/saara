import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';
import '../../services/storage_service.dart';

/// §7.6 storage management — media is kept on-device, so make what it costs
/// visible and reclaimable rather than letting it grow silently.
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  StorageUsage? _usage;
  List<({dynamic capture, int bytes})> _largest = const [];
  String? _dir;
  int? _retentionDays;
  String? _archiveDir;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    final svc = ref.read(storageServiceProvider);
    final usage = await svc.measure();
    final largest = await svc.largest();
    final dir = await svc.mediaDir();
    final settings = ref.read(appSettingsProvider);
    final retention = await settings.mediaRetentionDays();
    final archive = await settings.archiveDir();
    if (!mounted) return;
    setState(() {
      _usage = usage;
      _largest = largest;
      _dir = dir.path;
      _retentionDays = retention;
      _archiveDir = archive;
      _busy = false;
    });
  }

  Future<void> _setArchiveDir(String? path) async {
    await ref.read(appSettingsProvider).setArchiveDir(path);
    if (mounted) setState(() => _archiveDir = path);
  }

  /// Any folder the user can reach — external drive, NAS, or a desktop-synced
  /// cloud folder. Deliberately a plain path: no cloud API, no OAuth scope, so
  /// this can never pull the app into a restricted-scope review.
  Future<void> _pickArchiveDir() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose a folder to archive media into',
    );
    if (path == null) return;
    await _setArchiveDir(path);
  }

  Future<void> _purge() async {
    final days = _retentionDays;
    if (days == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final archiving = _archiveDir != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(archiving ? 'Archive old media?' : 'Delete old media?'),
        content: Text(
          archiving
              ? 'Moves photos, video and audio from tasks completed more than '
                    '$days days ago to:\n\n$_archiveDir\n\nThe captures stay on '
                    'their tasks and still open while that drive is connected.'
              : 'Removes photos, video and audio from tasks completed more '
                    'than $days days ago.\n\nTasks, history, notes and text '
                    'captures are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(archiving ? 'Archive' : 'Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final freed = await ref
        .read(storageServiceProvider)
        .purgeCompletedMedia(days, archiveDir: _archiveDir);
    ref.invalidate(taskIdsWithCapturesProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Reclaimed ${formatBytes(freed)}')),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final u = _usage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _busy ? null : _load,
          ),
        ],
      ),
      body: _busy || u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  formatBytes(u.totalBytes),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'used by ${u.captureCount} capture'
                  '${u.captureCount == 1 ? '' : 's'} and attachments',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                _bar('Photos', u.imageBytes, u.totalBytes, Colors.blue),
                _bar('Video', u.videoBytes, u.totalBytes, Colors.deepPurple),
                _bar('Audio', u.audioBytes, u.totalBytes, Colors.teal),
                if (u.orphanBytes > 0)
                  _bar(
                    'Unused files',
                    u.orphanBytes,
                    u.totalBytes,
                    Colors.orange,
                  ),
                const Divider(height: 32),

                if (u.orphanCount > 0) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.cleaning_services_outlined),
                      title: Text(
                        '${u.orphanCount} unused file'
                        '${u.orphanCount == 1 ? '' : 's'} · '
                        '${formatBytes(u.orphanBytes)}',
                      ),
                      subtitle: const Text(
                        'Left behind by deleted tasks or captures. Nothing '
                        'in Saara points at them.',
                      ),
                      trailing: FilledButton(
                        onPressed: _cleanUp,
                        child: const Text('Clean up'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (u.missingCount > 0) ...[
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.link_off),
                      title: Text(
                        '${u.missingCount} capture'
                        '${u.missingCount == 1 ? '' : 's'} missing its file',
                      ),
                      subtitle: const Text(
                        'The file was removed outside Saara — the entry '
                        'remains but can no longer be opened.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Text(
                  'Keep media after a task is done',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Once a task is complete, the raw photo/video has usually '
                  'served its purpose — what matters is that you did it on '
                  'time. Deleting media never touches the task, its history, '
                  'notes or text captures.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _retentionDays,
                  decoration: const InputDecoration(
                    labelText: 'Delete media from completed tasks',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('Never (keep everything)'),
                    ),
                    DropdownMenuItem(value: 7, child: Text('After 7 days')),
                    DropdownMenuItem(value: 30, child: Text('After 30 days')),
                    DropdownMenuItem(value: 90, child: Text('After 90 days')),
                    DropdownMenuItem(value: 365, child: Text('After 1 year')),
                  ],
                  onChanged: (v) async {
                    setState(() => _retentionDays = v);
                    await ref
                        .read(appSettingsProvider)
                        .setMediaRetentionDays(v);
                  },
                ),
                if (_retentionDays != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.drive_file_move_outlined),
                      title: Text(
                        _archiveDir == null
                            ? 'Delete the files'
                            : 'Move them to an archive',
                      ),
                      subtitle: Text(
                        _archiveDir ??
                            'Pick a folder — an external drive, a NAS, or a '
                                'synced cloud folder — to keep the files '
                                'instead of deleting them.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          if (_archiveDir != null)
                            IconButton(
                              tooltip: 'Clear (delete instead)',
                              icon: const Icon(Icons.close),
                              onPressed: () => _setArchiveDir(null),
                            ),
                          IconButton(
                            tooltip: 'Choose folder',
                            icon: const Icon(Icons.folder_open),
                            onPressed: _pickArchiveDir,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _archiveDir == null
                            ? Icons.auto_delete_outlined
                            : Icons.drive_file_move_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _archiveDir == null
                            ? 'Delete now (older than $_retentionDays days)'
                            : 'Archive now (older than $_retentionDays days)',
                      ),
                      onPressed: _purge,
                    ),
                  ),
                ],
                const Divider(height: 32),

                Text(
                  'Largest captures',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_largest.isEmpty)
                  const Text('No media stored yet.')
                else
                  for (final row in _largest)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(_iconFor(row.capture.type.name)),
                      title: Text(
                        row.capture.caption?.toString().trim().isNotEmpty ==
                                true
                            ? row.capture.caption.toString()
                            : row.capture.type.name,
                      ),
                      subtitle: Text(
                        '${formatBytes(row.bytes)} · '
                        '${DateFormat('d MMM yyyy').format(row.capture.createdAt)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(row.capture, row.bytes),
                      ),
                    ),

                const Divider(height: 32),
                Text(
                  'Where it lives',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _dir ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Media is stored on this device only — never uploaded. It sits '
                  'beside the encrypted database, outside any cloud-synced '
                  'folder, so nothing leaves unless you export or share it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _bar(String label, int bytes, int total, Color color) {
    if (bytes == 0) return const SizedBox.shrink();
    final frac = total == 0 ? 0.0 : bytes / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label),
              const Spacer(),
              Text(
                formatBytes(bytes),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: frac,
            minHeight: 8,
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
    'video' => Icons.videocam,
    'audio' => Icons.mic,
    'image' => Icons.photo,
    _ => Icons.notes,
  };

  Future<void> _cleanUp() async {
    final messenger = ScaffoldMessenger.of(context);
    final freed = await ref.read(storageServiceProvider).deleteOrphans();
    messenger.showSnackBar(
      SnackBar(content: Text('Reclaimed ${formatBytes(freed)}')),
    );
    await _load();
  }

  Future<void> _delete(dynamic capture, int bytes) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete capture?'),
        content: Text(
          'Frees ${formatBytes(bytes)}. This removes the file and '
          'its entry on the task.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(storageServiceProvider).deleteCapture(capture);
    ref.invalidate(taskIdsWithCapturesProvider);
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted · ${formatBytes(bytes)} freed')),
    );
    await _load();
  }
}

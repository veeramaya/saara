import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../services/google/google_sync_service.dart';

/// §11 Google Drive file picker — search the user's Drive, pick a file, and
/// return its webViewLink to attach to a task. Read-only; Saara stores only the
/// link (opens in Google, governed by the user's own sharing).
class DrivePickerScreen extends ConsumerStatefulWidget {
  const DrivePickerScreen({super.key});

  @override
  ConsumerState<DrivePickerScreen> createState() => _DrivePickerScreenState();
}

class _DrivePickerScreenState extends ConsumerState<DrivePickerScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  bool _needsReconnect = false;
  String? _error;
  List<GDriveFile> _files = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
      _needsReconnect = false;
    });
    try {
      // Connectivity, not account-object presence — desktop has no account
      // object (loopback OAuth) yet is genuinely connected.
      if (!await ref.read(googleSyncServiceProvider).isConnected()) {
        setState(() {
          _loading = false;
          _error = 'Connect Google first (Settings → Google Tasks sync).';
        });
        return;
      }
      final files = await ref
          .read(googleSyncServiceProvider)
          .listDriveFiles(query: query);
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } on GoogleSyncException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _needsReconnect = true; // usually a missing Drive scope
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _reconnect() async {
    try {
      await ref.read(googleSyncServiceProvider).disconnect();
      await ref.read(googleSyncServiceProvider).connect();
      await _load(query: _search.text);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick from Drive')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search your Drive',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _load(query: _search.text),
                ),
              ),
              onSubmitted: (q) => _load(query: q),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _errorView()
                : _files.isEmpty
                ? const Center(child: Text('No files found.'))
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (_, i) {
                      final f = _files[i];
                      return ListTile(
                        leading: Icon(_iconFor(f.mimeType)),
                        title: Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(context).pop(f.link),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          if (_needsReconnect)
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reconnect Google (grant Drive)'),
              onPressed: _reconnect,
            ),
        ],
      ),
    ),
  );

  IconData _iconFor(String mime) {
    if (mime.contains('spreadsheet')) return Icons.table_chart_outlined;
    if (mime.contains('presentation')) return Icons.slideshow_outlined;
    if (mime.contains('document')) return Icons.description_outlined;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('image')) return Icons.image_outlined;
    if (mime.contains('folder')) return Icons.folder_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

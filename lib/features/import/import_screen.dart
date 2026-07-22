import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../services/import/file_import_service.dart';

/// Offline task migration from a plain Excel (.xlsx) or CSV file: pick file →
/// dry-run preview (counts per area, unmapped repeats, skipped rows) → commit.
/// Replaces the Todoist import path; no network involved.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _busy = false;
  String? _error;
  String? _fileName;
  ImportPreview? _preview;
  bool _createAreas = true;
  String? _assignAreaId; // "assign all to this area" (Todoist per-project CSV)

  FileImportService get _service => FileImportService(
    db: ref.read(appDatabaseProvider),
    idGenerator: ref.read(uuidProvider).v4,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import tasks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Import from a spreadsheet or a Markdown outline.\n\n'
            '• .xlsx / .csv — first row is headers. Columns: Title (required), '
            'Due, Notes, Area (a.k.a. Project), Priority, Repeat. Todoist exports '
            'a CSV per project — its Project column maps to your Areas.\n'
            '• .md / .txt — "# Project" headings become Areas; "- task" lines '
            'become tasks. On a task line: @2026-07-20 sets a due date, p1–p4 '
            'sets priority, and " // note" adds a note.\n\n'
            'Note: a file stored in Drive as a Google Sheet can\'t be read '
            'directly — in Sheets use File → Download → .csv first.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickAndParse,
            icon: const Icon(Icons.upload_file),
            label: Text(_fileName ?? 'Choose .xlsx, .csv, or .md file'),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_preview != null) ..._previewSection(_preview!),
        ],
      ),
    );
  }

  List<Widget> _previewSection(ImportPreview p) {
    final scheme = Theme.of(context).colorScheme;
    return [
      const Divider(height: 32),
      Text('Dry run', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Text('${p.importable} task(s) ready to import.'),
      for (final e in p.perAreaCounts.entries)
        ListTile(
          dense: true,
          leading: const Icon(Icons.folder_outlined),
          title: Text(e.key),
          trailing: Text('${e.value}'),
        ),
      if (p.unmappedRecurring.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          '${p.unmappedRecurring.length} row(s) had a repeat value we couldn\'t '
          'map — importing as non-recurring:',
          style: TextStyle(color: scheme.error),
        ),
        for (final r in p.unmappedRecurring)
          ListTile(
            dense: true,
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(r.title ?? 'Row ${r.rowNumber}'),
            subtitle: Text('repeat: ${r.repeatPhrase}'),
          ),
      ],
      if (p.skipped.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(
          '${p.skipped.length} row(s) skipped:',
          style: TextStyle(color: scheme.error),
        ),
        for (final r in p.skipped)
          ListTile(
            dense: true,
            leading: const Icon(Icons.block, size: 18),
            title: Text('Row ${r.rowNumber}'),
            subtitle: Text(r.error ?? 'invalid'),
          ),
      ],
      const SizedBox(height: 8),
      _AreaAssignDropdown(
        value: _assignAreaId,
        onChanged: _busy ? null : (v) => setState(() => _assignAreaId = v),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: _createAreas,
        onChanged: _busy ? null : (v) => setState(() => _createAreas = v),
        title: const Text('Create missing areas'),
        subtitle: const Text(
          'Add any project/heading that isn\'t already an Area (up to 10 '
          'total). Off = those tasks land in Unassigned.',
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: (_busy || p.importable == 0) ? null : () => _commit(p),
        child: Text('Import ${p.importable} task(s)'),
      ),
    ];
  }

  Future<void> _pickAndParse() async {
    setState(() {
      _error = null;
      _preview = null;
    });
    // FileType.any (not a custom extension filter): Google Drive shows
    // Sheets/Docs with no file extension, so a filter hides them entirely and
    // the picker looks broken. We accept anything, then explain what's wrong.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true, // load bytes (works without dart:io on all platforms)
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final name = file.name.toLowerCase();
    const supported = ['.csv', '.xlsx', '.md', '.markdown', '.txt'];
    const googleNativeHelp =
        'Google Sheets/Docs files aren\'t real files — they live in Google\'s '
        'format and can\'t be read directly.\n\nFix: open it in Google Sheets → '
        'File → Download → Comma-separated values (.csv), then import that '
        'downloaded file.';

    if (!supported.any(name.endsWith)) {
      setState(
        () => _error =
            'Can\'t import "${file.name}". Saara reads .csv, .xlsx, .md or '
            '.txt.\n\n$googleNativeHelp',
      );
      return;
    }
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      setState(
        () => _error = 'Could not read "${file.name}".\n\n$googleNativeHelp',
      );
      return;
    }

    setState(() {
      _busy = true;
      _fileName = file.name;
    });
    try {
      final preview = _service.parse(bytes, fileName: file.name);
      setState(() => _preview = preview);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _commit(ImportPreview p) async {
    setState(() => _busy = true);
    try {
      final inserted = await _service.commit(
        p.rows,
        createMissingAreas: _createAreas,
        assignAreaId: _assignAreaId,
      );
      if (!mounted) return;
      // New tasks/areas — refresh the lists that show them.
      ref.invalidate(activeAreasProvider);
      ref.invalidate(areaScoresProvider);
      ref.invalidate(allTasksProvider);
      ref.invalidate(unscheduledTasksProvider);
      final now = DateTime.now();
      ref.invalidate(
        tasksForDayProvider(DateTime(now.year, now.month, now.day)),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Imported $inserted task(s).')));
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Picks one Area to assign every imported row to (used when the file has no
/// project column — e.g. a Todoist per-project CSV). Rows that already carry a
/// matched area keep it; only unassigned rows fall back to this.
class _AreaAssignDropdown extends ConsumerWidget {
  const _AreaAssignDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(activeAreasProvider).valueOrNull ?? const [];
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Assign all to area (optional)',
        helperText: 'For a single-project file (e.g. one Todoist project)',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('— none —')),
        for (final a in areas)
          DropdownMenuItem(value: a.id, child: Text(a.displayName)),
      ],
      onChanged: onChanged,
    );
  }
}

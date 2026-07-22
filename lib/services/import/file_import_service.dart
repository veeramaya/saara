import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import 'recurrence_phrase_mapper.dart';

/// One parsed spreadsheet row mapped toward a Task. `error` is set (and the row
/// skipped) when a required field — the title — is missing.
class ImportRow {
  ImportRow({
    required this.rowNumber,
    this.title,
    this.due,
    this.notes,
    this.area,
    this.priority = 0,
    this.rrule,
    this.repeatPhrase,
    this.error,
  });

  final int rowNumber; // 1-based spreadsheet row, for user-facing messages
  final String? title;
  final DateTime? due;
  final String? notes;
  final String? area;
  final int priority;
  final String? rrule;
  final String? repeatPhrase;
  final String? error;

  bool get valid => error == null;
  bool get recurringUnmapped =>
      repeatPhrase != null && repeatPhrase!.isNotEmpty && rrule == null;
}

/// Dry-run preview shown before commit.
class ImportPreview {
  ImportPreview({
    required this.rows,
    required this.skipped,
    required this.perAreaCounts,
  });

  final List<ImportRow> rows; // importable (valid) rows
  final List<ImportRow> skipped; // rows with errors
  final Map<String, int> perAreaCounts; // area text (or "Unassigned") → count

  int get importable => rows.length;
  List<ImportRow> get unmappedRecurring =>
      rows.where((r) => r.recurringUnmapped).toList();
}

/// Offline task migration from a plain Excel (.xlsx) or CSV file. First sheet /
/// first row is headers. Recognized columns (case-insensitive, synonyms accepted):
///
/// | Column   | Synonyms                    | Notes                          |
/// |----------|-----------------------------|--------------------------------|
/// | Title    | task, name                  | **required**                   |
/// | Due      | due date, date, when        | ISO or common date formats     |
/// | Notes    | description, note           |                                |
/// | Area     | project, category, list     | matched to an existing Area    |
/// | Priority | prio, importance            | integer                        |
/// | Repeat   | recurring, recurrence       | phrase → RRULE (else flagged)  |
///
/// Deterministic and fully on-device — no network (§1.1, §18.5).
class FileImportService {
  FileImportService({
    required this.db,
    required String Function() idGenerator,
    this.mapper = const RecurrencePhraseMapper(),
  }) : _newId = idGenerator;

  final AppDatabase db;
  final RecurrencePhraseMapper mapper;
  final String Function() _newId;

  static const _headerSynonyms = <String, String>{
    // 'content' + 'item' cover Todoist's export (its task text column is CONTENT).
    'title': 'title', 'task': 'title', 'name': 'title',
    'content': 'title', 'item': 'title',
    'due': 'due', 'due date': 'due', 'date': 'due', 'when': 'due',
    'notes': 'notes', 'description': 'notes', 'note': 'notes',
    'area': 'area', 'project': 'area', 'category': 'area', 'list': 'area',
    'priority': 'priority', 'prio': 'priority', 'importance': 'priority',
    'repeat': 'repeat', 'recurring': 'repeat', 'recurrence': 'repeat',
    // Todoist row kind: rows that aren't tasks (section/note/separator) are
    // skipped so a section header doesn't become a task.
    'type': 'type',
  };

  /// Parses [bytes] into a preview, choosing the reader by [fileName]'s
  /// extension (`.csv` → CSV, otherwise Excel). Throws [FormatException] if the
  /// file is empty or has no recognizable `Title` column.
  ImportPreview parse(Uint8List bytes, {required String fileName}) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.md') ||
        lower.endsWith('.markdown') ||
        lower.endsWith('.txt')) {
      return parseMarkdown(utf8.decode(bytes, allowMalformed: true));
    }
    final grid = lower.endsWith('.csv')
        ? _gridFromCsv(bytes)
        : _gridFromExcel(bytes);
    return _buildPreview(grid);
  }

  /// Markdown / outline import (§18.5). A `#`/`##` heading sets the current
  /// **project → Area** (e.g. how Todoist projects read as an outline); each
  /// list item (`- task`, `* task`, `1. task`, `- [ ] task`) under it becomes a
  /// task in that area. Inline tokens on a task line:
  ///   • `@YYYY-MM-DD` → due date       • `p1`..`p4` → priority (p1 highest)
  ///   • ` // note` → everything after becomes the note
  ImportPreview parseMarkdown(String raw) {
    final lines = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');
    final item = RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+(?:\[[ xX]\]\s*)?(.+)$');
    final atDate = RegExp(r'@(\d{4}-\d{2}-\d{2})');
    final isoDate = RegExp(r'\b(\d{4}-\d{2}-\d{2})\b');
    final prio = RegExp(r'\bp([1-4])\b', caseSensitive: false);

    String? currentArea;
    final rows = <ImportRow>[];
    final skipped = <ImportRow>[];
    final perArea = <String, int>{};

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;

      final h = heading.firstMatch(line);
      if (h != null) {
        currentArea = h.group(1)!.trim();
        continue;
      }
      final m = item.firstMatch(line);
      if (m == null) continue; // ignore prose / blank structure

      var title = m.group(1)!.trim();

      // ' // note' → notes.
      String? notes;
      final ni = title.indexOf(' // ');
      if (ni >= 0) {
        notes = title.substring(ni + 4).trim();
        title = title.substring(0, ni).trim();
      }
      // Due date: @date first, else a bare ISO date.
      DateTime? due;
      final at = atDate.firstMatch(title);
      if (at != null) {
        due = DateTime.tryParse(at.group(1)!);
        title = title.replaceRange(at.start, at.end, '').trim();
      } else {
        final iso = isoDate.firstMatch(title);
        if (iso != null) {
          due = DateTime.tryParse(iso.group(1)!);
          title = title.replaceRange(iso.start, iso.end, '').trim();
        }
      }
      // Priority p1..p4 (Todoist: p1 is highest).
      var priority = 0;
      final pm = prio.firstMatch(title);
      if (pm != null) {
        priority = 5 - int.parse(pm.group(1)!);
        title = title.replaceRange(pm.start, pm.end, '').trim();
      }

      title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
      if (title.isEmpty) {
        skipped.add(
          ImportRow(rowNumber: i + 1, error: 'Empty task after parsing'),
        );
        continue;
      }

      rows.add(
        ImportRow(
          rowNumber: i + 1,
          title: title,
          due: due,
          notes: notes == null || notes.isEmpty ? null : notes,
          area: currentArea,
          priority: priority,
        ),
      );
      final key = currentArea?.isNotEmpty == true ? currentArea! : 'Unassigned';
      perArea[key] = (perArea[key] ?? 0) + 1;
    }

    if (rows.isEmpty) {
      throw const FormatException(
        'No tasks found. Use "# Project" headings and "- task" lines.',
      );
    }
    return ImportPreview(rows: rows, skipped: skipped, perAreaCounts: perArea);
  }

  /// Reads the first sheet into a grid of trimmed string cells (row 0 = header).
  List<List<String?>> _gridFromExcel(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw const FormatException('The workbook has no sheets.');
    }
    final sheet = excel.tables[excel.tables.keys.first]!;
    return [
      for (final row in sheet.rows) [for (final cell in row) _text(cell)],
    ];
  }

  /// Parses CSV bytes (UTF-8, any line ending) into a grid of string cells.
  List<List<String?>> _gridFromCsv(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false, // keep everything as strings; we parse later
      eol: '\n',
    ).convert(normalized);
    return [
      for (final row in rows)
        [
          for (final cell in row)
            (cell == null || cell.toString().trim().isEmpty)
                ? null
                : cell.toString().trim(),
        ],
    ];
  }

  /// Shared row-mapping over a header+rows grid (format-agnostic).
  ImportPreview _buildPreview(List<List<String?>> grid) {
    if (grid.isEmpty) {
      throw const FormatException('The file is empty.');
    }

    // Header → canonical field, keyed by column index.
    final header = grid.first;
    final colField = <int, String>{};
    for (var c = 0; c < header.length; c++) {
      final name = header[c]?.toLowerCase().trim();
      final field = name == null ? null : _headerSynonyms[name];
      if (field != null) colField[c] = field;
    }
    if (!colField.values.contains('title')) {
      throw const FormatException(
        'No "Title" (or Task/Name) column found in the header row.',
      );
    }

    final rows = <ImportRow>[];
    final skipped = <ImportRow>[];
    final perArea = <String, int>{};

    for (var r = 1; r < grid.length; r++) {
      final cells = grid[r];
      final values = <String, String?>{};
      colField.forEach((index, field) {
        values[field] = index < cells.length ? cells[index] : null;
      });

      // Skip fully-blank rows silently.
      if (values.values.every((v) => v == null || v.isEmpty)) continue;

      // Todoist rows carry a TYPE; only real tasks import (skip section/note).
      final type = values['type']?.toLowerCase().trim();
      if (type != null && type.isNotEmpty && type != 'task') continue;

      final title = values['title'];
      if (title == null || title.trim().isEmpty) {
        skipped.add(ImportRow(rowNumber: r + 1, error: 'Missing title'));
        continue;
      }

      final repeatPhrase = values['repeat'];
      final row = ImportRow(
        rowNumber: r + 1,
        title: title.trim(),
        due: _parseDate(values['due']),
        notes: values['notes'],
        area: values['area']?.trim(),
        priority: int.tryParse(values['priority']?.trim() ?? '') ?? 0,
        repeatPhrase: repeatPhrase,
        rrule: mapper.toRrule(repeatPhrase),
      );
      rows.add(row);
      final areaKey = row.area?.isNotEmpty == true ? row.area! : 'Unassigned';
      perArea[areaKey] = (perArea[areaKey] ?? 0) + 1;
    }

    return ImportPreview(rows: rows, skipped: skipped, perAreaCounts: perArea);
  }

  /// Distinct project/area names in [rows] that don't match an existing Area —
  /// the ones "Create missing areas" would add (order preserved).
  Future<List<String>> unmatchedAreas(List<ImportRow> rows) async {
    final areaByName = await _areaLookup();
    final seen = <String>{};
    final out = <String>[];
    for (final r in rows) {
      final a = r.area?.trim();
      if (a == null || a.isEmpty) continue;
      final key = a.toLowerCase();
      if (areaByName.containsKey(key) || seen.contains(key)) continue;
      seen.add(key);
      out.add(a);
    }
    return out;
  }

  /// Inserts the valid [rows], resolving each row's area text to an existing
  /// Area id (matched on display name or base category, case-insensitive).
  /// When [createMissingAreas] is set, unmatched project names become new
  /// custom Areas — up to the app's 10-area cap; the rest stay Unassigned.
  /// Returns the number of tasks inserted.
  Future<int> commit(
    List<ImportRow> rows, {
    bool createMissingAreas = false,
    String? assignAreaId,
  }) async {
    final areaByName = await _areaLookup();
    final now = DateTime.now();
    var inserted = 0;

    if (createMissingAreas) {
      final active = (await db.select(db.areas).get())
          .where((a) => !a.archived)
          .length;
      var slots = 10 - active; // §areas: keep it focused — max 10
      for (final name in await unmatchedAreas(rows)) {
        if (slots <= 0) break;
        final id = _newId();
        await db
            .into(db.areas)
            .insert(
              AreasCompanion.insert(
                id: id,
                baseCategory: BaseCategory.custom,
                displayName: name,
                createdAt: now,
                updatedAt: now,
              ),
            );
        areaByName[name.toLowerCase()] = id;
        slots--;
      }
    }

    await db.batch((batch) {
      for (final row in rows) {
        if (!row.valid) continue;
        // Row's own area if matched, else the whole-file area the user picked.
        final areaId =
            (row.area == null ? null : areaByName[row.area!.toLowerCase()]) ??
            assignAreaId;
        batch.insert(
          db.tasks,
          TasksCompanion.insert(
            id: _newId(),
            title: row.title!,
            notes: Value(row.notes),
            areaId: Value(areaId),
            status: const Value(TaskStatus.created),
            scheduledStart: Value(row.due),
            dueDate: Value(row.due),
            rrule: Value(row.rrule),
            priority: Value(row.priority),
            source: const Value(TaskSource.fileImport),
            createdAt: now,
            updatedAt: now,
          ),
        );
        inserted++;
      }
    });
    return inserted;
  }

  Future<Map<String, String>> _areaLookup() async {
    final areas = await db.select(db.areas).get();
    final map = <String, String>{};
    for (final a in areas) {
      map[a.displayName.toLowerCase()] = a.id;
      map[a.baseCategory.name.toLowerCase()] = a.id;
    }
    return map;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim();
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    for (final fmt in const [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'd MMM yyyy',
      'MMM d, yyyy',
    ]) {
      try {
        return DateFormat(fmt).parseStrict(s);
      } catch (_) {
        // try next format
      }
    }
    return null;
  }

  /// Extracts a trimmed string from an Excel cell across the common v4
  /// [CellValue] types; null for empty cells.
  String? _text(Data? cell) {
    final v = cell?.value;
    switch (v) {
      case null:
        return null;
      case TextCellValue():
        final s = v.value.toString().trim();
        return s.isEmpty ? null : s;
      case IntCellValue():
        return v.value.toString();
      case DoubleCellValue():
        return v.value.toString();
      case BoolCellValue():
        return v.value.toString();
      case DateCellValue():
        return v.asDateTimeLocal().toIso8601String();
      case DateTimeCellValue():
        return v.asDateTimeLocal().toIso8601String();
      default:
        final s = v.toString().trim();
        return s.isEmpty ? null : s;
    }
  }
}

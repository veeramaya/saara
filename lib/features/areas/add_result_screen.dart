import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// Create **or edit** a measurable result for an area (§3.2).
///
/// Editing keeps the deadline honest: a new "N days" runs from the day you
/// change it, but the original date is preserved and every move is counted —
/// see [AreaDao.updateResult].
class AddResultScreen extends ConsumerStatefulWidget {
  const AddResultScreen({super.key, required this.areaId, this.editing});
  final String areaId;

  /// When set, the form edits this result instead of creating one.
  final MeasurableResult? editing;

  @override
  ConsumerState<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends ConsumerState<AddResultScreen> {
  final _title = TextEditingController();
  final _target = TextEditingController(text: '1');
  final _unit = TextEditingController();

  /// A nudge toward the *kind* of unit the chosen metric implies — never
  /// enforced, since Saara measures commitment, not physics.
  String get _unitHint => switch (_metric) {
    MetricType.currency => '₹ / \$',
    MetricType.durationMin => 'minutes',
    MetricType.numeric => 'inches, kg…',
    MetricType.count => 'sessions, reps…',
    MetricType.healthSteps => 'steps',
    MetricType.healthSleepHr => 'hours',
    MetricType.healthWeight => 'kg',
    _ => 'unit',
  };
  MetricType _metric = MetricType.count;
  Comparator _comparator = Comparator.gte;
  Cadence _cadence = Cadence.daily;

  /// Optional deadline (§3.2 `end_date`) — the milestone dimension.
  DateTime? _endDate;

  int? get _daysFromNow =>
      _endDate == null ? null : _endDate!.difference(DateTime.now()).inDays + 1;

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Achieve this by',
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  // Manual-loggable metrics. Health Connect auto-sourcing (steps/sleep/weight)
  // was removed before launch — Saara isn't a health app — so those types are
  // no longer offered for new results. An existing health result stays editable
  // (see the dropdown below). Re-add the health* types here if it returns.
  static const _metrics = [
    MetricType.count,
    MetricType.durationMin,
    MetricType.numeric,
    MetricType.currency,
    MetricType.boolean,
  ];

  static const _healthMetrics = {
    MetricType.healthSteps,
    MetricType.healthSleepHr,
    MetricType.healthWeight,
  };

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e == null) return;
    _title.text = e.title;
    _target.text = (e.targetValue ?? 1).toString();
    _unit.text = e.unit ?? '';
    _metric = e.metricType;
    _comparator = e.comparator;
    _cadence = e.cadence;
    _endDate = e.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _unit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit result' : 'New measurable result'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive this result',
              onPressed: _archive,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // §3.2 a moved deadline is shown, not hidden — the point of keeping
          // the original date at all.
          if (_isEdit && widget.editing!.deadlineMoves > 0) ...[
            Card(
              color: Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  'Deadline moved '
                  '${widget.editing!.deadlineMoves}×',
                ),
                subtitle: widget.editing!.originalEndDate == null
                    ? null
                    : Text(
                        'Originally due '
                        '${DateFormat('d MMM yyyy').format(widget.editing!.originalEndDate!)}',
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Walk 8,000 steps',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MetricType>(
            initialValue: _metric,
            decoration: const InputDecoration(labelText: 'Metric'),
            items: [
              for (final m in _metrics)
                DropdownMenuItem(value: m, child: Text(_metricLabel(m))),
              // Keep a pre-existing health-source result selectable when editing,
              // even though new ones can't be created any more.
              if (_isEdit && _healthMetrics.contains(_metric))
                DropdownMenuItem(
                  value: _metric,
                  child: Text(_metricLabel(_metric)),
                ),
            ],
            onChanged: (v) => setState(() {
              _metric = v!;
              if (_metric == MetricType.boolean) _target.text = '1';
            }),
          ),
          const SizedBox(height: 16),
          if (_metric != MetricType.boolean)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target value',
                      hintText: 'e.g. 8000',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  // Free text, never validated — it exists so you and your
                  // committed listener read the same meaning from the number.
                  child: TextField(
                    controller: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      hintText: _unitHint,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Comparator>(
            initialValue: _comparator,
            decoration: const InputDecoration(labelText: 'Meet the target by'),
            items: const [
              DropdownMenuItem(
                value: Comparator.gte,
                child: Text('At least (≥)'),
              ),
              DropdownMenuItem(
                value: Comparator.lte,
                child: Text('At most (≤)'),
              ),
              DropdownMenuItem(
                value: Comparator.eq,
                child: Text('Exactly (=)'),
              ),
            ],
            onChanged: (v) => setState(() => _comparator = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Cadence>(
            initialValue: _cadence,
            decoration: const InputDecoration(labelText: 'Cadence'),
            items: const [
              DropdownMenuItem(value: Cadence.daily, child: Text('Daily')),
              DropdownMenuItem(value: Cadence.weekly, child: Text('Weekly')),
              DropdownMenuItem(value: Cadence.monthly, child: Text('Monthly')),
            ],
            onChanged: (v) => setState(() => _cadence = v!),
          ),
          const SizedBox(height: 16),
          // §3.2 an optional deadline turns a running habit into a milestone
          // you either hit or don't — "32 inches by 30 September", not "32
          // inches, forever". The timeline is the index (endDate already
          // existed in the schema; it just had no way in).
          Text('Achieve by', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final days in const [30, 60, 90, 180])
                ChoiceChip(
                  label: Text('$days days'),
                  selected: _endDate != null && _daysFromNow == days,
                  onSelected: (_) => setState(
                    () => _endDate = DateTime.now().add(Duration(days: days)),
                  ),
                ),
              OutlinedButton.icon(
                icon: const Icon(Icons.event, size: 16),
                label: Text(
                  _endDate == null
                      ? 'Pick a date'
                      : DateFormat('d MMM yyyy').format(_endDate!),
                ),
                onPressed: _pickEndDate,
              ),
              if (_endDate != null)
                IconButton(
                  tooltip: 'No deadline (ongoing)',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _endDate = null),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _endDate == null
                ? 'Ongoing — measured every ${_cadence.name} with no end date.'
                : 'Due ${DateFormat('EEE, d MMM yyyy').format(_endDate!)} — '
                      '${_daysFromNow ?? 0} days from today.\n'
                      'If you change this later, the new count runs from that '
                      'day, and Saara keeps the original date and counts the '
                      'move — so a slipping deadline stays visible.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: _save,
          child: Text(_isEdit ? 'Save changes' : 'Save'),
        ),
      ),
    );
  }

  String _metricLabel(MetricType m) => switch (m) {
    MetricType.count => 'Count',
    MetricType.durationMin => 'Duration (minutes)',
    MetricType.numeric => 'Number',
    MetricType.currency => 'Money (₹)',
    MetricType.boolean => 'Yes / No',
    MetricType.healthSteps => 'Steps (Health Connect)',
    MetricType.healthSleepHr => 'Sleep hours (Health Connect)',
    MetricType.healthWeight => 'Weight (Health Connect)',
    _ => m.name,
  };

  /// §3.2 an area measures at most this many results at once. More than a
  /// handful and the area's score stops meaning anything — finish one, then
  /// start the next.
  static const _maxResultsPerArea = 6;

  /// Stop measuring this result without destroying its history — the logs and
  /// past scores stay, it just leaves the active set (and frees one of the six).
  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive this result?'),
        content: const Text(
          'It stops counting toward the area score and frees a slot. Its '
          'logged history is kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(areaDaoProvider).archiveResult(widget.editing!.id);
    ref.invalidate(areaResultsProvider(widget.areaId));
    ref.invalidate(areaScoresProvider);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    // --- edit path: update in place, with deadline accounting in the DAO ---
    if (_isEdit) {
      final target = _metric == MetricType.boolean
          ? 1.0
          : double.tryParse(_target.text.trim()) ?? 1.0;
      await ref
          .read(areaDaoProvider)
          .updateResult(
            widget.editing!,
            title: title,
            targetValue: target,
            unit: _unit.text.trim(),
            cadence: _cadence,
            comparator: _comparator,
            endDate: _endDate,
            clearEndDate: _endDate == null,
          );
      ref.invalidate(areaResultsProvider(widget.areaId));
      ref.invalidate(areaScoresProvider);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final existing = await ref
        .read(areaDaoProvider)
        .resultsForArea(widget.areaId);
    if (existing.length >= _maxResultsPerArea) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'An area tracks up to $_maxResultsPerArea results. '
            'Complete or remove one first — keeping it few keeps the score '
            'meaningful.',
          ),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final target = _metric == MetricType.boolean
        ? 1.0
        : double.tryParse(_target.text.trim()) ?? 1.0;

    await ref
        .read(areaDaoProvider)
        .createResult(
          MeasurableResultsCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            areaId: widget.areaId,
            title: title,
            metricType: _metric,
            targetValue: Value(target),
            unit: Value(_unit.text.trim().isEmpty ? null : _unit.text.trim()),
            comparator: _comparator,
            cadence: _cadence,
            verification: _healthMetrics.contains(_metric)
                ? Verification.healthSource
                : Verification.manualLog,
            startDate: now,
            endDate: Value(_endDate),
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.invalidate(areaResultsProvider(widget.areaId));
    ref.invalidate(areaScoresProvider);
    if (mounted) Navigator.of(context).pop();
  }
}

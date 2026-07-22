import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.dart';
import '../../core/platform.dart';
import '../../core/time_context.dart';
import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/parser/parsed_task.dart';
import '../../providers.dart';
import '../../services/contacts_service.dart';
import '../../services/geofence_service.dart';
import '../../services/google/google_config.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../areas/add_area_screen.dart';
import '../../services/ocr_service.dart';
import '../contacts/contact_picker_screen.dart';
import '../google/drive_picker_screen.dart';

/// §7.2 Task card (create/confirm). A single card, pre-filled by the
/// deterministic parser (§5). Fields below the confidence threshold are
/// highlighted; the task is never saved silently from a low-confidence parse.
///
/// [initialInput] lets share-target text (§11) or voice transcripts (§19) drop
/// straight into the same card.
class TaskCardScreen extends ConsumerStatefulWidget {
  const TaskCardScreen({
    super.key,
    this.initialInput,
    this.initialKind,
    this.imagePath,
    this.autoExtract = false,
    this.editing,
    this.startWithMeet = false,
  });

  /// Opens the card as a Google Meet event: kind = event, Meet link armed, so
  /// "New Google Meet event" lands the user one step from Save (§9).
  final bool startWithMeet;

  /// When set, the card edits this existing task (fields prefilled; Save writes
  /// an update that then syncs to Google) instead of creating a new one.
  final Task? editing;

  final String? initialInput;

  /// Preselects Task vs Event (e.g. from an OCR "create event" choice).
  final TaskKind? initialKind;

  /// The original captured image — kept with the task so the extraction can be
  /// checked against the source (§7.6).
  final String? imagePath;

  /// Run "Extract with AI" automatically on open (from a camera/screenshot
  /// capture). Falls back silently to the attached image if no key is set.
  final bool autoExtract;

  @override
  ConsumerState<TaskCardScreen> createState() => _TaskCardScreenState();
}

class _TaskCardScreenState extends ConsumerState<TaskCardScreen> {
  final _inputController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _docLinkController = TextEditingController();
  String? _pickedImagePath; // phone image attached in-card (vs OCR image)

  /// Manual repeat presets (§4/§6 RRULE). Parser-detected repeats also land in
  /// [_rrule] and highlight the matching chip.
  static const _repeatOptions = <String, String?>{
    'Once': null,
    'Daily': 'FREQ=DAILY',
    'Mon–Fri': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR',
    'Mon–Sat': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA',
    'Weekly': 'FREQ=WEEKLY',
    'Monthly': 'FREQ=MONTHLY',
  };

  // RRULE day codes in week order, with single-letter labels for the picker.
  static const _dayCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// The BYDAY set currently encoded in [_rrule], if any.
  Set<String> get _selectedDays {
    final r = _rrule;
    if (r == null || !r.contains('BYDAY=')) return const {};
    return r
        .split('BYDAY=')
        .last
        .split(';')
        .first
        .split(',')
        .where((d) => d.isNotEmpty)
        .toSet();
  }

  static String _dayName(String code) =>
      const {
        'MO': 'Mon',
        'TU': 'Tue',
        'WE': 'Wed',
        'TH': 'Thu',
        'FR': 'Fri',
        'SA': 'Sat',
        'SU': 'Sun',
      }[code] ??
      code;

  /// Toggle one weekday, rebuilding the rule. Any combination works — "till
  /// Saturday every week" is Mon–Sat, but so is Tue/Thu or weekends only.
  void _toggleDay(String code) {
    final days = {..._selectedDays};
    if (!days.remove(code)) days.add(code);
    setState(() {
      _rrule = days.isEmpty
          ? null
          : 'FREQ=WEEKLY;BYDAY=${_dayCodes.where(days.contains).join(',')}';
    });
  }

  ParsedTaskDraft? _draft;
  TaskKind _kind = TaskKind.task;
  DateTime? _scheduledStart;
  int? _durationMin;
  String? _rrule;
  String? _areaId; // selected Area (FK), mapped from the parser's guess
  final List<SimpleContact> _participants = [];
  final _locationController = TextEditingController();
  final _meetingLinkController =
      TextEditingController(); // Zoom/Teams/Meet join
  bool _reminderEnabled = false;
  bool _generateMeet = false; // ask Google to mint a Meet link on next sync
  bool _aiBusy = false;
  String? _conflictWarning; // set when an event overlaps existing items
  bool _geofence = false; // notify on arrival at the location
  double? _lat;
  double? _lng;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _listening = false;

  /// The image shown/saved: the OCR capture, else one attached from the phone.
  String? get _effectiveImage => widget.imagePath ?? _pickedImagePath;

  /// Already committed to, so there is nothing left to release — the button
  /// goes back to plain "Save". A commitment is never silently un-given: to
  /// step back from one you dispose of it (§4), you don't demote it to a draft.
  bool get _alreadyReleased =>
      widget.editing?.publicationState == PublicationState.released;

  @override
  void initState() {
    super.initState();
    _kind =
        widget.initialKind ??
        (widget.startWithMeet ? TaskKind.event : TaskKind.task);
    if (widget.editing != null) {
      _prefillFromTask(widget.editing!);
    }
    if (widget.startWithMeet) _generateMeet = true;
    final input = widget.initialInput;
    if (widget.imagePath != null) {
      _prefillFromCapture(input ?? '');
    } else if (input != null && input.isNotEmpty) {
      _inputController.text = input;
      _reparse();
    }
    // Auto-read the captured image with AI (if a key is set), so capture "just
    // works". The image stays shown for verification.
    if (widget.autoExtract && widget.imagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _extractWithAi(silentIfNoKey: true),
      );
    }
    // Typing a link hides the "Generate Meet" affordance (and clears the flag);
    // rebuild so the two can't be armed at once.
    _meetingLinkController.addListener(_onMeetingLinkChanged);
  }

  void _onMeetingLinkChanged() {
    final hasLink = _meetingLinkController.text.trim().isNotEmpty;
    if (hasLink && _generateMeet) _generateMeet = false;
    setState(() {});
  }

  /// Edit mode: prefill every field from the existing task.
  void _prefillFromTask(Task t) {
    _kind = t.kind ?? TaskKind.task;
    _titleController.text = t.title;
    _notesController.text = t.notes ?? '';
    _scheduledStart = t.scheduledStart;
    _durationMin = t.durationMin;
    _rrule = t.rrule;
    _areaId = t.areaId;
    _locationController.text = t.locationName ?? '';
    _meetingLinkController.text = t.meetingLink ?? '';
    _docLinkController.text = t.documentLink ?? '';
    _pickedImagePath = t.attachmentImagePath;
    _reminderEnabled =
        t.reminderOffsets != null && t.reminderOffsets!.isNotEmpty;
    // Already asked for a Meet link but not yet minted — show the pending state.
    _generateMeet =
        t.meetingProvider == MeetingProvider.meet &&
        (t.meetingLink ?? '').isEmpty;
    _geofence = t.geofenceEnabled;
    _lat = t.lat;
    _lng = t.lng;
  }

  /// OCR mode: keep the full text (editable) in Notes, guess the Title from the
  /// first line, and pull any date/repeat the parser finds — everything stays
  /// editable so the user formats it into fields and can verify against the
  /// attached image (§7.6).
  void _prefillFromCapture(String text) {
    _inputController.text = text;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final title = lines.isEmpty ? 'Captured note' : lines.first;
    final draft = ref.read(parserProvider).parse(text);
    setState(() {
      _draft = draft;
      _titleController.text = title.length > 80
          ? title.substring(0, 80)
          : title;
      _notesController.text = text;
      _scheduledStart = draft.scheduledStart;
      _durationMin = draft.durationMin;
      _rrule = draft.rrule;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _docLinkController.dispose();
    _locationController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  void _reparse() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;
    final draft = ref.read(parserProvider).parse(input);
    // Map the parser's base-category guess to the first matching Area (§5.5).
    final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
    final match = draft.areaGuess == null
        ? null
        : areas.firstWhereOrNull((a) => a.baseCategory == draft.areaGuess);
    setState(() {
      _draft = draft;
      _titleController.text = draft.title;
      _scheduledStart = draft.scheduledStart;
      _durationMin = draft.durationMin;
      _rrule = draft.rrule;
      _areaId = match?.id;
      _reminderEnabled = draft.meetingLink != null; // §8 suggest for meetings
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final uncertain = draft?.uncertainFields ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing != null ? 'Edit task' : 'New task'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_effectiveImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _viewImage(_effectiveImage!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_effectiveImage!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Raw entry — type or talk (voice hooks into this in §19).
                  TextField(
                    controller: _inputController,
                    maxLines: null,
                    decoration: InputDecoration(
                      labelText: 'Type, paste, or talk a task',
                      hintText: 'e.g. paste a WhatsApp message, then tap AI',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _listening ? Icons.mic : Icons.mic_none,
                          color: _listening
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        tooltip: _listening ? 'Stop' : 'Dictate',
                        onPressed: _toggleListen,
                      ),
                    ),
                    textInputAction: TextInputAction.newline,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: _reparse,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Parse'),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message:
                            'Reads the text you typed or pasted above '
                            'into the fields below',
                        child: FilledButton.tonalIcon(
                          onPressed: _aiBusy ? null : _structureFromText,
                          icon: _aiBusy
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          // Distinct from "AI from image" below — these read
                          // different sources and were both just called "AI".
                          label: const Text('AI from text'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  SegmentedButton<TaskKind>(
                    segments: const [
                      ButtonSegment(
                        value: TaskKind.task,
                        label: Text('Task'),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                      ButtonSegment(
                        value: TaskKind.event,
                        label: Text('Event'),
                        icon: Icon(Icons.event),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _kind == TaskKind.event
                        ? 'Syncs to your Google Calendar. Needs a date & time.'
                        : 'A to-do — syncs with Google Tasks.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  _FieldLabel('Title', uncertain.contains('title')),
                  TextField(controller: _titleController),
                  const SizedBox(height: 12),

                  _FieldLabel('When', uncertain.contains('scheduledStart')),
                  _PickerRow(
                    text: _scheduledStart == null
                        ? 'No date/time'
                        : DateFormat(
                            'EEE, MMM d · h:mm a',
                          ).format(_scheduledStart!),
                    onTap: _pickDateTime,
                  ),
                  if (_conflictWarning != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_busy, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _conflictWarning!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  _FieldLabel('Duration', uncertain.contains('durationMin')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final m in const [15, 30, 45, 60, 90, 120])
                        ChoiceChip(
                          label: Text(_durationLabel(m)),
                          selected: _durationMin == m,
                          onSelected: (_) => setState(
                            () => _durationMin = _durationMin == m ? null : m,
                          ),
                        ),
                      // Explicit end time — the natural way to say "6 to 11 PM".
                      // Sets duration from start→end, so both stay consistent.
                      OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(_endsLabel()),
                        onPressed: _pickEnd,
                      ),
                      if (_durationMin != null)
                        IconButton(
                          tooltip: 'Clear duration',
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _durationMin = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _FieldLabel('Location', false),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      hintText: 'Venue / address (optional)',
                      isDense: true,
                    ),
                  ),
                  if (kGeofenceEnabled)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text('Notify me when I arrive'),
                      subtitle: Text(
                        _geofence && _lat != null
                            ? 'Geofence set at this place'
                            : 'Reminds you at the location (needs "allow all the time")',
                      ),
                      value: _geofence,
                      onChanged: _toggleGeofence,
                    ),
                  const SizedBox(height: 12),

                  _FieldLabel('Meeting / join link', false),
                  TextField(
                    controller: _meetingLinkController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Zoom / Teams / Google Meet link',
                      prefixIcon: const Icon(Icons.videocam_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open',
                        onPressed: () {
                          final url = _meetingLinkController.text.trim();
                          if (url.isNotEmpty) {
                            launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  // §9 One-tap Google Meet — no extra scope, Google Calendar
                  // mints the link on the next push. Only when it can actually
                  // work: an event, connected to Google, no link typed yet.
                  if (_kind == TaskKind.event &&
                      _meetingLinkController.text.trim().isEmpty &&
                      (ref.watch(googleConnectedProvider).valueOrNull ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _generateMeet
                          ? Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'A Google Meet link will be added when this '
                                    'event syncs.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _generateMeet = false),
                                  child: const Text('Undo'),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.videocam_outlined,
                                  size: 18,
                                ),
                                label: const Text('Generate Google Meet link'),
                                onPressed: () =>
                                    setState(() => _generateMeet = true),
                              ),
                            ),
                    ),
                  const SizedBox(height: 12),

                  _FieldLabel('Repeat', uncertain.contains('rrule')),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final opt in _repeatOptions.entries)
                        ChoiceChip(
                          label: Text(opt.key),
                          selected: _rrule == opt.value,
                          onSelected: (_) => setState(() => _rrule = opt.value),
                        ),
                    ],
                  ),
                  // Pick exact days for any pattern the presets don't cover.
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Repeat on',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 10),
                      for (var i = 0; i < _dayCodes.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _DayToggle(
                            label: _dayLabels[i],
                            selected: _selectedDays.contains(_dayCodes[i]),
                            onTap: () => _toggleDay(_dayCodes[i]),
                          ),
                        ),
                    ],
                  ),
                  if (_selectedDays.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Repeats every week on '
                        '${_dayCodes.where(_selectedDays.contains).map((d) => _dayName(d)).join(', ')}.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),

                  _FieldLabel('Area', uncertain.contains('area')),
                  _AreaChips(
                    selectedId: _areaId,
                    onSelected: (id) => setState(() => _areaId = id),
                  ),
                  const SizedBox(height: 12),

                  _FieldLabel('Participants', false),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final c in _participants)
                        InputChip(
                          avatar: CircleAvatar(
                            child: Text(
                              c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                            ),
                          ),
                          label: Text(c.name),
                          onDeleted: () =>
                              setState(() => _participants.remove(c)),
                        ),
                      // Device contacts are mobile-only (flutter_contacts has
                      // no desktop implementation), so desktop types a name
                      // instead of showing a button that can't work.
                      ActionChip(
                        avatar: const Icon(Icons.person_add_alt, size: 18),
                        label: Text(supportsContacts ? 'Add' : 'Add name'),
                        onPressed: supportsContacts
                            ? _pickParticipant
                            : _addParticipantByName,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Per-task reminder'),
                    subtitle: const Text('Notify me 15 min before it starts'),
                    value: _reminderEnabled,
                    onChanged: (v) => setState(() => _reminderEnabled = v),
                  ),

                  _FieldLabel('Notes', false),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Anything else',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _FieldLabel('Attachments & links', false),
                  TextField(
                    controller: _docLinkController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Document link or file',
                      hintText: 'Paste a link, or choose a file',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open',
                        onPressed: _openDocLink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Choose file'),
                      onPressed: _chooseFile,
                    ),
                  ),
                  // §9 hidden while the restricted drive.readonly scope is off
                  // (kDrivePickerEnabled) — pasting a Drive link above works
                  // and needs no scope.
                  if (kDrivePickerEnabled)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_to_drive, size: 18),
                        label: const Text('Pick from Google Drive'),
                        onPressed: _pickFromDrive,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          _effectiveImage == null
                              ? (supportsCamera
                                    ? 'Attach image from phone'
                                    : 'Attach image')
                              : 'Replace image',
                        ),
                        onPressed: _attachImage,
                      ),
                      if (_effectiveImage != null)
                        FilledButton.tonalIcon(
                          icon: _aiBusy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome, size: 18),
                          label: const Text('AI from image'),
                          onPressed: _aiBusy ? null : _extractWithAi,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (draft != null && draft.needsReview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Some fields look uncertain — please review before saving.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      // §4.1c Releasing is giving your word, so the button says so. It is the
      // same single tap Save was — the act is just named honestly. "Save as
      // draft" sits beneath for thinking that isn't a commitment yet.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => _save(release: true),
              child: Text(_alreadyReleased ? 'Save' : 'Release'),
            ),
            if (!_alreadyReleased)
              TextButton(
                onPressed: () => _save(release: false),
                child: const Text('Save as draft'),
              ),
          ],
        ),
      ),
    );
  }

  /// §19 voice capture — dictate into the input, then Parse or tap AI. Toggles
  /// listening; the recognized words stream into the field live.
  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok) {
      _snack('Speech recognition unavailable on this device.');
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (mounted) {
          setState(() => _inputController.text = r.recognizedWords);
        }
      },
    );
  }

  Future<void> _attachImage() async {
    final path = await const OcrService().pickImage(ImageSource.gallery);
    if (path != null && mounted) setState(() => _pickedImagePath = path);
  }

  /// §8 enable an arrival geofence: resolve the place to coordinates (geocode
  /// the typed location, else current position) and request background location.
  Future<void> _toggleGeofence(bool on) async {
    if (!on) {
      setState(() => _geofence = false);
      return;
    }
    const svc = LocationService();
    ({double lat, double lng})? coords;
    final place = _locationController.text.trim();
    if (place.isNotEmpty) coords = await svc.geocode(place);
    coords ??= await svc.currentLatLng();
    if (coords == null) {
      _snack('Couldn\'t find the location — type a place, or allow location.');
      return;
    }
    final bg = await svc.ensureBackground();
    if (mounted) {
      setState(() {
        _geofence = true;
        _lat = coords!.lat;
        _lng = coords.lng;
      });
      if (!bg) {
        _snack(
          'Set — for arrival while the app is closed, allow location '
          '"all the time" in system settings.',
        );
      }
    }
  }

  /// Register or clear the task's arrival geofence to match the current state.
  Future<void> _applyGeofence(String taskId) async {
    if (_geofence && _lat != null && _lng != null) {
      await SaaraGeofence.register(taskId, _lat!, _lng!);
    } else {
      await SaaraGeofence.remove(taskId);
    }
  }

  Future<void> _pickFromDrive() async {
    final link = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DrivePickerScreen()),
    );
    if (link != null && mounted) {
      setState(() => _docLinkController.text = link);
    }
  }

  String get _areaNames =>
      (ref.read(activeAreasProvider).valueOrNull ?? const [])
          .map((a) => a.displayName)
          .join(', ');

  String _buildExtractPrompt() {
    final now = DateTime.now();
    return 'Today is ${promptNow(now)}. This image '
        'is a photo/screenshot of a message, invitation, or note describing ONE '
        'to-do or calendar event. Resolve any relative date/time — e.g. "in 2 '
        'days", "within 2 days", "tomorrow 5pm", "next Friday" — to an absolute '
        'ISO-8601 datetime. Return ONLY JSON with keys: '
        '"title" (short string), '
        '"kind" ("task" or "event"; use "event" for an appointment, meeting, or '
        'anything with a specific clock time or venue), '
        '"datetime" (ISO-8601 with time, or null), '
        '"durationMinutes" (number or null), '
        '"repeat" ("once","daily","weekly","monthly"), '
        '"area" (the ONE best-fitting name from [$_areaNames], or null), '
        '"location" (venue/address string, or null), '
        '"link" (the first URL in the text, or null), '
        '"linkType" ("meeting" for a Zoom/Teams/Google Meet join link, '
        '"document" for a file/audio/video/Drive link, else "other"), '
        '"notes" (string). No commentary, JSON only.';
  }

  /// Structure the typed/pasted text into fields with AI (§11) — e.g. copy a
  /// WhatsApp message and let Saara turn it into a meaningful task/event.
  Future<void> _structureFromText() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      _snack('Type or paste some text first, then tap AI.');
      return;
    }
    final config = await ref.read(aiConfigProvider.future);
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      _snack('Add an AI key in Settings → Saara AI to use this.');
      return;
    }
    setState(() => _aiBusy = true);
    try {
      final now = DateTime.now();
      final prompt =
          'Today is ${promptNow(now)}. From the '
          'message below, extract ONE to-do or calendar event. Resolve relative '
          'dates ("in 2 days", "tomorrow 5pm", "next Friday"). Return ONLY JSON '
          'with keys: "title","kind"("task"|"event"),"datetime"(ISO or null). '
          'Use "event" ONLY for a scheduled meeting/appointment at a specific '
          'time (it MUST have a datetime); use "task" for to-dos, payments, '
          'errands, reminders, and anything without a specific meeting time. '
          'Other keys: '
          '"durationMinutes"(num|null),"repeat"("once"|"daily"|"weekly"|"monthly"),'
          '"area"(the ONE best-fitting name from [$_areaNames], or null),'
          '"location"(str|null),"link"(str|null),'
          '"linkType"("meeting"|"document"|"other"),"notes"(str). No commentary, '
          'JSON only.\n\nMESSAGE:\n$text';
      final out = await ref
          .read(llmServiceProvider)
          .extractFromText(config, prompt: prompt);
      _applyExtraction(out);
    } catch (e) {
      _snack('AI failed: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  /// Optional smart layer (§6/§11): let the AI read the attached image into the
  /// fields. The image stays attached so the result can be verified/edited.
  Future<void> _extractWithAi({bool silentIfNoKey = false}) async {
    final img = _effectiveImage;
    if (img == null) return;
    final config = await ref.read(aiConfigProvider.future);
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      if (!silentIfNoKey) {
        _snack('Add a Gemini key in Settings → Saara AI to use this.');
      }
      return;
    }
    setState(() => _aiBusy = true);
    try {
      final bytes = await File(img).readAsBytes();
      final mime = img.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final out = await ref
          .read(llmServiceProvider)
          .extractFromImage(
            config,
            imageBytes: bytes,
            mimeType: mime,
            prompt: _buildExtractPrompt(),
          );
      _applyExtraction(out);
    } catch (e) {
      _snack('AI extraction failed: $e');
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
  }

  void _applyExtraction(String raw) {
    // Be defensive — strip any code fences the model might add.
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s
          .replaceAll(RegExp(r'^```[a-zA-Z]*'), '')
          .replaceAll('```', '')
          .trim();
    }
    Map<String, dynamic> data;
    try {
      data = json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      _snack('Could not read the AI response — edit the fields manually.');
      return;
    }
    final areas = ref.read(activeAreasProvider).valueOrNull ?? const [];
    setState(() {
      final title = data['title'];
      if (title is String && title.trim().isNotEmpty) {
        _titleController.text = title.trim();
      }
      final dt = data['datetime'];
      DateTime? parsedDt;
      if (dt is String) {
        parsedDt = parseAiDateTime(dt);
        if (parsedDt != null) _scheduledStart = parsedDt;
      }
      // An event is a time-blocked calendar entry, so it only makes sense with
      // a concrete time. If the model labels something an "event" but gives no
      // datetime (e.g. "pay Bharath 680"), keep it a to-do — otherwise the
      // event-needs-a-date rule would block saving a perfectly good task.
      if (data['kind'] == 'event' && parsedDt != null) _kind = TaskKind.event;
      final dur = data['durationMinutes'];
      if (dur is num) _durationMin = dur.toInt();
      _rrule = switch ((data['repeat'] ?? 'once').toString().toLowerCase()) {
        'daily' => 'FREQ=DAILY',
        'weekly' => 'FREQ=WEEKLY',
        'monthly' => 'FREQ=MONTHLY',
        _ => null,
      };
      final notes = data['notes'];
      if (notes is String && notes.trim().isNotEmpty) {
        _notesController.text = notes.trim();
      }
      final loc = data['location'];
      if (loc is String && loc.trim().isNotEmpty) {
        _locationController.text = loc.trim();
      }
      // Route the link: a meeting join link is a "join" link on the item; any
      // other URL (file/audio/video/Drive) becomes the document link.
      final link = data['link'];
      if (link is String && link.trim().isNotEmpty) {
        final type = (data['linkType'] ?? 'other').toString().toLowerCase();
        if (type == 'meeting') {
          _meetingLinkController.text = link.trim();
        } else {
          _docLinkController.text = link.trim();
        }
      }
      final area = data['area'];
      if (area is String && area.trim().isNotEmpty) {
        final want = area.trim().toLowerCase();
        final match = areas.firstWhereOrNull(
          (a) =>
              a.displayName.toLowerCase().contains(want) ||
              a.baseCategory.name == want,
        );
        if (match != null) _areaId = match.id;
      }
    });
    _checkConflicts();
    _snack('Filled from the image — please check the fields.');
  }

  /// §8 conflict detection — an event overlapping existing scheduled items on
  /// that day. Warns and suggests; the user resolves by changing the time.
  Future<void> _checkConflicts() async {
    final start = _scheduledStart;
    if (start == null || _kind != TaskKind.event) {
      if (mounted) setState(() => _conflictWarning = null);
      return;
    }
    final end = start.add(Duration(minutes: _durationMin ?? 60));
    final day = DateTime(start.year, start.month, start.day);
    final items = await ref.read(taskDaoProvider).tasksForDay(day);
    final clashes = items.where((t) {
      final s = t.scheduledStart;
      if (s == null) return false;
      final e = s.add(Duration(minutes: t.durationMin ?? 60));
      return start.isBefore(e) && end.isAfter(s); // time-window overlap
    }).toList();
    if (!mounted) return;
    setState(() {
      // Advisory only — never a blocker. Double-booking is sometimes exactly
      // what you mean, so Saara points it out and leaves the call to you.
      _conflictWarning = clashes.isEmpty
          ? null
          : 'Heads-up: overlaps ${clashes.length} item'
                '${clashes.length == 1 ? '' : 's'} — '
                '${clashes.map((c) => c.title).take(2).join(', ')}. '
                'You can still save; change the time only if you want to.';
    });
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _viewImage(String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: Image.file(File(path), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledStart ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledStart ?? now),
    );
    setState(() {
      _scheduledStart = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 9,
        time?.minute ?? 0,
      );
    });
    _checkConflicts();
  }

  static String _durationLabel(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60, r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}m';
  }

  /// Shows the computed end, or an invitation to set one.
  String _endsLabel() {
    final start = _scheduledStart;
    if (start == null || _durationMin == null) return 'Set end…';
    final end = start.add(Duration(minutes: _durationMin!));
    final sameDay =
        end.day == start.day &&
        end.month == start.month &&
        end.year == start.year;
    return 'Ends ${DateFormat(sameDay ? 'h:mm a' : 'MMM d · h:mm a').format(end)}';
  }

  /// Pick an end date+time; duration is derived from it. Supports a session
  /// that crosses midnight (e.g. 9 PM → 1 AM).
  Future<void> _pickEnd() async {
    final start = _scheduledStart;
    if (start == null) {
      _snack('Set the start date/time first.');
      return;
    }
    final current = start.add(Duration(minutes: _durationMin ?? 60));
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(start.year, start.month, start.day),
      lastDate: start.add(const Duration(days: 7)),
      helpText: 'Ends on',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Ends at',
    );
    if (!mounted) return;
    final end = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    final mins = end.difference(start).inMinutes;
    if (mins <= 0) {
      _snack('The end must be after the start.');
      return;
    }
    setState(() => _durationMin = mins);
  }

  /// Opens the document field — a web link **or a local file path**. A path
  /// like `C:\docs\notes.pdf` isn't a URL, so it must be converted with
  /// [Uri.file]; `Uri.parse` silently produced something unopenable before.
  Future<void> _openDocLink() async {
    final raw = _docLinkController.text.trim();
    if (raw.isEmpty) return;
    final lower = raw.toLowerCase();
    final isUrl =
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:');
    try {
      final uri = isUrl ? Uri.parse(raw) : Uri.file(raw);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _snack('Nothing on this device can open that.');
    } catch (e) {
      if (mounted) _snack('Could not open: $e');
    }
  }

  /// Attach any file from disk by path (works on desktop and mobile). Saara
  /// stores the *path*, not a copy — opening hands it to the OS.
  Future<void> _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _docLinkController.text = path);
  }

  /// Desktop fallback for participants: type a name. `flutter_contacts` is
  /// mobile-only, so rather than a button that throws, desktop captures the
  /// name directly — it's stored the same way and syncs the same way.
  Future<void> _addParticipantByName() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add participant'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Name',
            border: OutlineInputBorder(),
            helperText: 'Device contacts are available on mobile.',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    setState(
      () => _participants.add(
        SimpleContact(id: 'manual:${name.toLowerCase()}', name: name),
      ),
    );
  }

  Future<void> _pickParticipant() async {
    final picked = await Navigator.of(context).push<SimpleContact>(
      MaterialPageRoute(builder: (_) => const ContactPickerScreen()),
    );
    if (picked == null) return;
    if (_participants.any((c) => c.id == picked.id)) return; // no duplicates
    setState(() => _participants.add(picked));
  }

  /// Write an update to an existing task (§4) — marks it dirty so the two-way
  /// sync pushes the change to Google Tasks/Calendar.
  /// Ask which dates an edit applies to, mirroring Outlook / Google Calendar.
  /// Returns 'one' | 'following' | 'series', or null if cancelled.
  Future<String?> _askEditScope() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Save repeating task'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'This task repeats. Which dates should the change apply to?',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ),
          for (final o in const [
            ('one', 'This event', 'Only this date'),
            (
              'following',
              'This and following events',
              'This date and every later one',
            ),
            ('series', 'All events', 'Every date in the series'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, o.$1),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(o.$2),
                subtitle: Text(o.$3),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fields that are the same on every date of a series. Time is handled apart:
  /// each date keeps its own day and only the time-of-day moves.
  TasksCompanion _sharedSeriesFields(String title) => TasksCompanion(
    title: Value(title),
    notes: Value(
      _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ),
    areaId: Value(_areaId),
    durationMin: Value(_durationMin),
    locationName: Value(
      _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    ),
    meetingLink: Value(
      _meetingLinkController.text.trim().isEmpty
          ? null
          : _meetingLinkController.text.trim(),
    ),
    reminderOffsets: Value(_reminderEnabled ? const [-15] : null),
  );

  /// Apply an edit to more than this one date.
  ///
  /// *All events* rewrites the rule and every occurrence. *This and following*
  /// splits the series — the old rule is capped just before this date and a new
  /// one carries the change forward, so earlier dates are left exactly as they
  /// were. Splitting rather than editing in place is what keeps history honest.
  Future<void> _saveSeriesEdit(
    Task t,
    String title,
    DateTime? anchor,
    String scope,
    DateTime now,
  ) async {
    final dao = ref.read(taskDaoProvider);
    final slot = t.occurrenceSlot ?? t.scheduledStart;
    final shared = _sharedSeriesFields(title);

    if (scope == 'series') {
      await dao.applyToWholeSeries(
        templateId: t.parentRecurringId!,
        shared: shared,
        newHour: anchor?.hour,
        newMinute: anchor?.minute,
      );
    } else {
      await dao.splitSeriesAt(
        templateId: t.parentRecurringId!,
        fromSlot: slot ?? now,
        newTemplateId: ref.read(uuidProvider).v4(),
        shared: shared.copyWith(
          kind: Value(_kind),
          geofenceEnabled: Value(_geofence),
          lat: Value(_lat),
          lng: Value(_lng),
          source: Value(t.source),
          priority: Value(t.priority),
        ),
        newStart: anchor ?? slot ?? now,
      );
    }

    // Regenerate so the new/updated rule's dates appear immediately.
    ref.invalidate(materializeRecurringProvider);
    ref.invalidate(allTasksProvider);
    ref.invalidate(unscheduledTasksProvider);
    ref.invalidate(tasksForDayProvider);
    ref.invalidate(tasksBetweenProvider);
    ref.invalidate(scheduleConflictsProvider);
    ref.invalidate(taskByIdProvider(t.id));
    await _syncAfterSave(t.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scope == 'series'
              ? 'Updated every date of “$title”.'
              : 'Updated “$title” from this date onward — earlier dates kept.',
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveEdit(
    Task t,
    String title,
    DateTime? anchor,
    bool isEvent,
    DateTime now,
  ) async {
    final db = ref.read(appDatabaseProvider);
    // Editing one date of a repeating task: ask the scope first (§4).
    if (t.parentRecurringId != null) {
      final scope = await _askEditScope();
      if (scope == null) return; // cancelled — change nothing
      if (scope != 'one') {
        await _saveSeriesEdit(t, title, anchor, scope, now);
        return;
      }
    }
    await (db.update(db.tasks)..where((x) => x.id.equals(t.id))).write(
      TasksCompanion(
        title: Value(title),
        kind: Value(_kind),
        attachmentImagePath: Value(_effectiveImage),
        documentLink: Value(
          _docLinkController.text.trim().isEmpty
              ? null
              : _docLinkController.text.trim(),
        ),
        notes: Value(
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
        areaId: Value(_areaId),
        scheduledStart: Value(anchor),
        dueDate: Value(anchor),
        durationMin: Value(_durationMin),
        rrule: Value(_rrule),
        reminderOffsets: Value(_reminderEnabled ? const [-15] : null),
        meetingLink: Value(
          _meetingLinkController.text.trim().isEmpty
              ? null
              : _meetingLinkController.text.trim(),
        ),
        // Meet provider + no link is the "mint one on next sync" signal (§9).
        // Fall back to the task's existing provider, not _draft (null on edit),
        // so editing an event doesn't silently wipe its provider.
        meetingProvider: Value(
          _generateMeet ? MeetingProvider.meet : t.meetingProvider,
        ),
        locationName: Value(
          _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        ),
        geofenceEnabled: Value(_geofence),
        lat: Value(_lat),
        lng: Value(_lng),
        updatedAt: Value(now),
      ),
    );
    await _applyGeofence(t.id);
    ref.invalidate(taskByIdProvider(t.id));
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
    ref.invalidate(unscheduledTasksProvider);
    if (anchor != null) {
      ref.invalidate(
        tasksForDayProvider(DateTime(anchor.year, anchor.month, anchor.day)),
      );
    }
    final oldStart = t.scheduledStart;
    if (oldStart != null) {
      ref.invalidate(
        tasksForDayProvider(
          DateTime(oldStart.year, oldStart.month, oldStart.day),
        ),
      );
    }
    // §8 reschedule or clear the reminder to match the edit.
    if (_reminderEnabled && anchor != null) {
      await NotificationService.instance.scheduleTaskReminder(
        taskId: t.id,
        title: title,
        when: anchor,
        offsetsMinutes: const [-15],
      );
    } else {
      await NotificationService.instance.cancelTaskReminder(t.id);
    }
    await _syncAfterSave(t.id);
    if (mounted) Navigator.of(context).pop();
  }

  /// Get the just-saved item onto Google. For a Meet event we **wait** — the
  /// link is minted server-side and the user may share the invite immediately
  /// (§9, §11), so it must exist before we return. Everything else syncs in the
  /// background so Save stays instant.
  Future<void> _syncAfterSave(String taskId) async {
    final connected = await ref.read(googleSyncServiceProvider).isConnected();
    if (!connected) {
      if (_generateMeet && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Saved. Connect Google in Settings to add the Meet link.',
            ),
          ),
        );
      }
      return;
    }
    if (!_generateMeet) {
      unawaited(() async {
        try {
          await ref.read(googleSyncOrchestratorProvider).syncAll();
        } catch (_) {}
      }());
      return;
    }
    // Meet event: block behind a spinner until Google returns the link.
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Creating Google Meet link…')),
            ],
          ),
        ),
      );
    }
    String? link;
    String? error;
    try {
      // Targeted create/patch — deterministic, unlike the full reconcile.
      link = await ref
          .read(googleSyncOrchestratorProvider)
          .ensureMeetLink(taskId);
      // Fold the rest of the event into Google in the background.
      unawaited(() async {
        try {
          await ref.read(googleSyncOrchestratorProvider).syncAll();
        } catch (_) {}
      }());
    } catch (e) {
      error = '$e';
      debugPrint('Saara Meet link failed: $e');
    }
    ref.invalidate(taskByIdProvider(taskId));
    if (mounted) Navigator.of(context).pop(); // close the spinner
    if (mounted && (link ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            error == null
                ? 'Saved. Google didn\'t return a Meet link — open the event '
                      'and try again, or add a link manually.'
                : 'Saved, but the Meet link failed: $error',
          ),
        ),
      );
    }
  }

  /// Wraps the save so a failure is *visible*. Previously any exception left
  /// the form open with no message — indistinguishable from "the button does
  /// nothing", which is how a save silently failed.
  Future<void> _save({required bool release}) async {
    try {
      await _performSave(release: release);
    } catch (e, st) {
      debugPrint('Saara save failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not save: $e"),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _performSave({required bool release}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    final isEvent = _kind == TaskKind.event;
    if (isEvent && _scheduledStart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An event needs a date & time')),
      );
      return;
    }
    final now = DateTime.now();
    final id = ref.read(uuidProvider).v4();

    // A recurring task is a template and needs an anchor start (DTSTART) for the
    // RRULE to expand from. If the user gave no date, anchor it to today so
    // instances (incl. today's) generate. One-off tasks keep a null date.
    // Events are single occurrences (Calendar recurrence is a later add).
    final isRecurring = !isEvent && _rrule != null;
    final anchor =
        _scheduledStart ??
        (isRecurring ? DateTime(now.year, now.month, now.day, 9) : null);

    if (widget.editing != null) {
      // Releasing a draft you saved earlier — the commitment is made here, so
      // it is recorded here.
      if (release && !_alreadyReleased) {
        await ref.read(taskServiceProvider).release(widget.editing!);
      }
      await _saveEdit(widget.editing!, title, anchor, isEvent, now);
      return;
    }

    final companion = TasksCompanion.insert(
      id: id,
      title: title,
      kind: Value(_kind),
      publicationState: Value(
        release ? PublicationState.released : PublicationState.draft,
      ),
      attachmentImagePath: Value(_effectiveImage),
      documentLink: Value(
        _docLinkController.text.trim().isEmpty
            ? null
            : _docLinkController.text.trim(),
      ),
      notes: Value(
        _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
      areaId: Value(_areaId),
      status: const Value(TaskStatus.created),
      scheduledStart: Value(anchor),
      dueDate: Value(anchor),
      durationMin: Value(_durationMin),
      rrule: Value(_rrule),
      reminderOffsets: Value(_reminderEnabled ? const [-15] : null),
      meetingLink: Value(
        _meetingLinkController.text.trim().isEmpty
            ? _draft?.meetingLink
            : _meetingLinkController.text.trim(),
      ),
      meetingProvider: Value(
        _generateMeet ? MeetingProvider.meet : _draft?.meetingProvider,
      ),
      locationName: Value(
        _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      ),
      geofenceEnabled: Value(_geofence),
      lat: Value(_lat),
      lng: Value(_lng),
      source: Value(_draft?.source ?? TaskSource.manual),
      createdAt: now,
      updatedAt: now,
    );
    await ref.read(taskDaoProvider).insertTask(companion);
    // The ledger records both facts: that it came into existence, and — if you
    // committed here — the moment you gave your word (§4.1d).
    final saved = await ref.read(taskDaoProvider).findById(id);
    if (saved != null) {
      final service = ref.read(taskServiceProvider);
      await service.recordCreated(saved);
      if (release) await service.release(saved);
    }
    await _applyGeofence(id);

    // Persist chosen participants as on-device contact refs (§3.3, §11).
    final dao = ref.read(taskDaoProvider);
    final uuid = ref.read(uuidProvider);
    for (final c in _participants) {
      await dao.addParticipant(
        TaskParticipantsCompanion.insert(
          id: uuid.v4(),
          taskId: id,
          contactLookupKey: c.id,
          displayName: c.name,
        ),
      );
    }

    // For recurring templates, generate the upcoming instances immediately so
    // they show up without an app restart (§4, §8).
    if (isRecurring) {
      await ref.read(recurringEngineProvider).materializeAll();
    }

    // §8 per-task reminder (opt-in): schedule 15 min before the start.
    if (_reminderEnabled && anchor != null) {
      await NotificationService.instance.scheduleTaskReminder(
        taskId: id,
        title: title,
        when: anchor,
        offsetsMinutes: const [-15],
      );
    }

    // Refresh today (an instance may land today) and the anchored day.
    ref.invalidate(tasksForDayProvider(DateTime(now.year, now.month, now.day)));
    ref.invalidate(unscheduledTasksProvider);
    if (anchor != null) {
      ref.invalidate(
        tasksForDayProvider(DateTime(anchor.year, anchor.month, anchor.day)),
      );
    }
    // Push the new item to Google promptly (§9); a Meet event waits for its link.
    await _syncAfterSave(id);
    if (mounted) Navigator.of(context).pop();
  }
}

/// A compact circular weekday toggle for the repeat-on picker (§4 RRULE BYDAY).
class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? scheme.primary : Colors.transparent,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, this.uncertain);
  final String label;
  final bool uncertain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: uncertain ? scheme.error : scheme.primary,
            ),
          ),
          if (uncertain) ...[
            const SizedBox(width: 6),
            Icon(Icons.help_outline, size: 14, color: scheme.error),
          ],
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.event, size: 18),
      label: Text(text),
    );
  }
}

/// Choice chips over the user's actual Areas (seeded on first launch, §20.3).
/// Selecting one sets the task's `area_id`; "None" leaves it unassigned (§5.5).
class _AreaChips extends ConsumerWidget {
  const _AreaChips({required this.selectedId, required this.onSelected});
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(activeAreasProvider);
    return areas.when(
      loading: () => const SizedBox(height: 32),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) => Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('None'),
            selected: selectedId == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final a in list)
            ChoiceChip(
              label: Text(a.displayName),
              selected: selectedId == a.id,
              onSelected: (_) => onSelected(a.id),
            ),
          // Create an area without leaving the task (§7.5). Capped at 10 areas
          // upstream — keep it focused.
          if (list.length < 10)
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('New area'),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddAreaScreen(nextSortOrder: list.length),
                  ),
                );
                // Select whatever was just created, so the task is categorised
                // immediately (an uncategorised task skews the area metrics).
                final fresh = await ref.refresh(activeAreasProvider.future);
                final added = fresh.where(
                  (a) => !list.any((o) => o.id == a.id),
                );
                if (added.isNotEmpty) onSelected(added.first.id);
              },
            ),
        ],
      ),
    );
  }
}

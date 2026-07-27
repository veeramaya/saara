import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/platform.dart';
import 'desktop_google_auth.dart';
import 'google_config.dart';

class GoogleSyncException implements Exception {
  GoogleSyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A Google Task as returned by the REST API, with the fields two-way sync needs.
class GTask {
  GTask({
    required this.id,
    required this.listId,
    required this.title,
    this.notes,
    this.due,
    this.completed = false,
    this.deleted = false,
    required this.updated,
  });
  final String id;
  final String listId;
  final String title;
  final String? notes;
  final DateTime? due;
  final bool completed;
  final bool deleted;

  /// RFC3339 last-modification stamp from Google (used for conflict detection).
  final String updated;
}

/// A Google Calendar event as needed for read-only import (§9). Meetings and
/// appointments land on the Saara timeline so desktop calendar and mobile agree.
class GCalEvent {
  GCalEvent({
    required this.id,
    required this.title,
    this.start,
    this.durationMin,
    this.meetingLink,
    this.location,
    this.cancelled = false,
    this.recurringEventId,
    required this.updated,
  });
  final String id;
  final String title;
  final DateTime? start;
  final int? durationMin;
  final String? meetingLink;
  final String? location;
  final bool cancelled;

  /// For an expanded instance of a recurring event, the id of its master event
  /// (null for single events / masters). Used to avoid duplicate imports and
  /// false deletes of recurring events created in Saara (§9).
  final String? recurringEventId;
  final String updated;
}

/// A Google Drive file for the picker (§11) — the user selects one and its
/// webViewLink is stored on the task, opening in Google when tapped.
class GDriveFile {
  GDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.link,
  });
  final String id;
  final String name;
  final String mimeType;
  final String link;
}

/// §9 Google Tasks two-way sync transport. Device→Google directly (§1.4).
/// google_sign_in for auth; Tasks REST over http. Google Tasks appear in the
/// Calendar app's Tasks layer, keeping desktop (web) and mobile in step.
class GoogleSyncService {
  GoogleSyncService({http.Client? httpClient})
    : _http = httpClient ?? http.Client(),
      // No serverClientId: we only need an OAuth *access token* to call the
      // Tasks REST API, which the Android OAuth client (package + SHA-1)
      // provides directly. A serverClientId must be a Web-application client;
      // pointing it at an Android client caused sign-in error 10 (§9).
      _google = GoogleSignIn(scopes: kGoogleScopes);

  final http.Client _http;
  final GoogleSignIn _google;

  static const _tasksBase = 'https://tasks.googleapis.com/tasks/v1';

  GoogleSignInAccount? get currentUser => _google.currentUser;

  /// True when we hold usable credentials — mobile account or desktop tokens.
  /// Callers use this (not [currentUser]) so both platforms behave the same.
  Future<bool> isConnected() async {
    if (isDesktop) return desktopAuth.isConnected;
    return (await _google.signInSilently()) != null;
  }

  /// Silent restore on app start. Returns null on desktop (no account object);
  /// use [isConnected] there.
  Future<GoogleSignInAccount?> restore() async {
    if (isDesktop) {
      // Refreshing proves the stored grant is still good.
      if (!await desktopAuth.isConnected) return null;
      await desktopAuth.accessToken();
      return null;
    }
    return _google.signInSilently();
  }

  /// Interactive connect. On desktop this opens the browser (loopback + PKCE)
  /// and returns the signed-in email; on mobile it returns the account.
  Future<GoogleSignInAccount?> connect() => _google.signIn();

  /// Desktop-only interactive connect; returns the signed-in email.
  Future<String> connectDesktop() => desktopAuth.signIn(kGoogleScopes);

  /// The Google account Saara is connected as, on either platform. Used to send
  /// mail *from* the account the user signed in with rather than whatever the
  /// OS considers the default mail client (§13).
  Future<String?> signedInEmail() async {
    if (isDesktop) return desktopAuth.connectedEmail();
    final acct = _google.currentUser ?? await _google.signInSilently();
    return acct?.email;
  }

  Future<void> disconnect() async {
    if (isDesktop) return desktopAuth.signOut();
    await _google.disconnect();
  }

  /// Desktop OAuth (loopback + PKCE) — used when google_sign_in has no
  /// implementation for the platform (Windows/Linux/macOS, §9).
  final DesktopGoogleAuth desktopAuth = DesktopGoogleAuth();

  Future<Map<String, String>> _authHeader() async {
    final String? token;
    if (isDesktop) {
      token = await desktopAuth.accessToken();
      if (token == null) {
        throw GoogleSyncException(
          'Not connected to Google. Connect in Settings → Google sync.',
        );
      }
    } else {
      final account = _google.currentUser ?? await _google.signInSilently();
      if (account == null) {
        throw GoogleSyncException('Not connected to Google.');
      }
      token = (await account.authentication).accessToken;
      if (token == null) {
        throw GoogleSyncException('Could not get a Google access token.');
      }
    }
    return {'Authorization': 'Bearer $token'};
  }

  /// The first task list id (where new pushes land; also '@default' works).
  Future<String> defaultListId() async {
    final headers = await _authHeader();
    final lists = await _getJson('$_tasksBase/users/@me/lists', headers);
    final items = (lists['items'] as List?) ?? const [];
    if (items.isEmpty) return '@default';
    return (items.first as Map)['id'] as String;
  }

  /// Every task across every list, including completed, hidden, and deleted
  /// (deletions must be visible so we can propagate them).
  Future<List<GTask>> fetchAllTasks() async {
    final headers = await _authHeader();
    final lists = await _getJson('$_tasksBase/users/@me/lists', headers);
    final out = <GTask>[];
    for (final l in (lists['items'] as List?) ?? const []) {
      final listId = (l as Map)['id'] as String;
      // Page through the whole list. Google caps a page at 100 and returns an
      // unspecified order, so *not* following nextPageToken silently drops an
      // arbitrary subset once a list exceeds one page (§9).
      String? pageToken;
      var guard = 0;
      do {
        final tasks = await _getJson(
          '$_tasksBase/lists/$listId/tasks'
          '?showCompleted=true&showHidden=true&showDeleted=true&maxResults=100'
          '${pageToken == null ? '' : '&pageToken=${Uri.encodeComponent(pageToken)}'}',
          headers,
        );
        for (final t in (tasks['items'] as List?) ?? const []) {
          out.add(_parse(t as Map<String, dynamic>, listId));
        }
        pageToken = tasks['nextPageToken'] as String?;
      } while (pageToken != null && ++guard < 50); // ≤5000 tasks per list
    }
    return out;
  }

  static const _calBase =
      'https://www.googleapis.com/calendar/v3/calendars/primary/events';

  /// Read the primary calendar's events in [timeMin, timeMax] (§9). Recurring
  /// events are expanded (`singleEvents=true`). Throws if the Calendar API isn't
  /// enabled — the caller catches so Tasks sync still succeeds.
  Future<List<GCalEvent>> fetchCalendarEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    final headers = await _authHeader();
    final base =
        '$_calBase?singleEvents=true&orderBy=startTime&maxResults=250'
        '&showDeleted=true'
        '&timeMin=${Uri.encodeComponent(timeMin.toUtc().toIso8601String())}'
        '&timeMax=${Uri.encodeComponent(timeMax.toUtc().toIso8601String())}';
    final out = <GCalEvent>[];
    // Page through — a busy month can exceed one page, and dropping the tail
    // would silently lose events from the window (§9).
    String? pageToken;
    var guard = 0;
    do {
      final data = await _getJson(
        pageToken == null
            ? base
            : '$base&pageToken=${Uri.encodeComponent(pageToken)}',
        headers,
      );
      for (final item in (data['items'] as List?) ?? const []) {
        out.add(_parseEvent(item as Map<String, dynamic>));
      }
      pageToken = data['nextPageToken'] as String?;
    } while (pageToken != null && ++guard < 20); // ≤5000 events per window
    return out;
  }

  /// Create a Calendar event (§9). Timed event; end defaults to +60 min. Pass
  /// [rrule] (e.g. "FREQ=WEEKLY;BYDAY=MO") to make it recurring on Google.
  Future<GCalEvent> insertEvent({
    required String title,
    String? notes,
    required DateTime start,
    int? durationMin,
    String? location,
    String? rrule,
    String? meetRequestId,
  }) async {
    final headers = await _authHeader();
    // conferenceDataVersion=1 is required for Google to honour a Meet request.
    final url = Uri.parse(_calBase).replace(
      queryParameters: {
        if (meetRequestId != null) 'conferenceDataVersion': '1',
      },
    );
    final res = await _http.post(
      url,
      headers: {...headers, 'content-type': 'application/json'},
      body: json.encode(
        _eventBody(
          title: title,
          notes: notes,
          start: start,
          durationMin: durationMin,
          location: location,
          rrule: rrule,
          meetRequestId: meetRequestId,
        ),
      ),
    );
    if (res.statusCode >= 400) throw _error(res);
    return _parseEvent(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<GCalEvent> patchEvent({
    required String id,
    required String title,
    String? notes,
    required DateTime start,
    int? durationMin,
    String? location,
    String? rrule,
    String? meetRequestId,
  }) async {
    final headers = await _authHeader();
    final url = Uri.parse('$_calBase/$id').replace(
      queryParameters: {
        if (meetRequestId != null) 'conferenceDataVersion': '1',
      },
    );
    final res = await _http.patch(
      url,
      headers: {...headers, 'content-type': 'application/json'},
      body: json.encode(
        _eventBody(
          title: title,
          notes: notes,
          start: start,
          durationMin: durationMin,
          location: location,
          rrule: rrule,
          meetRequestId: meetRequestId,
        ),
      ),
    );
    if (res.statusCode >= 400) throw _error(res);
    return _parseEvent(json.decode(res.body) as Map<String, dynamic>);
  }

  /// Fetch one event by id (with conference data). Used to re-read a freshly
  /// created Meet event whose conference was still "pending" in the create
  /// response, so the join link is populated before we show it (§9).
  Future<GCalEvent> getEvent(String id) async {
    final headers = await _authHeader();
    final url = Uri.parse(
      '$_calBase/$id',
    ).replace(queryParameters: {'conferenceDataVersion': '1'});
    final data = await _getJson(url.toString(), headers);
    return _parseEvent(data);
  }

  Future<void> deleteEvent(String id) async {
    final headers = await _authHeader();
    final res = await _http.delete(
      Uri.parse('$_calBase/$id'),
      headers: headers,
    );
    if (res.statusCode >= 400 &&
        res.statusCode != 404 &&
        res.statusCode != 410) {
      throw _error(res);
    }
  }

  Map<String, dynamic> _eventBody({
    required String title,
    String? notes,
    required DateTime start,
    int? durationMin,
    String? location,
    String? rrule,
    String? meetRequestId,
  }) {
    final end = start.add(Duration(minutes: durationMin ?? 60));
    final body = <String, dynamic>{
      'summary': title,
      // Send in UTC (Z) — Google renders in the viewer's zone. A **recurring**
      // event is additionally *rejected* without an explicit `timeZone`
      // ("Missing time zone definition for start time"), so name it: UTC, to
      // match the UTC instant we send. This anchors the series to a fixed
      // instant (Saara's absolute-time model) — correct here, and India has no
      // DST to drift it.
      'start': {'dateTime': start.toUtc().toIso8601String(), 'timeZone': 'UTC'},
      'end': {'dateTime': end.toUtc().toIso8601String(), 'timeZone': 'UTC'},
    };
    if (notes != null) body['description'] = notes;
    if (location != null) body['location'] = location;
    if (rrule != null && rrule.isNotEmpty) {
      body['recurrence'] = ['RRULE:$rrule'];
    }
    // Ask Google to mint a Meet link. requestId keys the operation, so reusing
    // the same id (the task's own id) is idempotent — a re-push won't spawn a
    // second conference.
    if (meetRequestId != null) {
      body['conferenceData'] = {
        'createRequest': {
          'requestId': meetRequestId,
          'conferenceSolutionKey': {'type': 'hangoutsMeet'},
        },
      };
    }
    return body;
  }

  GCalEvent _parseEvent(Map<String, dynamic> m) {
    final start = _eventTime(m['start'] as Map<String, dynamic>?);
    final end = _eventTime(m['end'] as Map<String, dynamic>?);
    final durationMin = (start != null && end != null)
        ? end.difference(start).inMinutes
        : null;
    // Meeting link: hangoutLink, else the first video conference entry point.
    String? link = m['hangoutLink'] as String?;
    if (link == null && m['conferenceData'] is Map) {
      final eps = (m['conferenceData'] as Map)['entryPoints'];
      if (eps is List) {
        for (final e in eps) {
          if (e is Map && e['entryPointType'] == 'video') {
            link = e['uri'] as String?;
            break;
          }
        }
      }
    }
    return GCalEvent(
      id: m['id'] as String,
      title: (m['summary'] as String?)?.trim() ?? '(no title)',
      start: start,
      durationMin: (durationMin != null && durationMin > 0)
          ? durationMin
          : null,
      meetingLink: link,
      location: m['location'] as String?,
      cancelled: m['status'] == 'cancelled',
      recurringEventId: m['recurringEventId'] as String?,
      updated: (m['updated'] ?? '').toString(),
    );
  }

  DateTime? _eventTime(Map<String, dynamic>? t) {
    if (t == null) return null;
    final dt = t['dateTime'] as String?;
    if (dt != null) return DateTime.tryParse(dt)?.toLocal();
    final d = t['date'] as String?; // all-day event → local midnight
    return d != null ? DateTime.tryParse(d) : null;
  }

  Future<GTask> insertTask({
    required String title,
    String? notes,
    DateTime? due,
    bool completed = false,
    required String listId,
  }) async {
    final headers = await _authHeader();
    final res = await _http.post(
      Uri.parse('$_tasksBase/lists/$listId/tasks'),
      headers: {...headers, 'content-type': 'application/json'},
      body: json.encode(
        _taskBody(title: title, notes: notes, due: due, completed: completed),
      ),
    );
    if (res.statusCode >= 400) throw _error(res);
    return _parse(json.decode(res.body) as Map<String, dynamic>, listId);
  }

  Future<GTask> patchTask({
    required String listId,
    required String id,
    required String title,
    String? notes,
    DateTime? due,
    required bool completed,
  }) async {
    final headers = await _authHeader();
    final res = await _http.patch(
      Uri.parse('$_tasksBase/lists/$listId/tasks/$id'),
      headers: {...headers, 'content-type': 'application/json'},
      body: json.encode(
        _taskBody(title: title, notes: notes, due: due, completed: completed),
      ),
    );
    if (res.statusCode >= 400) throw _error(res);
    return _parse(json.decode(res.body) as Map<String, dynamic>, listId);
  }

  Future<void> deleteTask(String listId, String id) async {
    final headers = await _authHeader();
    final res = await _http.delete(
      Uri.parse('$_tasksBase/lists/$listId/tasks/$id'),
      headers: headers,
    );
    // 404/410 → already gone; treat as success.
    if (res.statusCode >= 400 &&
        res.statusCode != 404 &&
        res.statusCode != 410) {
      throw _error(res);
    }
  }

  Map<String, dynamic> _taskBody({
    required String title,
    String? notes,
    DateTime? due,
    required bool completed,
  }) {
    return {
      'title': title,
      // notes: send even when empty so clearing propagates.
      'notes': notes ?? '',
      'status': completed ? 'completed' : 'needsAction',
      // Google Tasks `due` is date-only (time ignored). Clearing isn't
      // supported via PATCH null, so we only set it when present.
      if (due != null)
        'due': DateTime.utc(due.year, due.month, due.day).toIso8601String(),
    };
  }

  GTask _parse(Map<String, dynamic> m, String listId) {
    return GTask(
      id: m['id'] as String,
      listId: listId,
      title: (m['title'] as String?)?.trim() ?? '',
      notes: m['notes'] as String?,
      due: m['due'] != null
          ? DateTime.tryParse(m['due'].toString())?.toLocal()
          : null,
      completed: m['status'] == 'completed',
      deleted: m['deleted'] == true,
      updated: (m['updated'] ?? '').toString(),
    );
  }

  static const _driveBase = 'https://www.googleapis.com/drive/v3/files';

  /// List the user's Drive files (§11), most-recent first, optionally filtered
  /// by [query] (name contains). Returns (id, name, mimeType, webViewLink).
  Future<List<GDriveFile>> listDriveFiles({String? query}) async {
    final headers = await _authHeader();
    final q = StringBuffer('trashed = false');
    if (query != null && query.trim().isNotEmpty) {
      final safe = query.trim().replaceAll("'", r"\'");
      q.write(" and name contains '$safe'");
    }
    final url =
        '$_driveBase?orderBy=modifiedTime desc&pageSize=50'
        '&fields=files(id,name,mimeType,webViewLink)'
        '&q=${Uri.encodeComponent(q.toString())}';
    final data = await _getJson(url, headers);
    final out = <GDriveFile>[];
    for (final f in (data['files'] as List?) ?? const []) {
      final m = f as Map<String, dynamic>;
      final link = m['webViewLink'] as String?;
      if (link == null) continue;
      out.add(
        GDriveFile(
          id: m['id'] as String,
          name: (m['name'] as String?) ?? 'Untitled',
          mimeType: (m['mimeType'] as String?) ?? '',
          link: link,
        ),
      );
    }
    return out;
  }

  Future<Map<String, dynamic>> _getJson(
    String url,
    Map<String, String> headers,
  ) async {
    final res = await _http.get(Uri.parse(url), headers: headers);
    if (res.statusCode >= 400) throw _error(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  GoogleSyncException _error(http.Response res) {
    if (res.statusCode == 401 || res.statusCode == 403) {
      return GoogleSyncException(
        'Google access denied (${res.statusCode}). '
        'Reconnect, and check the Tasks API is enabled.',
      );
    }
    var msg = 'Google error ${res.statusCode}';
    try {
      final err = json.decode(res.body) as Map<String, dynamic>;
      msg = (err['error'] as Map?)?['message']?.toString() ?? msg;
    } catch (_) {}
    return GoogleSyncException(msg);
  }

  // ---- Drive app-data sync (§9) --------------------------------------------
  // A hidden, app-private folder ('appDataFolder') where Saara keeps only its
  // own encrypted ledger file — it cannot see the user's real Drive files.

  static const _driveFiles = 'https://www.googleapis.com/drive/v3/files';
  static const _driveUpload =
      'https://www.googleapis.com/upload/drive/v3/files';

  /// List the files Saara has in its app-data folder (id + name).
  Future<List<GDriveAppFile>> listAppData() async {
    final headers = await _authHeader();
    final data = await _getJson(
      '$_driveFiles?spaces=appDataFolder&pageSize=100'
      '&fields=${Uri.encodeComponent('files(id,name,modifiedTime)')}',
      headers,
    );
    return [
      for (final f in (data['files'] as List?) ?? const [])
        GDriveAppFile(
          id: (f as Map)['id'].toString(),
          name: f['name'].toString(),
        ),
    ];
  }

  /// Create [name] in the app-data folder, or replace [existingId]'s content.
  Future<void> uploadAppData(
    String name,
    String content, {
    String? existingId,
  }) async {
    final headers = await _authHeader();
    if (existingId != null) {
      // Replace the content of the existing file (metadata unchanged).
      final res = await _http.patch(
        Uri.parse('$_driveUpload/$existingId?uploadType=media'),
        headers: {...headers, 'Content-Type': 'application/octet-stream'},
        body: utf8.encode(content),
      );
      if (res.statusCode >= 400) throw _error(res);
      return;
    }
    // Create: multipart/related — metadata part (parents=appDataFolder) + media.
    const boundary = 'saara-ledger-boundary';
    final body =
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '${json.encode({
          'name': name,
          'parents': ['appDataFolder'],
        })}\r\n'
        '--$boundary\r\n'
        'Content-Type: application/octet-stream\r\n\r\n'
        '$content\r\n'
        '--$boundary--';
    final res = await _http.post(
      Uri.parse('$_driveUpload?uploadType=multipart'),
      headers: {
        ...headers,
        'Content-Type': 'multipart/related; boundary=$boundary',
      },
      body: utf8.encode(body),
    );
    if (res.statusCode >= 400) throw _error(res);
  }

  /// Download a file's raw content from the app-data folder.
  Future<String> downloadAppData(String fileId) async {
    final headers = await _authHeader();
    final res = await _http.get(
      Uri.parse('$_driveFiles/$fileId?alt=media'),
      headers: headers,
    );
    if (res.statusCode >= 400) throw _error(res);
    return utf8.decode(res.bodyBytes);
  }

  void close() => _http.close();
}

/// A file in Saara's Drive app-data folder.
class GDriveAppFile {
  const GDriveAppFile({required this.id, required this.name});
  final String id;
  final String name;
}

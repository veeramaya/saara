import 'package:drift/drift.dart';

import '../converters.dart';

/// §3.6 SaaraGroup — in-app groups only (NOT WhatsApp scraping; see §11).
class SaaraGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get memberLookupKeys =>
      text().map(const StringListConverter())(); // JSON array
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// §3.6 DayLog — one row per day, keyed by date. Drives the morning-brief /
/// evening-review rhythm (§7.3, §7.4). `committed_at` set on "Commit to today".
///
/// Unlike device-local ritual *settings* (times, mandate), the day's own record
/// — the morning **declaration**, the evening **restoration** line, and whether
/// a **card was shared** — is part of your day and **syncs** across devices
/// (§9). `updated_at` drives the last-writer-wins merge.
class DayLogs extends Table {
  // Local calendar date, 'YYYY-MM-DD' (date-only key, no time zone drift).
  TextColumn get date => text()();
  DateTimeColumn get openedAt => dateTime().nullable()();
  DateTimeColumn get committedAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  TextColumn get reflectionCaptureId => text().nullable()();

  /// §7.3 the morning declaration — the word you give for the day, in your own
  /// voice. Synced (LWW), so it reads the same on every device.
  TextColumn get declaration => text().nullable()();

  /// §7.4 the evening restoration line — one honest line to close on. Synced.
  TextColumn get reflection => text().nullable()();

  /// §13 when a Day Card was last shared for this day, so any device can show
  /// "you already shared a card today — revise?" rather than duplicate it.
  DateTimeColumn get cardSharedAt => dateTime().nullable()();

  /// LWW clock for the sync merge.
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {date};
}

/// §3.6 HealthSnapshot — cached daily pulls (§10). Composite key (date, metric).
class HealthSnapshots extends Table {
  TextColumn get date => text()(); // 'YYYY-MM-DD'
  TextColumn get metric => text()();
  RealColumn get value => real()();

  @override
  Set<Column> get primaryKey => {date, metric};
}

/// §3.6 Settings — key/value store: ai_tier, notif times, storage cap, quality.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// §3.6 ApiCredential — alias into Keystore/Keychain. **Raw keys NEVER in DB**
/// (§1, §3.6, §6 Tier 3). Only the alias to secure storage lives here.
class ApiCredentials extends Table {
  TextColumn get provider => text()();
  TextColumn get keyAlias => text()();

  @override
  Set<Column> get primaryKey => {provider};
}

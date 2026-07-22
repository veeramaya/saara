import 'package:drift/drift.dart';

import '../../domain/enums.dart';

/// §3.4 Capture (unified system) — text/audio/video attached to a task, day,
/// week, or area. Limits (§16): video ≤ 180 s, audio ≤ 600 s. Media lives in
/// local encrypted storage; thumbnails/metadata stay local even when archived.
class Captures extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<CaptureType>()();
  TextColumn get mediaPath => text().nullable()(); // local encrypted path
  TextColumn get textContent => text().nullable()();
  TextColumn get caption => text().nullable()();
  IntColumn get durationSec => integer().nullable()(); // video ≤180, audio ≤600
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  TextColumn get attachedType => textEnum<AttachedType>()();
  // day: 'YYYY-MM-DD', week: 'YYYY-Www', else the entity id.
  TextColumn get attachedId => text()();

  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get archiveUri => text().nullable()(); // user's Drive/iCloud ref
  TextColumn get thumbnailPath => text().nullable()(); // kept local

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

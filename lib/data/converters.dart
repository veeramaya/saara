import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a `List<int>` (e.g. Task.reminder_offsets `[-15,-60]`, §3.3) as a
/// JSON text column. NULL column ⇒ null list (no per-task reminder, the default).
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) => (json.decode(fromDb) as List).cast<int>();

  @override
  String toSql(List<int> value) => json.encode(value);
}

/// Stores a `List<String>` (e.g. SaaraGroup.member_lookup_keys, §3.6) as JSON.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (json.decode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => json.encode(value);
}

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/services/reset_service.dart';

/// §1.1 "Reset local data" must genuinely leave nothing behind — a reset that
/// half-works is worse than none, because the user believes they started clean.
/// It must also leave the app usable, not an empty shell.
void main() {
  late AppDatabase db;
  late ResetService reset;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    reset = ResetService(db);
  });
  tearDown(() async => db.close());

  Future<void> seedUserData() async {
    final now = DateTime(2026, 7, 22, 9);
    await db.taskDao.insertTask(
      TasksCompanion.insert(
        id: 't1',
        title: 'Morning walk',
        scheduledStart: Value(now),
        createdAt: now,
        updatedAt: now,
      ),
    );
    // A ledger entry — the local-only history the warning calls out.
    await db
        .into(db.taskTransitions)
        .insert(
          TaskTransitionsCompanion.insert(
            id: 'tr1',
            taskId: 't1',
            toStatus: TaskStatus.started,
            at: now,
          ),
        );
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(key: 'google_autosync', value: Value('on')),
        );
  }

  test('every trace of user data is gone', () async {
    await seedUserData();
    expect(await db.taskDao.allTasks(), isNotEmpty);

    await reset.wipeLocalData();

    expect(await db.taskDao.allTasks(), isEmpty);
    expect(await db.taskDao.deletedTasks(), isEmpty, reason: 'trash too');
    expect(
      await db.select(db.taskTransitions).get(),
      isEmpty,
      reason: 'the integrity ledger is local-only and must be cleared',
    );
    expect(
      await db.select(db.settings).get(),
      isEmpty,
      reason: 'settings, incl. the Google connection flag',
    );
  });

  test('the app is left usable, with starter areas restored', () async {
    await seedUserData();
    await reset.wipeLocalData();

    final areas = await db.areaDao.activeAreas();
    expect(
      areas,
      isNotEmpty,
      reason: 'a reset device should open ready to use, not blank',
    );
  });

  test('running it twice is safe', () async {
    await seedUserData();
    await reset.wipeLocalData();
    await reset.wipeLocalData();

    expect(await db.taskDao.allTasks(), isEmpty);
    expect(
      await db.areaDao.activeAreas(),
      isNotEmpty,
      reason: 'the second pass must not duplicate the starter areas',
    );
  });
}

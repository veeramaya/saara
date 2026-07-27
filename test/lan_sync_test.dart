import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saara/data/database.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/services/app_settings.dart';
import 'package:saara/services/ledger_sync_service.dart';
import 'package:saara/services/lan_sync.dart';

/// §9 Wi-Fi (QR) sync — the transport, exercised over loopback so the whole
/// exchange is proven without two physical devices. The server binds every
/// interface, so a client hitting 127.0.0.1 goes through the real socket path.
void main() {
  late AppDatabase deviceA;
  late AppDatabase deviceB;
  final t0 = DateTime(2026, 7, 27, 9);

  setUp(() {
    deviceA = AppDatabase.forTesting(NativeDatabase.memory());
    deviceB = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await deviceA.close();
    await deviceB.close();
  });

  Future<void> addTask(AppDatabase db, String id, String title) => db
      .into(db.tasks)
      .insert(
        TasksCompanion.insert(
          id: id,
          title: title,
          publicationState: const Value(PublicationState.released),
          createdAt: t0,
          updatedAt: t0,
        ),
      );

  // The host binds anyIPv4; talk to it over loopback so the test never depends
  // on the machine's LAN address being reachable.
  LanPairing loopback(LanPairing p) =>
      LanPairing(host: '127.0.0.1', port: p.port, token: p.token, name: p.name);

  test('one scan merges both devices in a single round-trip', () async {
    await addTask(deviceA, 'a1', 'From A');
    await addTask(deviceB, 'b1', 'From B');

    final server = LanSyncServer(
      LedgerSyncService(deviceA),
      AppSettings(deviceA),
    );
    final pairing = await server.start();
    final client = LanSyncClient(
      LedgerSyncService(deviceB),
      AppSettings(deviceB),
    );

    final result = await client.syncWith(loopback(pairing));

    // B pulled A's task (in the response) and A pulled B's (from the request).
    expect(await deviceB.taskDao.findById('a1'), isNotNull);
    expect(await deviceA.taskDao.findById('b1'), isNotNull);
    expect(result.merged.tasks, greaterThanOrEqualTo(1));

    await server.stop();
  });

  test('a wrong token is refused', () async {
    await addTask(deviceA, 'a1', 'From A');
    final server = LanSyncServer(
      LedgerSyncService(deviceA),
      AppSettings(deviceA),
    );
    final pairing = await server.start();
    final bad = LanPairing(
      host: '127.0.0.1',
      port: pairing.port,
      token: 'not-the-real-token',
      name: pairing.name,
    );
    final client = LanSyncClient(
      LedgerSyncService(deviceB),
      AppSettings(deviceB),
    );

    await expectLater(client.syncWith(bad), throwsA(isA<HttpException>()));
    // Nothing crossed.
    expect(await deviceA.taskDao.findById('a1'), isNotNull);
    await server.stop();
  });

  test('pairing payload round-trips through the QR encoding', () {
    const p = LanPairing(
      host: '192.168.1.5',
      port: 54321,
      token: 'abc123',
      name: 'Desktop',
    );
    final back = LanPairing.tryDecode(p.encode());
    expect(back, isNotNull);
    expect(back!.host, '192.168.1.5');
    expect(back.port, 54321);
    expect(back.token, 'abc123');
    expect(back.name, 'Desktop');

    expect(LanPairing.tryDecode('not a qr'), isNull);
    expect(LanPairing.tryDecode('{"v":2,"h":"x","p":1,"t":"y"}'), isNull);
  });
}

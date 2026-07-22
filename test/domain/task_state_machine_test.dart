import 'package:flutter_test/flutter_test.dart';
import 'package:saara/domain/enums.dart';
import 'package:saara/domain/task_state_machine.dart';

/// Validates the §4 transition matrix via [TaskStateMachine.canTransition],
/// which is pure (no Drift-generated types) and so runs without build_runner.
/// Full outcome tests (completed timing, reschedule spawn, missed guard) live in
/// an integration test against an in-memory DB once codegen has run.
void main() {
  final m = TaskStateMachine();

  group('legal transitions (§4)', () {
    test('created → started', () {
      expect(m.canTransition(TaskStatus.created, TaskStatus.started), isTrue);
    });
    test('started → in_progress', () {
      expect(
        m.canTransition(TaskStatus.started, TaskStatus.inProgress),
        isTrue,
      );
    });
    test('in_progress → completed', () {
      expect(
        m.canTransition(TaskStatus.inProgress, TaskStatus.completed),
        isTrue,
      );
    });
    test('open states → missed / rejected / rescheduled', () {
      for (final from in [
        TaskStatus.created,
        TaskStatus.started,
        TaskStatus.inProgress,
      ]) {
        expect(m.canTransition(from, TaskStatus.missed), isTrue);
        expect(m.canTransition(from, TaskStatus.rejected), isTrue);
        expect(m.canTransition(from, TaskStatus.rescheduled), isTrue);
      }
    });
  });

  group('terminal states have no forward transitions (§4)', () {
    for (final terminal in [TaskStatus.rejected, TaskStatus.rescheduled]) {
      test('${terminal.name} is terminal', () {
        for (final to in TaskStatus.values) {
          expect(
            m.canTransition(terminal, to),
            isFalse,
            reason: '${terminal.name} → ${to.name} must be illegal',
          );
        }
      });
    }
  });

  group('completed / missed are reversible (§4 reopen)', () {
    // An accidental one-tap check-off must not be a one-way door. Reopening is
    // *recorded* as a transition, so the ledger stays honest — the completion
    // is never silently erased.
    for (final from in [TaskStatus.completed, TaskStatus.missed]) {
      test('${from.name} can reopen to started', () {
        expect(m.canTransition(from, TaskStatus.started), isTrue);
      });

      test('${from.name} allows nothing else', () {
        for (final to in TaskStatus.values) {
          if (to == TaskStatus.started) continue;
          expect(
            m.canTransition(from, to),
            isFalse,
            reason: '${from.name} → ${to.name} must stay illegal',
          );
        }
      });
    }

    // The *outcome* of reopening (completion stamps cleared, ledger row
    // written) is asserted in test/task_crud_sync_test.dart, which runs against
    // a real database. This file stays free of Drift types on purpose.
  });

  test('completed → started IS allowed (reopen, §4)', () {
    // Deliberately reversed from the original rule: an accidental check-off
    // must be undoable. The move is recorded in the ledger, so honesty is kept
    // by *visibility*, not by making completion irreversible.
    expect(m.canTransition(TaskStatus.completed, TaskStatus.started), isTrue);
  });

  test('rejected stays irreversible', () {
    expect(m.canTransition(TaskStatus.rejected, TaskStatus.started), isFalse);
  });
}

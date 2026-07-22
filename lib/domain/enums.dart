/// Domain enums shared across the Drift schema (§3) and the task state
/// machine (§4). Stored as text in SQLite (see `textEnum` columns in
/// `data/tables/*`), so **do not reorder or rename** existing values without a
/// migration — the enum *name* is the persisted value.
library;

/// §3.1 Area.base_category — drives parser keywords, health verification
/// mapping, and report grouping.
enum BaseCategory { health, family, finance, work, relationships, custom }

/// §4.1a whether a commitment has been *given*. Orthogonal to [TaskStatus],
/// which tracks what happened to it afterwards.
///
/// A **draft** is thinking out loud: it travels with the ledger to your other
/// devices, but it is not pushed to Google and it does not count in reporting.
/// **Releasing is giving your word** — from then on it syncs everywhere, counts,
/// and its past cannot be deleted (only its future).
enum PublicationState { draft, released }

/// §3.3 what a ledger entry records. The ledger is append-only: entries are
/// never edited or removed, so a mistake is answered with a `corrected` entry
/// rather than a rewrite.
enum LedgerEventKind {
  /// The task or occurrence came into existence (still a draft).
  created,

  /// The moment the user gave their word — worth recording in its own right,
  /// since the gap between committing and acting is itself informative.
  released,

  /// A move through the §4 lifecycle: started, completed, missed, rejected…
  statusChange,

  /// Removed going forward. The past it already accrued stays (§4.2).
  deleted,

  /// A correction to an earlier classification — an adjusting entry, never an
  /// erasure (§4.3).
  corrected,
}

/// §3.2 MeasurableResult.metric_type
enum MetricType {
  count,
  durationMin,
  boolean,
  numeric,
  healthSteps,
  healthActiveMin,
  healthSleepHr,
  healthWeight,
  taskCompletionPct,
  currency, // §3.2 money as a measurable — a target amount, scored like any number
}

/// §3.2 comparator
enum Comparator { gte, lte, eq }

/// §3.2 cadence
enum Cadence { daily, weekly, monthly }

/// §3.2 verification
enum Verification { healthSource, taskLogs, manualLog }

/// §3.3 / §4 Task.status. The full lifecycle; transitions are validated by
/// [TaskStateMachine] and every change writes a TaskTransition row (§3.3).
enum TaskStatus {
  created,
  started,
  inProgress,
  completed,
  missed,
  rejected,
  rescheduled,
}

/// §3.3 meeting_provider
enum MeetingProvider { zoom, teams, meet, webex, other }

/// §3.3 Task.source. `fileImport` extends the PRD list to record tasks brought
/// in via the offline spreadsheet migration (replaces the Todoist path for now).
enum TaskSource {
  manual,
  conversation,
  shareTarget,
  gcalSync,
  todoistImport,
  fileImport,
  gcalEvent, // §9 imported from Google Calendar events
}

/// §3.3 whether a row is a to-do (syncs with Google Tasks) or a time-blocked
/// calendar event (syncs two-way with Google Calendar). Legacy null rows are
/// treated as tasks. Both are commitments; events are a different nature.
enum TaskKind { task, event }

/// §3.4 Capture.type
enum CaptureType { text, audio, video, image }

/// §3.4 Capture.attached_type
enum AttachedType { task, day, week, area }

/// §3.5 CommittedListener.channel
enum ListenerChannel { email, whatsappShare, smsShare }

/// §3.5 CommittedListener.scope
enum ListenerScope { all, area, task }

/// §3.5 CommittedListener.frequency
enum ListenerFrequency { weekly, daily, onMissEscalation }

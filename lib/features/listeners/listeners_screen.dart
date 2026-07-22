import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../domain/listener_report.dart';
import '../../domain/reliability.dart';
import '../../providers.dart';
import 'add_listener_screen.dart';

/// §7.7 / §13 Committed listeners — add people, preview a ledger-generated
/// report, and send it through the user's own apps (share sheet). Gmail-send
/// delivery (from the user's own address) arrives with the OAuth work.
class ListenersScreen extends ConsumerWidget {
  const ListenersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listenersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Committed listeners')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (listeners) {
          if (listeners.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Add someone who will witness you keeping your word.\n'
                  'Reports are generated on your device and sent through your '
                  'own apps.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            children: [for (final l in listeners) _ListenerCard(listener: l)],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add'),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddListenerScreen())),
      ),
    );
  }
}

class _ListenerCard extends ConsumerWidget {
  const _ListenerCard({required this.listener});
  final CommittedListener listener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.hearing)),
            title: Text(listener.displayName),
            subtitle: Text(
              '${listener.channel.name} · ${listener.scope.name} · ${listener.frequency.name}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(ref),
            ),
          ),
          _FeedbackLine(listenerId: listener.id),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Record feedback'),
                  onPressed: () => _recordFeedback(context, ref),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Preview & send'),
                  onPressed: () => _previewAndSend(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Capture the listener's summary-level view of how reliably the user kept
  /// their word to them (§13). Enter/share-based — no backend.
  Future<void> _recordFeedback(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<({int rating, String comment})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FeedbackSheet(name: listener.displayName),
    );
    if (result == null) return;
    final db = ref.read(appDatabaseProvider);
    await db
        .into(db.listenerFeedbacks)
        .insert(
          ListenerFeedbacksCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            listenerId: listener.id,
            ratingPct: result.rating,
            comment: Value(result.comment.isEmpty ? null : result.comment),
            createdAt: DateTime.now(),
          ),
        );
    ref.invalidate(listenerFeedbackForProvider(listener.id));
    ref.invalidate(latestListenerFeedbackProvider);
  }

  Future<void> _delete(WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(
      db.committedListeners,
    )..where((t) => t.id.equals(listener.id))).go();
    ref.invalidate(listenersProvider);
  }

  Future<void> _previewAndSend(BuildContext context, WidgetRef ref) async {
    // Build the report from the ledger (§13), respecting the listener's scope.
    final summary = await ref.read(reportSummaryProvider.future);
    final scores = await ref.read(areaScoresProvider.future);
    final scoped = listener.scope == ListenerScope.area
        ? scores.where((s) => s.area.id == listener.scopeId)
        : scores;
    final text = buildListenerReport(
      forName: listener.displayName,
      summary: summary,
      areas: [
        for (final s in scoped) (name: s.area.displayName, score: s.score),
      ],
      now: DateTime.now(),
    );

    if (!context.mounted) return;
    final send = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report preview'),
        content: SingleChildScrollView(child: Text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.share),
            label: const Text('Send'),
          ),
        ],
      ),
    );
    if (send != true) return;
    if (!context.mounted) return;
    await _deliver(context, ref, text, listener);
  }

  /// Deliver through the user's own apps (§1.4). The OS share sheet only lists
  /// *installed* apps — on Windows that means Outlook/Teams, never WhatsApp or
  /// Gmail — so offer those explicitly via their web handoff URLs, which work
  /// on every platform (and open the native app on mobile).
  Future<void> _deliver(
    BuildContext context,
    WidgetRef ref,
    String text,
    CommittedListener listener,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final to = (listener.email ?? '').trim();
    final looksEmail = to.contains('@');

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('WhatsApp'),
              subtitle: const Text('Opens WhatsApp with the report ready'),
              onTap: () {
                Navigator.pop(ctx);
                final digits = to.replaceAll(RegExp(r'[^0-9]'), '');
                launchUrl(
                  Uri.parse(
                    'https://wa.me/${looksEmail ? '' : digits}?text=${Uri.encodeComponent(text)}',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Gmail'),
              subtitle: const Text('Opens a Gmail compose window'),
              onTap: () async {
                Navigator.pop(ctx);
                // Compose *as the Google account Saara is signed in with*, so
                // the report doesn't go out from whatever the OS treats as the
                // default mail client (that's how Outlook hijacked it).
                final from = await ref
                    .read(googleSyncServiceProvider)
                    .signedInEmail();
                final user = (from == null || from.isEmpty)
                    ? '0'
                    : Uri.encodeComponent(from);
                launchUrl(
                  Uri.parse(
                    'https://mail.google.com/mail/u/$user/?view=cm&fs=1'
                    '&to=${Uri.encodeComponent(looksEmail ? to : '')}'
                    '&su=${Uri.encodeComponent('Saara report')}'
                    '&body=${Uri.encodeComponent(text)}',
                  ),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy to clipboard'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: text));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Report copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Other apps…'),
              subtitle: const Text('Your device\'s share sheet'),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(text, subject: 'Saara report');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// A Saara suggestion from the gap between self-effectiveness and how a listener
/// rates you (§13). Positive gap = you rate yourself higher than they do.
String listenerGapSuggestion(double selfPct, int listenerPct) {
  final gap = selfPct - listenerPct;
  if (gap >= 15) {
    return 'They experience you as less reliable than you feel. Renegotiate the '
        'commitment, or add a reminder so it lands for them too.';
  }
  if (gap <= -15) {
    return 'They trust you more than you credit yourself — you can commit a '
        'little bigger here.';
  }
  return 'You and your listener see it the same way — keep it up.';
}

/// The listener's latest rating shown beside the user's own score, with the gap
/// and a suggestion (§13 relational integrity).
class _FeedbackLine extends ConsumerWidget {
  const _FeedbackLine({required this.listenerId});
  final String listenerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fb = ref.watch(listenerFeedbackForProvider(listenerId));
    final selfAsync = ref.watch(overallEffectivenessProvider);
    return fb.maybeWhen(
      data: (f) {
        if (f == null) return const SizedBox.shrink();
        final self = selfAsync.maybeWhen(data: (v) => v, orElse: () => 0.0);
        final scheme = Theme.of(context).colorScheme;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'You',
                      value: '${self.round()}%',
                      sub: reliabilityLevelName(self),
                    ),
                  ),
                  const Icon(Icons.compare_arrows, size: 18),
                  Expanded(
                    child: _Metric(
                      label: 'Listener',
                      value: '${f.ratingPct}%',
                      sub: reliabilityLevelName(f.ratingPct.toDouble()),
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              if (f.comment != null && f.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '“${f.comment}”',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      listenerGapSuggestion(self, f.ratingPct),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.sub,
    this.alignEnd = false,
  });
  final String label, value, sub;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(sub, style: TextStyle(fontSize: 11, color: scheme.primary)),
      ],
    );
  }
}

/// Bottom sheet to capture a listener's rating (0–100) + comment.
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.name});
  final String name;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  double _rating = 60;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How reliably have you kept your word to ${widget.name}?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_rating.round()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                reliabilityLevelName(_rating),
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: _rating,
            max: 100,
            divisions: 20,
            label: '${_rating.round()}%',
            onChanged: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Their comment (optional)',
              hintText: 'e.g. “On time more often lately.”',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, (
                rating: _rating.round(),
                comment: _comment.text.trim(),
              )),
              child: const Text('Save feedback'),
            ),
          ),
        ],
      ),
    );
  }
}

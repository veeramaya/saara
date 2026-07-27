import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers.dart';
import '../settings/lan_sync_screen.dart';

/// §9 A compact sync-freshness indicator for the app bar of every main screen.
/// Amber "Sync" the moment there are local edits the other device hasn't got;
/// green "In sync" once they match. Tapping opens Wi-Fi sync. It's most load-
/// bearing on the scoring screen: an un-synced device shows a partial score, so
/// the chip tells you at a glance whether what you're reading is the full story.
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref.watch(syncFreshnessProvider).valueOrNull;
    if (fresh == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final unsynced = fresh.unsynced;
    final color = unsynced
        ? (theme.brightness == Brightness.dark
              ? Colors.amber.shade300
              : Colors.amber.shade800)
        : Colors.green.shade600;
    final label = unsynced ? 'Sync' : 'In sync';
    final tip = unsynced
        ? 'You have changes not yet synced to your other device — tap to sync'
        : fresh.lastSync == null
        ? 'In sync'
        : 'In sync · last ${DateFormat('MMM d, h:mm a').format(fresh.lastSync!)}';

    return Tooltip(
      message: tip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LanSyncScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                unsynced ? Icons.sync_problem : Icons.check_circle,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

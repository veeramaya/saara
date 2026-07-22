import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';

/// Add a committed listener (§3.5, §7.7). Contacts picker is Phase 2 — for now
/// the listener is entered manually. Consent confirmation is required (the user
/// affirms the person agreed to receive reports).
class AddListenerScreen extends ConsumerStatefulWidget {
  const AddListenerScreen({super.key});

  @override
  ConsumerState<AddListenerScreen> createState() => _AddListenerScreenState();
}

class _AddListenerScreenState extends ConsumerState<AddListenerScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  ListenerChannel _channel = ListenerChannel.whatsappShare;
  ListenerScope _scope = ListenerScope.all;
  String? _scopeAreaId;
  ListenerFrequency _frequency = ListenerFrequency.weekly;
  bool _consent = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(activeAreasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add committed listener')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ListenerChannel>(
            initialValue: _channel,
            decoration: const InputDecoration(labelText: 'Deliver via'),
            items: const [
              DropdownMenuItem(
                value: ListenerChannel.whatsappShare,
                child: Text('WhatsApp / share sheet'),
              ),
              DropdownMenuItem(
                value: ListenerChannel.smsShare,
                child: Text('SMS / share'),
              ),
              DropdownMenuItem(
                value: ListenerChannel.email,
                child: Text('Email'),
              ),
            ],
            onChanged: (v) => setState(() => _channel = v!),
          ),
          if (_channel == ListenerChannel.email) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<ListenerScope>(
            initialValue: _scope,
            decoration: const InputDecoration(labelText: 'Scope'),
            items: const [
              DropdownMenuItem(
                value: ListenerScope.all,
                child: Text('All areas'),
              ),
              DropdownMenuItem(
                value: ListenerScope.area,
                child: Text('One area'),
              ),
            ],
            onChanged: (v) => setState(() => _scope = v!),
          ),
          if (_scope == ListenerScope.area)
            areasAsync.maybeWhen(
              data: (areas) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: _scopeAreaId,
                  decoration: const InputDecoration(labelText: 'Area'),
                  items: [
                    for (final a in areas)
                      DropdownMenuItem(value: a.id, child: Text(a.displayName)),
                  ],
                  onChanged: (v) => setState(() => _scopeAreaId = v),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ListenerFrequency>(
            initialValue: _frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: const [
              DropdownMenuItem(
                value: ListenerFrequency.weekly,
                child: Text('Weekly'),
              ),
              DropdownMenuItem(
                value: ListenerFrequency.daily,
                child: Text('Daily'),
              ),
              DropdownMenuItem(
                value: ListenerFrequency.onMissEscalation,
                child: Text('On repeated misses'),
              ),
            ],
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            title: const Text('They agreed to receive my reports'),
            subtitle: const Text('Required — you confirm their consent.'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton(onPressed: _save, child: const Text('Save')),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack('Name is required');
      return;
    }
    if (!_consent) {
      _snack('Please confirm they consented to receive reports');
      return;
    }
    if (_scope == ListenerScope.area && _scopeAreaId == null) {
      _snack('Pick an area for the scope');
      return;
    }
    final now = DateTime.now();
    final db = ref.read(appDatabaseProvider);
    await db
        .into(db.committedListeners)
        .insert(
          CommittedListenersCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            contactLookupKey: 'manual',
            displayName: name,
            channel: _channel,
            email: Value(
              _email.text.trim().isEmpty ? null : _email.text.trim(),
            ),
            scope: _scope,
            scopeId: Value(_scope == ListenerScope.area ? _scopeAreaId : null),
            frequency: _frequency,
            consentConfirmedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    ref.invalidate(listenersProvider);
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

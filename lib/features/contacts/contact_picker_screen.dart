import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../services/contacts_service.dart';

/// §11 contact picker — requests read permission just-in-time (§15), lists
/// on-device contacts with a search box, and returns the chosen [SimpleContact].
/// Nothing is uploaded; matching is entirely local.
class ContactPickerScreen extends ConsumerStatefulWidget {
  const ContactPickerScreen({super.key});

  @override
  ConsumerState<ContactPickerScreen> createState() =>
      _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  final _search = TextEditingController();
  Future<List<SimpleContact>>? _future;
  bool _permissionDenied = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(contactsServiceProvider);
    final granted = await service.ensurePermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _permissionDenied = true);
      return;
    }
    setState(() => _future = service.all());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add participant')),
      body: _permissionDenied
          ? _denied()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _search,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search contacts',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<SimpleContact>>(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final all = snap.data!;
                      final filtered = _query.isEmpty
                          ? all
                          : all
                                .where(
                                  (c) => c.name.toLowerCase().contains(_query),
                                )
                                .toList();
                      if (filtered.isEmpty) {
                        return const Center(child: Text('No matches.'));
                      }
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                              ),
                            ),
                            title: Text(c.name),
                            onTap: () => Navigator.of(context).pop(c),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _denied() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.contacts_outlined, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Saara needs contacts access to add participants. Matching stays '
            'on your device — contacts are never uploaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              setState(() => _permissionDenied = false);
              _load();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

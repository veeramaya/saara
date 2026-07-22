import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../domain/enums.dart';
import '../../providers.dart';
import 'area_icons.dart';

/// §3.1 / §20.3 — create a custom area (e.g. "Leadership", "Serving a
/// community", "Family oneness"). Name + an icon and colour from the library.
/// Base category is [BaseCategory.custom]; areas are capped at 10 upstream.
class AddAreaScreen extends ConsumerStatefulWidget {
  const AddAreaScreen({super.key, required this.nextSortOrder});

  final int nextSortOrder;

  @override
  ConsumerState<AddAreaScreen> createState() => _AddAreaScreenState();
}

class _AddAreaScreenState extends ConsumerState<AddAreaScreen> {
  final _name = TextEditingController();
  String _icon = areaIconChoices.keys.first;
  String _color = areaColorChoices.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = areaColor(_color) ?? Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('New area')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(areaIcon(_icon), color: accent, size: 32),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Leadership, Serving a community, Family oneness',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          Text('Icon', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in areaIconChoices.entries)
                _Pickable(
                  selected: _icon == entry.key,
                  accent: accent,
                  onTap: () => setState(() => _icon = entry.key),
                  child: Icon(
                    entry.value,
                    color: _icon == entry.key ? Colors.white : accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Colour', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final hex in areaColorChoices)
                GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: areaColor(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == hex
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: FilledButton(onPressed: _save, child: const Text('Save area')),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final now = DateTime.now();
    await ref
        .read(areaDaoProvider)
        .insertArea(
          AreasCompanion.insert(
            id: ref.read(uuidProvider).v4(),
            baseCategory: BaseCategory.custom,
            displayName: name,
            icon: Value(_icon),
            color: Value(_color),
            sortOrder: Value(widget.nextSortOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
    // activeAreasProvider is a stream — the grid refreshes itself.
    if (mounted) Navigator.of(context).pop();
  }
}

class _Pickable extends StatelessWidget {
  const _Pickable({
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? accent : accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }
}

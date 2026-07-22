import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers.dart';
import '../../services/ai/ai_config.dart';
import '../../services/ai/llm.dart';

/// §6 Tier 3 setup — pick a provider and enter a BYO key. Gemini has a free
/// tier (easiest to test). Keys are stored per-provider in the Keystore only;
/// all calls go device→provider directly (§2).
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  AiProvider _provider = AiProvider.gemini;
  bool _loaded = false;
  bool _showKey = false;
  bool _testing = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final config = await ref.read(aiConfigStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _provider = config.provider;
      _key.text = config.apiKey ?? '';
      _model.text = config.model;
      _loaded = true;
    });
  }

  // Load a provider's saved key/model when the dropdown changes.
  Future<void> _switchProvider(AiProvider p) async {
    await ref.read(aiConfigStoreProvider).selectProvider(p);
    final config = await ref.read(aiConfigStoreProvider).load();
    if (!mounted) return;
    setState(() {
      _provider = p;
      _key.text = config.apiKey ?? '';
      _model.text = config.model;
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Saara AI (your key)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bring your own AI key. It is stored only in this device\'s secure '
            'keystore, and Saara talks to the provider directly — nothing goes '
            'through Realmaya.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AiProvider>(
            initialValue: _provider,
            decoration: const InputDecoration(
              labelText: 'Provider',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final p in AiProvider.values)
                DropdownMenuItem(value: p, child: Text(p.displayName)),
            ],
            onChanged: (p) {
              if (p != null) _switchProvider(p);
            },
          ),
          const SizedBox(height: 8),
          Text(
            _provider.keySource,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('Get a ${_provider.displayName} key'),
              onPressed: () => launchUrl(
                Uri.parse(_provider.keyUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            obscureText: !_showKey,
            maxLines: 1,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: '${_provider.displayName} API key',
              hintText: _provider.keyHint,
              border: const OutlineInputBorder(),
              errorText: _keyLooksShort
                  ? 'Only ${_key.text.trim().length} characters — the full key '
                        'didn\'t paste. Use Paste below.'
                  : null,
              helperText: _key.text.isEmpty
                  ? 'Tip: use the Paste button so the whole key comes in'
                  : '${_key.text.trim().length} characters',
              suffixIcon: IconButton(
                icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility),
                tooltip: _showKey ? 'Hide' : 'Show',
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('Paste'),
                onPressed: _pasteKey,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering, size: 18),
                label: const Text('Test key'),
                onPressed: _testing ? null : _testKey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _model,
            decoration: InputDecoration(
              labelText: 'Model',
              border: const OutlineInputBorder(),
              helperText:
                  'Default: ${_provider.defaultModel}. '
                  'Tap a suggestion or type the exact model id.',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in _provider.suggestedModels)
                ActionChip(
                  label: Text(m),
                  onPressed: () => setState(() => _model.text = m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.checklist, size: 18),
            label: const Text('Check available models'),
            onPressed: _checking ? null : _checkModels,
          ),
          const SizedBox(height: 12),
          Text(
            'You are sharing conversation text with a third-party AI — review '
            'their data settings. Usage is billed to your own account.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _clear, child: const Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  /// A full Anthropic key is ~108 chars; Gemini ~39. Anything well below that
  /// means the paste was truncated (the #1 cause of a 401).
  bool get _keyLooksShort {
    final n = _key.text.trim().length;
    if (n == 0) return false;
    final min = _provider == AiProvider.anthropic ? 90 : 30;
    return n < min;
  }

  /// Paste the ENTIRE clipboard into the key field — avoids partial hand-
  /// selection that leaves a short, rejected key.
  Future<void> _pasteKey() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _snack('Clipboard is empty — copy your key first.');
      return;
    }
    setState(() => _key.text = text);
  }

  /// Validate the entered key/model against the provider with a tiny call, so
  /// the user can confirm it works (and that the whole key pasted) before use.
  Future<void> _testKey() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      _snack('Enter your API key first');
      return;
    }
    setState(() => _testing = true);
    try {
      final model = _model.text.trim().isEmpty
          ? _provider.defaultModel
          : _model.text.trim();
      final cfg = AiConfig(provider: _provider, apiKey: key, model: model);
      await ref
          .read(llmServiceProvider)
          .complete(
            cfg,
            messages: [
              const ChatTurn('user', 'Reply with the single word: OK'),
            ],
          );
      if (mounted) _snack('✓ Key works');
    } on AiException catch (e) {
      if (mounted) _snack('✗ ${e.message}');
    } catch (e) {
      if (mounted) _snack('✗ $e');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  /// Ask the provider which models this key can actually use, then let the user
  /// tap one to select it. This is the definitive fix for a "model not
  /// available" 404 — it turns guesswork into the real list.
  Future<void> _checkModels() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      _snack('Enter your API key first');
      return;
    }
    setState(() => _checking = true);
    try {
      final cfg = AiConfig(
        provider: _provider,
        apiKey: key,
        model: _provider.defaultModel,
      );
      final models = await ref.read(llmServiceProvider).listModels(cfg);
      if (!mounted) return;
      if (models.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No models available'),
            content: const Text(
              'Your key authenticated, but the account has access to zero '
              'models. This almost always means the account has no API '
              'credits yet. Add credits in the provider console, then try '
              'again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${models.length} models available'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Tap one to use it:'),
                ),
                for (final m in models)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(m),
                    onTap: () {
                      setState(() => _model.text = m);
                      Navigator.pop(ctx);
                      _snack('Model set to $m');
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on AiException catch (e) {
      if (mounted) _snack('✗ ${e.message}');
    } catch (e) {
      if (mounted) _snack('✗ $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _save() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      _snack('Enter your API key');
      return;
    }
    await ref
        .read(aiConfigStoreProvider)
        .save(
          provider: _provider,
          apiKey: key,
          // Never save a blank model — fall back to the provider default.
          model: _model.text.trim().isEmpty
              ? _provider.defaultModel
              : _model.text.trim(),
        );
    ref.invalidate(aiConfigProvider);
    if (mounted) {
      _snack('Saved');
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    await ref.read(aiConfigStoreProvider).clear(_provider);
    ref.invalidate(aiConfigProvider);
    if (mounted) {
      _key.clear();
      _snack('Key removed');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

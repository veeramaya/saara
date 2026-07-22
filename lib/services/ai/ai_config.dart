import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'anthropic_client.dart';
import 'gemini_client.dart';
import 'llm.dart';

/// Tier 3 config: chosen provider + that provider's key and model. Keys live
/// only in the Keystore/Keychain (§6), never in the DB or on any server.
class AiConfig {
  const AiConfig({required this.provider, this.apiKey, required this.model});
  final AiProvider provider;
  final String? apiKey;
  final String model;

  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;
}

class AiConfigStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyProvider = 'ai_provider';

  String _keyFor(AiProvider p) => 'aikey_${p.name}';
  String _modelFor(AiProvider p) => 'aimodel_${p.name}';

  /// Loads the config for the currently-selected provider (defaults to Gemini —
  /// it has a free tier, easiest to try).
  Future<AiConfig> load() async {
    final providerName = await _storage.read(key: _keyProvider);
    final provider = AiProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AiProvider.gemini,
    );
    final key = await _storage.read(key: _keyFor(provider));
    final stored =
        await _storage.read(key: _modelFor(provider)) ?? provider.defaultModel;
    // Auto-heal stale `-latest` aliases saved by older builds → dated snapshot.
    final model = provider.normalizeModel(stored);
    if (model != stored) {
      await _storage.write(key: _modelFor(provider), value: model);
    }
    return AiConfig(provider: provider, apiKey: key, model: model);
  }

  Future<void> save({
    required AiProvider provider,
    required String apiKey,
    required String model,
  }) async {
    await _storage.write(key: _keyProvider, value: provider.name);
    await _storage.write(key: _keyFor(provider), value: apiKey.trim());
    final chosen = model.trim().isEmpty ? provider.defaultModel : model.trim();
    await _storage.write(
      key: _modelFor(provider),
      value: provider.normalizeModel(chosen),
    );
  }

  Future<void> selectProvider(AiProvider provider) =>
      _storage.write(key: _keyProvider, value: provider.name);

  Future<void> clear(AiProvider provider) =>
      _storage.delete(key: _keyFor(provider));
}

/// Routes a completion to the right provider client based on [AiConfig].
class LlmService {
  LlmService() : _anthropic = AnthropicClient(), _gemini = GeminiClient();

  final AnthropicClient _anthropic;
  final GeminiClient _gemini;

  Future<String> complete(
    AiConfig config, {
    required List<ChatTurn> messages,
    String? system,
  }) {
    final client = switch (config.provider) {
      AiProvider.anthropic => _anthropic,
      AiProvider.gemini => _gemini,
    };
    return client.complete(
      apiKey: config.apiKey!,
      model: config.model,
      messages: messages,
      system: system,
    );
  }

  /// Extract task fields from an image (§11) — Gemini or Anthropic (both do
  /// vision), whichever key the user has configured.
  Future<String> extractFromImage(
    AiConfig config, {
    required List<int> imageBytes,
    required String mimeType,
    required String prompt,
  }) {
    return switch (config.provider) {
      AiProvider.gemini => _gemini.extractFromImage(
        apiKey: config.apiKey!,
        model: config.model,
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType,
      ),
      AiProvider.anthropic => _anthropic.extractFromImage(
        apiKey: config.apiKey!,
        model: config.model,
        prompt: prompt,
        imageBytes: imageBytes,
        mimeType: mimeType,
      ),
    };
  }

  /// Structure a plain-text message (e.g. pasted from WhatsApp) into task JSON
  /// (§11). Works with either provider via the normal chat endpoint.
  Future<String> extractFromText(AiConfig config, {required String prompt}) {
    final client = switch (config.provider) {
      AiProvider.anthropic => _anthropic as LlmClient,
      AiProvider.gemini => _gemini as LlmClient,
    };
    return client.complete(
      apiKey: config.apiKey!,
      model: config.model,
      messages: [ChatTurn('user', prompt)],
    );
  }

  /// [extractFromText], but self-healing: if the configured model isn't
  /// available to the key (the #1 confusing failure), transparently ask the
  /// account which models it *can* use, switch to a sensible one, and retry
  /// once. Returns the text plus, if it changed, the model that actually
  /// worked so the caller can persist it (§6).
  Future<({String text, String? usedModel})> extractFromTextHealing(
    AiConfig config, {
    required String prompt,
  }) async {
    try {
      final text = await extractFromText(config, prompt: prompt);
      return (text: text, usedModel: null);
    } on AiException catch (e) {
      if (!_looksModelNotFound(e)) rethrow;
      // Ask the key what it can actually use. Propagates auth errors / empties
      // (no models = no access → the original message is the right one).
      final models = await listModels(config);
      final pick = _pickModel(config.provider, models);
      if (pick == null || pick == config.model) rethrow;
      final healed = AiConfig(
        provider: config.provider,
        apiKey: config.apiKey,
        model: pick,
      );
      final text = await extractFromText(healed, prompt: prompt);
      return (text: text, usedModel: pick);
    }
  }

  bool _looksModelNotFound(AiException e) =>
      e.statusCode == 404 ||
      e.message.contains('available to your API key') ||
      e.message.toLowerCase().startsWith('model:');

  /// A sensible model from the account's real list — cheapest capable first.
  String? _pickModel(AiProvider provider, List<String> models) {
    if (models.isEmpty) return null;
    final prefs = switch (provider) {
      AiProvider.anthropic => const ['haiku', 'sonnet'],
      AiProvider.gemini => const ['flash', 'pro'],
    };
    for (final want in prefs) {
      final hit = models.where((m) => m.toLowerCase().contains(want));
      if (hit.isNotEmpty) return hit.first;
    }
    return models.first;
  }

  /// Lists the models the given key can actually use (§6 diagnostic).
  Future<List<String>> listModels(AiConfig config) {
    return switch (config.provider) {
      AiProvider.anthropic => _anthropic.listModels(apiKey: config.apiKey!),
      AiProvider.gemini => _gemini.listModels(apiKey: config.apiKey!),
    };
  }

  void close() {
    _anthropic.close();
    _gemini.close();
  }
}

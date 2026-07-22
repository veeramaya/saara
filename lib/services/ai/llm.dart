/// Shared Tier-3 BYO-key AI types (§6). The app supports more than one provider
/// so users can bring whichever key they have — Google Gemini has a free tier,
/// which is the easiest way to try the agent.
library;

enum AiProvider { gemini, anthropic }

extension AiProviderInfo on AiProvider {
  String get displayName => switch (this) {
    AiProvider.gemini => 'Google Gemini',
    AiProvider.anthropic => 'Anthropic Claude',
  };

  String get defaultModel => switch (this) {
    AiProvider.gemini => 'gemini-2.5-flash',
    // Dated snapshot, not the `-latest` alias: aliases 404 with
    // `not_found_error` on many accounts/regions. Cheap + reliable.
    AiProvider.anthropic => 'claude-3-5-haiku-20241022',
  };

  /// Known-good *public API* model names to pick from (avoids the 404s that a
  /// wrong id causes). Anthropic entries are **dated snapshots** — the
  /// `-latest` aliases are convenience pointers that don't resolve everywhere.
  List<String> get suggestedModels => switch (this) {
    AiProvider.gemini => const [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
    ],
    AiProvider.anthropic => const [
      'claude-3-5-haiku-20241022',
      'claude-3-5-sonnet-20241022',
      'claude-sonnet-4-20250514',
      'claude-opus-4-20250514',
      'claude-3-opus-20240229',
    ],
  };

  /// Auto-heal a stored model id: map Anthropic `-latest` aliases (which 404 on
  /// many accounts) to their equivalent dated snapshot. No-op otherwise.
  String normalizeModel(String model) {
    if (this != AiProvider.anthropic) return model;
    const aliasMap = {
      'claude-3-5-haiku-latest': 'claude-3-5-haiku-20241022',
      'claude-3-5-sonnet-latest': 'claude-3-5-sonnet-20241022',
      'claude-3-opus-latest': 'claude-3-opus-20240229',
      'claude-3-haiku-latest': 'claude-3-haiku-20240307',
      'claude-3-sonnet-latest': 'claude-3-sonnet-20240229',
    };
    return aliasMap[model.trim()] ?? model;
  }

  String get keyHint => switch (this) {
    AiProvider.gemini => 'AIza…',
    AiProvider.anthropic => 'sk-ant-…',
  };

  /// Where to get a key.
  String get keySource => switch (this) {
    AiProvider.gemini =>
      'Free tier — sign in with your Google account, click "Create API key", copy it here.',
    AiProvider.anthropic => 'Paid — create a key in the console, copy it here.',
  };

  /// The page that mints an API key for this provider.
  String get keyUrl => switch (this) {
    AiProvider.gemini => 'https://aistudio.google.com/apikey',
    AiProvider.anthropic => 'https://console.anthropic.com/settings/keys',
  };
}

class AiException implements Exception {
  AiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

/// One chat turn. `role` is 'user' or 'assistant' (providers map as needed).
class ChatTurn {
  const ChatTurn(this.role, this.text);
  final String role;
  final String text;
}

/// A minimal provider client: turn a conversation into an assistant reply.
abstract class LlmClient {
  Future<String> complete({
    required String apiKey,
    required String model,
    required List<ChatTurn> messages,
    String? system,
    int maxTokens = 8192,
  });

  void close();
}

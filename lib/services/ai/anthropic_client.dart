import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm.dart';

/// Anthropic Messages API client (§6 Tier 3). Raw HTTP — no official Dart SDK.
/// Calls device→provider directly with the user's own key.
class AnthropicClient implements LlmClient {
  AnthropicClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _endpoint = 'https://api.anthropic.com/v1/messages';

  @override
  Future<String> complete({
    required String apiKey,
    required String model,
    required List<ChatTurn> messages,
    String? system,
    int maxTokens = 8192,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'messages': [
        for (final m in messages) {'role': m.role, 'content': m.text},
      ],
      if (system != null && system.isNotEmpty) 'system': system,
    };

    http.Response res;
    try {
      res = await _http.post(
        Uri.parse(_endpoint),
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode(body),
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }

    if (res.statusCode == 401) {
      throw AiException(
        'API key rejected (401). Check your key in Settings.',
        statusCode: 401,
      );
    }
    if (res.statusCode == 429) {
      throw AiException(
        'Rate limited (429). Try again in a moment.',
        statusCode: 429,
      );
    }
    if (res.statusCode >= 400) {
      throw _apiError(res, model);
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    if (data['stop_reason'] == 'refusal') {
      throw AiException('The model declined to respond to that.');
    }
    final content = (data['content'] as List?) ?? const [];
    final buffer = StringBuffer();
    for (final block in content) {
      if (block is Map && block['type'] == 'text') buffer.write(block['text']);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) throw AiException('Empty response from the model.');
    return text;
  }

  /// Multimodal extraction (§6/§11): image + prompt → text (JSON). Claude
  /// supports vision, so image capture works with an Anthropic key too.
  Future<String> extractFromImage({
    required String apiKey,
    required String model,
    required String prompt,
    required List<int> imageBytes,
    required String mimeType,
    int maxTokens = 2048,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    };
    http.Response res;
    try {
      res = await _http.post(
        Uri.parse(_endpoint),
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode(body),
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }
    if (res.statusCode >= 400) {
      throw _apiError(res, model);
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final content = (data['content'] as List?) ?? const [];
    final buffer = StringBuffer();
    for (final block in content) {
      if (block is Map && block['type'] == 'text') buffer.write(block['text']);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) throw AiException('Empty response from the model.');
    return text;
  }

  /// Turns an Anthropic error body into a human, actionable message. Anthropic's
  /// `not_found_error` body is literally `model: <name>`, which is useless on
  /// its own — surface what the user should actually do.
  AiException _apiError(http.Response res, String model) {
    String? apiMsg;
    String? type;
    try {
      final err = json.decode(res.body) as Map<String, dynamic>;
      final e = err['error'] as Map?;
      apiMsg = e?['message']?.toString();
      type = e?['type']?.toString();
    } catch (_) {}
    if (res.statusCode == 404 ||
        type == 'not_found_error' ||
        (apiMsg != null && apiMsg.startsWith('model:'))) {
      return AiException(
        "Model '$model' isn't available to your API key. Open Settings → AI and "
        'pick another model (e.g. claude-3-5-haiku-20241022), and confirm your '
        'key has API credits (a Claude.ai plan is separate from API billing).',
        statusCode: res.statusCode,
      );
    }
    return AiException(
      apiMsg ?? 'Error ${res.statusCode}',
      statusCode: res.statusCode,
    );
  }

  /// Lists the models this key can actually use (§6 diagnostic). Definitively
  /// separates "wrong model name" from "key/account has no model access".
  /// Returns model ids, newest first. Throws [AiException] on auth failure.
  Future<List<String>> listModels({required String apiKey}) async {
    http.Response res;
    try {
      res = await _http.get(
        Uri.parse('https://api.anthropic.com/v1/models?limit=100'),
        headers: {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }
    if (res.statusCode == 401) {
      throw AiException(
        'API key rejected (401). Check your key.',
        statusCode: 401,
      );
    }
    if (res.statusCode >= 400) {
      throw _apiError(res, '');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final list = (data['data'] as List?) ?? const [];
    return [
      for (final m in list)
        if (m is Map && m['id'] != null) m['id'].toString(),
    ];
  }

  @override
  void close() => _http.close();
}

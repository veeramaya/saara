import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm.dart';

/// Google Gemini (Generative Language API) client (§6 Tier 3). Raw HTTP.
/// Free-tier keys from Google AI Studio work here. Device→provider directly.
class GeminiClient implements LlmClient {
  GeminiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  Future<String> complete({
    required String apiKey,
    required String model,
    required List<ChatTurn> messages,
    String? system,
    int maxTokens = 8192,
  }) async {
    final url = Uri.parse('$_base/$model:generateContent');
    final body = <String, dynamic>{
      if (system != null && system.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': system},
          ],
        },
      // Gemini roles are 'user' and 'model'.
      'contents': [
        for (final m in messages)
          {
            'role': m.role == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m.text},
            ],
          },
      ],
      'generationConfig': {'maxOutputTokens': maxTokens},
    };

    http.Response res;
    try {
      res = await _http.post(
        url,
        headers: {'content-type': 'application/json', 'x-goog-api-key': apiKey},
        body: json.encode(body),
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }

    if (res.statusCode >= 400) {
      var msg = 'Error ${res.statusCode}';
      try {
        final err = json.decode(res.body) as Map<String, dynamic>;
        msg = (err['error'] as Map?)?['message']?.toString() ?? msg;
      } catch (_) {}
      if (res.statusCode == 400 && msg.toLowerCase().contains('api key')) {
        msg = 'API key not valid. Check your key in Settings.';
      }
      if (res.statusCode == 429) {
        // Preserve Google's detail — it says WHICH quota (per-minute vs
        // per-day, free-tier vs project) and often that free tier needs
        // billing enabled. Masking it hid the real cause.
        final low = msg.toLowerCase();
        final freeTier = low.contains('free') || low.contains('billing');
        msg =
            'Quota exceeded (429). $msg'
            '${freeTier ? '\n\nThe free tier for this model may need billing '
                      'enabled on the Google Cloud project, or try a different model '
                      '(e.g. gemini-2.0-flash) via "Check available models".' : ''}';
      }
      throw AiException(msg, statusCode: res.statusCode);
    }

    final data = json.decode(res.body) as Map<String, dynamic>;
    final candidates = (data['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) {
      final feedback = data['promptFeedback'] as Map?;
      final blocked = feedback?['blockReason'];
      if (blocked != null) {
        throw AiException('Blocked by the provider ($blocked).');
      }
      throw AiException('Empty response from the model.');
    }
    final parts =
        ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ??
        const [];
    final buffer = StringBuffer();
    for (final p in parts) {
      if (p is Map && p['text'] != null) buffer.write(p['text']);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw AiException('Empty response (the model may have been cut off).');
    }
    return text;
  }

  /// Multimodal extraction (§6/§11): send an image + a prompt, return the
  /// model's text (JSON when [jsonOut] is set). Used to read a photo/screenshot
  /// of notes into task fields — an *optional* smart layer over manual capture.
  Future<String> extractFromImage({
    required String apiKey,
    required String model,
    required String prompt,
    required List<int> imageBytes,
    required String mimeType,
    bool jsonOut = true,
    int maxTokens = 2048,
  }) async {
    final url = Uri.parse('$_base/$model:generateContent');
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
            {
              'inlineData': {
                'mimeType': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        if (jsonOut) 'responseMimeType': 'application/json',
      },
    };

    http.Response res;
    try {
      res = await _http.post(
        url,
        headers: {'content-type': 'application/json', 'x-goog-api-key': apiKey},
        body: json.encode(body),
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }
    if (res.statusCode >= 400) {
      var msg = 'Error ${res.statusCode}';
      try {
        final err = json.decode(res.body) as Map<String, dynamic>;
        msg = (err['error'] as Map?)?['message']?.toString() ?? msg;
      } catch (_) {}
      throw AiException(msg, statusCode: res.statusCode);
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final candidates = (data['candidates'] as List?) ?? const [];
    if (candidates.isEmpty) throw AiException('Empty response from the model.');
    final parts =
        ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ??
        const [];
    final buffer = StringBuffer();
    for (final p in parts) {
      if (p is Map && p['text'] != null) buffer.write(p['text']);
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) throw AiException('Empty response from the model.');
    return text;
  }

  /// Lists models this key can call `generateContent` on (§6 diagnostic).
  /// Returns bare model ids (e.g. `gemini-2.5-flash`).
  Future<List<String>> listModels({required String apiKey}) async {
    http.Response res;
    try {
      res = await _http.get(
        Uri.parse('$_base?pageSize=200'),
        headers: {'x-goog-api-key': apiKey},
      );
    } catch (e) {
      throw AiException('Network error: $e');
    }
    if (res.statusCode >= 400) {
      var msg = 'Error ${res.statusCode}';
      try {
        final err = json.decode(res.body) as Map<String, dynamic>;
        msg = (err['error'] as Map?)?['message']?.toString() ?? msg;
      } catch (_) {}
      if (res.statusCode == 400 && msg.toLowerCase().contains('api key')) {
        msg = 'API key not valid. Check your key.';
      }
      throw AiException(msg, statusCode: res.statusCode);
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final list = (data['models'] as List?) ?? const [];
    return [
      for (final m in list)
        if (m is Map &&
            (m['supportedGenerationMethods'] as List?)?.contains(
                  'generateContent',
                ) ==
                true &&
            m['name'] != null)
          // Strip the "models/" prefix the API returns.
          m['name'].toString().replaceFirst('models/', ''),
    ];
  }

  @override
  void close() => _http.close();
}

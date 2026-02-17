import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/providers/base_ai_provider.dart';
import '../../../core/utils/cost_estimator.dart';

class OpenAIProvider implements BaseAIProvider {
  final Dio _dio = Dio();

  @override
  String get id => 'openai';

  @override
  String get name => 'OpenAI';

  @override
  Future<bool> validateKey(String apiKey) async {
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String prompt,
    required List<ChatMessage> history,
    required String model,
    required String apiKey,
  }) async* {
    final messages = [
      ...history.map((m) => {
            'role': m.role.name,
            'content': m.content,
          }),
      {'role': 'user', 'content': prompt},
    ];

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        data: {
          'model': model,
          'messages': messages,
          'stream': true,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        final data = String.fromCharCodes(chunk);
        final lines = data.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final content = line.substring(6).trim();
            if (content == '[DONE]') break;
            // Simplified parsing for brevity, in a real app use jsonDecode
            if (content.contains('"content":"')) {
              final match = RegExp(r'"content":"(.*?)"').firstMatch(content);
              if (match != null) {
                yield match.group(1)!.replaceAll('\\n', '\n');
              }
            }
          }
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  @override
  Future<List<String>> getAvailableModels(String apiKey) async {
    try {
      final response = await _dio.get(
        'https://api.openai.com/v1/models',
        options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
      );
      final List models = response.data['data'];
      return models
          .map((m) => m['id'] as String)
          .where((id) => id.contains('gpt'))
          .toList();
    } catch (_) {
      return ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo'];
    }
  }

  @override
  int estimateTokens(String text) => CostEstimator.estimateTokens(text);

  @override
  double estimateCost(int tokens, String model) =>
      CostEstimator.estimateCost(inputTokens: tokens, outputTokens: 0, model: model);
}

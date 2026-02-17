import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/providers/base_ai_provider.dart';
import '../../../core/utils/cost_estimator.dart';

class GeminiProvider implements BaseAIProvider {
  final Dio _dio = Dio();

  @override
  String get id => 'gemini';

  @override
  String get name => 'Google Gemini';

  @override
  Future<bool> validateKey(String apiKey) async {
    try {
      final response = await _dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
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
    final contents = [
      ...history.map((m) => {
            'role': m.role == MessageRole.user ? 'user' : 'model',
            'parts': [
              {'text': m.content}
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': prompt}
        ]
      },
    ];

    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
        data: {'contents': contents},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream;
      await for (final chunk in stream) {
        final data = utf8.decode(chunk);
        final lines = data.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6);
            final jsonData = jsonDecode(jsonStr);
            final content = jsonData['candidates']?[0]['content']?['parts']?[0]['text'];
            if (content != null) {
              yield content;
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
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final List models = response.data['models'];
      return models
          .map((m) => m['name'].toString().split('/').last)
          .where((name) => name.contains('gemini'))
          .toList();
    } catch (_) {
      return ['gemini-1.5-pro', 'gemini-1.5-flash'];
    }
  }

  @override
  int estimateTokens(String text) => CostEstimator.estimateTokens(text);

  @override
  double estimateCost(int tokens, String model) =>
      CostEstimator.estimateCost(inputTokens: tokens, outputTokens: 0, model: model);
}

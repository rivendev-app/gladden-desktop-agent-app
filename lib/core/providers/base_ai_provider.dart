enum MessageRole { user, assistant, system }

class ChatMessage {
  final String content;
  final MessageRole role;
  final String? model;
  final String? provider;
  final int? estimatedTokens;
  final double? estimatedCost;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    this.model,
    this.provider,
    this.estimatedTokens,
    this.estimatedCost,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

abstract class BaseAIProvider {
  String get id;
  String get name;

  Future<bool> validateKey(String apiKey);
  
  Stream<String> sendMessageStream({
    required String prompt,
    required List<ChatMessage> history,
    required String model,
    required String apiKey,
  });

  Future<List<String>> getAvailableModels(String apiKey);
  
  int estimateTokens(String text);
  double estimateCost(int tokens, String model);
}

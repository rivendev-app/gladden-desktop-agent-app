class ModelPricing {
  final double inputPricePer1k;
  final double outputPricePer1k;

  const ModelPricing(this.inputPricePer1k, this.outputPricePer1k);
}

class CostEstimator {
  static const Map<String, ModelPricing> pricingTable = {
    'gpt-4o': ModelPricing(0.005, 0.015),
    'gpt-4o-mini': ModelPricing(0.00015, 0.0006),
    'gpt-3.5-turbo': ModelPricing(0.0005, 0.0015),
    'gemini-1.5-pro': ModelPricing(0.0035, 0.0105),
    'gemini-1.5-flash': ModelPricing(0.000075, 0.0003),
  };

  static double estimateCost({
    required int inputTokens,
    required int outputTokens,
    required String model,
  }) {
    final pricing = pricingTable[model] ?? pricingTable['gpt-4o-mini']!;
    final inputCost = (inputTokens / 1000) * pricing.inputPricePer1k;
    final outputCost = (outputTokens / 1000) * pricing.outputPricePer1k;
    return inputCost + outputCost;
  }

  // Simple heuristic for token estimation: ~4 chars per token for English
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4).ceil();
  }
}

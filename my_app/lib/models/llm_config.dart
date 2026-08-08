/// Configuration for the external LLM API provider.
class LlmConfig {
  final String provider;
  final String apiKey;
  final String model;
  final double temperature;

  const LlmConfig({
    this.provider = 'OpenRouter',
    this.apiKey = '',
    this.model = 'openai/gpt-4o-mini',
    this.temperature = 0.2,
  });

  bool get hasApiKey => apiKey.isNotEmpty;

  LlmConfig copyWith({
    String? provider,
    String? apiKey,
    String? model,
    double? temperature,
  }) {
    return LlmConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
    );
  }
}

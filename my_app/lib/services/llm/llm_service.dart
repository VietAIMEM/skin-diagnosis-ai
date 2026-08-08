import '../../models/chat_message.dart';

/// Provider abstraction for OpenAI-compatible LLM APIs.
abstract class LlmService {
  Future<String> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String model,
    double temperature,
  });
}

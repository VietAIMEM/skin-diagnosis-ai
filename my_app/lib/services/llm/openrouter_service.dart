import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../models/chat_message.dart';
import '../../utils/error_handler.dart';
import 'llm_service.dart';

/// OpenAI-compatible provider via OpenRouter (or any base URL that uses the
// ignore_for_file: prefer_initializing_formals
/// /chat/completions schema).
class OpenRouterService implements LlmService {
  OpenRouterService({
    required String baseUrl,
    required String apiKey,
    Dio? dio,
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _dio = dio ?? Dio();

  final String _baseUrl;
  final String _apiKey;
  final Dio _dio;

  static const _timeout = Duration(seconds: 90);

  @override
  Future<String> sendMessage({
    required List<ChatMessage> messages,
    required String systemPrompt,
    required String model,
    double temperature = 0.2,
  }) async {
    if (_apiKey.isEmpty) {
      throw const AppException('Please configure your LLM API key in Settings.');
    }

    final payload = {
      'model': model,
      'temperature': temperature,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        for (final m in messages)
          {
            'role': m.role.apiRole,
            'content': _contentFor(m),
          },
      ],
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/chat/completions',
        data: jsonEncode(payload),
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            if (_baseUrl.contains('openrouter.ai'))
              'HTTP-Referer': 'https://skinai.local',
            if (_baseUrl.contains('openrouter.ai'))
              'X-Title': 'SkinAI',
          },
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final data = response.data ?? const <String, dynamic>{};
      return _parseContent(data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  String _contentFor(ChatMessage m) {
    if (m.isImageAnalysis) {
      return '[Image analysis result]\n${m.text}';
    }
    return m.text;
  }

  String _parseContent(Map<String, dynamic> data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw const AppException('Unable to parse the AI response.');
    }
    final message = (choices.first as Map<String, dynamic>?)?['message'];
    final content = message is Map<String, dynamic> ? message['content'] : null;
    if (content == null) {
      throw const AppException('Unable to parse the AI response.');
    }
    return content.toString().trim();
  }

  AppException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return const AppException('Your API key appears to be invalid.');
    }
    if (status == 429) {
      return const AppException(
          'The selected AI provider is temporarily rate-limited.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const AppException('The AI service took too long to respond.');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      if (e.error is SocketException || e.error is HttpException) {
        return const AppException(
            'Internet connection is required for AI chat, but image analysis can still run locally.');
      }
    }
    if (status != null && status >= 500) {
      return const AppException('The AI service is currently unavailable.');
    }
    return const AppException('Unable to reach the AI service.');
  }
}

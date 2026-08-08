import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/llm_config.dart';
import '../models/user_profile.dart';
import '../services/camera/image_service.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/openrouter_service.dart';
import '../services/llm/prompt_builder.dart';
import '../services/onnx/image_preprocessor.dart';
import '../services/onnx/inference_service.dart';
import '../services/onnx/model_manager.dart';
import '../services/storage/chat_database.dart';
import '../services/storage/preferences_service.dart';
import '../services/storage/secure_storage_service.dart';
import '../utils/constants.dart';

// ---- Storage ----

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError('overridden in bootstrap');
});

final chatDatabaseProvider = Provider<ChatDatabase>((ref) {
  return ChatDatabase();
});

// ---- LLM config ----

final llmConfigProvider =
    NotifierProvider<LlmConfigNotifier, LlmConfig>(LlmConfigNotifier.new);

class LlmConfigNotifier extends Notifier<LlmConfig> {
  @override
  LlmConfig build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return LlmConfig(
      apiKey: '',
      model: prefs.llmModel,
      temperature: prefs.llmTemperature,
    );
  }

  Future<void> refreshFromStorage() async {
    final secure = ref.read(secureStorageServiceProvider);
    final prefs = ref.read(preferencesServiceProvider);
    final apiKey = await secure.readApiKey();
    state = state.copyWith(
      apiKey: apiKey ?? '',
      model: prefs.llmModel,
      temperature: prefs.llmTemperature,
    );
  }

  Future<void> save({
    String? apiKey,
    String? model,
    double? temperature,
  }) async {
    final secure = ref.read(secureStorageServiceProvider);
    final prefs = ref.read(preferencesServiceProvider);
    if (apiKey != null) {
      await secure.writeApiKey(apiKey);
    }
    if (model != null) {
      await prefs.setLlmModel(model);
    }
    if (temperature != null) {
      await prefs.setLlmTemperature(temperature);
    }
    state = state.copyWith(
      apiKey: apiKey ?? state.apiKey,
      model: model ?? state.model,
      temperature: temperature ?? state.temperature,
    );
  }
}

// ---- LLM service ----

final llmServiceProvider = Provider<LlmService>((ref) {
  final config = ref.watch(llmConfigProvider);
  return OpenRouterService(
    baseUrl: openRouterBaseUrl,
    apiKey: config.apiKey,
  );
});

final promptBuilderProvider =
    Provider<PromptBuilder>((ref) => const PromptBuilder());

// ---- ONNX ----

final modelManagerProvider = Provider<ModelManager>((ref) => ModelManager());

final imagePreprocessorProvider =
    Provider<ImagePreprocessor>((ref) => const ImagePreprocessor());

final inferenceServiceProvider = Provider<InferenceService>((ref) {
  return InferenceService(
    modelManager: ref.watch(modelManagerProvider),
    preprocessor: ref.watch(imagePreprocessorProvider),
  );
});

// ---- Profile ----

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile>(UserProfileNotifier.new);

class UserProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.profile ?? const UserProfile();
  }

  Future<void> save(UserProfile profile) async {
    await ref.read(preferencesServiceProvider).saveProfile(profile);
    state = profile;
  }
}

// ---- Onboarding ----

final onboardingProvider = Provider<bool>((ref) {
  final prefs = ref.watch(preferencesServiceProvider);
  return prefs.onboardingCompleted;
});

// ---- Model selection ----

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return switch (prefs.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    await ref.read(preferencesServiceProvider).setThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    state = mode;
  }
}

final analysisModelProvider = NotifierProvider<AnalysisModelNotifier, AnalysisModelOption>(
  AnalysisModelNotifier.new,
);

class AnalysisModelNotifier extends Notifier<AnalysisModelOption> {
  @override
  AnalysisModelOption build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return prefs.analysisModelOption;
  }

  Future<void> setOption(AnalysisModelOption option) async {
    final prefs = ref.read(preferencesServiceProvider);
    await prefs.setAnalysisModelOption(switch (option) {
      AnalysisModelOption.smartphone => modelIdSmartphone,
      AnalysisModelOption.baseline => modelIdBaseline,
      AnalysisModelOption.compareBoth => 'compare_both',
    });
    state = option;
  }
}

// ---- Image service ----

final imageServiceProvider =
    Provider<ImageService>((ref) => ImageService(ImagePicker()));

// ---- Chat ----

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final bool isAnalyzing;
  final bool loadingHistory;

  const ChatState({
    required this.messages,
    this.isSending = false,
    this.isAnalyzing = false,
    this.loadingHistory = true,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isAnalyzing,
    bool? loadingHistory,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      loadingHistory: loadingHistory ?? this.loadingHistory,
    );
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    _loadHistory();
    return const ChatState(messages: [], loadingHistory: true);
  }

  Future<void> _loadHistory() async {
    final db = ref.read(chatDatabaseProvider);
    final messages = await db.loadMessages();
    state = ChatState(
      messages: messages.isEmpty
          ? [ChatMessage(role: MessageRole.assistant, text: starterMessage, timestamp: DateTime.now())]
          : messages,
      loadingHistory: false,
    );
  }

  Future<void> clearHistory() async {
    final db = ref.read(chatDatabaseProvider);
    await db.clearAll();
    state = ChatState(
      messages: [
        ChatMessage(role: MessageRole.assistant, text: starterMessage, timestamp: DateTime.now()),
      ],
      loadingHistory: false,
    );
  }

  void addMessage(ChatMessage message) {
    final messages = [...state.messages, message];
    state = state.copyWith(messages: messages);
    ref.read(chatDatabaseProvider).insertMessage(message);
  }

  void updateMessage(ChatMessage message) {
    final messages = [
      for (final m in state.messages) m.id == message.id ? message : m,
    ];
    state = state.copyWith(messages: messages);
    ref.read(chatDatabaseProvider).updateMessage(message);
  }

  void removeMessage(String id) {
    final messages = state.messages.where((m) => m.id != id).toList();
    state = state.copyWith(messages: messages);
    ref.read(chatDatabaseProvider).deleteMessage(id);
  }

  Future<void> sendText(String text) async {
    if (text.trim().isEmpty || state.isSending) return;
    addMessage(ChatMessage(
      role: MessageRole.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    ));

    final config = ref.read(llmConfigProvider);
    if (!config.hasApiKey) {
      addMessage(ChatMessage(
        role: MessageRole.assistant,
        text: 'Please configure your LLM API key in Settings.',
        error: true,
        timestamp: DateTime.now(),
      ));
      return;
    }

    state = state.copyWith(isSending: true);
    await _askLlm();
    state = state.copyWith(isSending: false);
  }

  Future<void> _askLlm({String? extraContext}) async {
    final llm = ref.read(llmServiceProvider);
    final builder = ref.read(promptBuilderProvider);
    final profile = ref.read(userProfileProvider);
    final config = ref.read(llmConfigProvider);

    // Build history, excluding transient loading messages.
    final source = state.messages.where((m) => !m.loading).toList();
    var history = source
        .where((m) =>
            m.role == MessageRole.user ||
            m.role == MessageRole.assistant ||
            (m.role == MessageRole.imageAnalysis && m.text.isNotEmpty))
        .toList();

    if (extraContext != null && extraContext.isNotEmpty) {
      history = [
        ChatMessage(
          role: MessageRole.system,
          text: extraContext,
          timestamp: DateTime.now(),
        ),
        ...history,
      ];
    }

    if (history.length > maxChatHistoryMessages) {
      history = history.sublist(history.length - maxChatHistoryMessages);
    }

    final loadingId = 'loading-${DateTime.now().millisecondsSinceEpoch}';
    addMessage(ChatMessage(
      id: loadingId,
      role: MessageRole.assistant,
      text: '',
      loading: true,
      timestamp: DateTime.now(),
    ));

    try {
      final response = await llm.sendMessage(
        messages: history,
        systemPrompt: builder.buildSystemPrompt(
          profile: profile,
          language: ref.read(preferencesServiceProvider).language,
        ),
        model: config.model,
        temperature: config.temperature,
      );
      removeMessage(loadingId);
      addMessage(ChatMessage(
        role: MessageRole.assistant,
        text: response,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      removeMessage(loadingId);
      addMessage(ChatMessage(
        role: MessageRole.assistant,
        text: e.toString(),
        error: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> analyzeImage(String imagePath, AnalysisModelOption option) async {
    if (state.isAnalyzing) return;

    state = state.copyWith(isAnalyzing: true);
    addMessage(ChatMessage(
      role: MessageRole.user,
      text: 'Analyze this image',
      imagePath: imagePath,
      timestamp: DateTime.now(),
    ));

    final chatId = 'analysis-${DateTime.now().millisecondsSinceEpoch}';
    addMessage(ChatMessage(
      id: chatId,
      role: MessageRole.imageAnalysis,
      text: 'Analyzing image...',
      loading: true,
      timestamp: DateTime.now(),
    ));

    try {
      final inference = ref.read(inferenceServiceProvider);
      final result = await inference.analyze(
        XFile(imagePath),
        option: option,
      );

      final chatMessage = ChatMessage(
        id: chatId,
        role: MessageRole.imageAnalysis,
        text: buildAnalysisText(result),
        imagePath: imagePath,
        diagnosisResult: result.toJson(),
        timestamp: DateTime.now(),
      );
      updateMessage(chatMessage);

      final config = ref.read(llmConfigProvider);
      if (config.hasApiKey) {
        state = state.copyWith(isSending: true);
        final builder = ref.read(promptBuilderProvider);
        await _askLlm(extraContext: builder.buildAnalysisContext(result));
        state = state.copyWith(isSending: false);
      } else {
        addMessage(ChatMessage(
          role: MessageRole.assistant,
          text:
              'AI explanation unavailable. Configure an LLM API key in Settings to get a natural-language explanation.',
          error: true,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      removeMessage(chatId);
      addMessage(ChatMessage(
        role: MessageRole.assistant,
        text: friendlyAnalysisError(e),
        error: true,
        timestamp: DateTime.now(),
      ));
    } finally {
      state = state.copyWith(isAnalyzing: false, isSending: false);
    }
  }
}

String buildAnalysisText(dynamic result) {
  final json = result.toJson();
  final predicted = json['predictedClass'] as String? ?? '';
  final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
  return 'Image Analysis\n'
      'Prediction: $predicted\n'
      'Confidence: ${(confidence * 100).toStringAsFixed(1)}%';
}

String friendlyAnalysisError(Object e) {
  if (e is FormatException) return 'Unable to process this image.';
  if (e is StateError) return 'Unable to load the local analysis model.';
  return 'Image analysis failed.';
}

const starterMessage =
    'Hello! I\'m SkinAI.\n\nI can help you understand the results of an AI-based skin lesion image analysis.\n\nYou can ask me questions or take a photo of a skin lesion to begin an analysis.';

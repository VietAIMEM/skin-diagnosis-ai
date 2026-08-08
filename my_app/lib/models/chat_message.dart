import 'package:uuid/uuid.dart';

enum MessageRole {
  user,
  assistant,
  system,
  imageAnalysis,
}

extension MessageRoleX on MessageRole {
  String get apiRole {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
      case MessageRole.imageAnalysis:
        return 'system';
    }
  }

  String get wireValue {
    switch (this) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
      case MessageRole.imageAnalysis:
        return 'image_analysis';
    }
  }
}

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime timestamp;
  final String? imagePath;
  final Map<String, dynamic>? diagnosisResult;
  final bool error;
  final bool loading;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    String? id,
    this.imagePath,
    this.diagnosisResult,
    this.error = false,
    this.loading = false,
  }) : id = id ?? const Uuid().v4();

  ChatMessage copyWith({
    String? text,
    DateTime? timestamp,
    String? imagePath,
    Map<String, dynamic>? diagnosisResult,
    bool? error,
    bool? loading,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
      error: error ?? this.error,
      loading: loading ?? this.loading,
    );
  }

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isImageAnalysis => role == MessageRole.imageAnalysis;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.wireValue,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      if (imagePath != null) 'imagePath': imagePath,
      if (diagnosisResult != null) 'diagnosisResult': diagnosisResult,
      'error': error,
      'loading': loading,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = MessageRole.values.firstWhere(
      (r) => r.wireValue == json['role'],
      orElse: () => MessageRole.system,
    );
    return ChatMessage(
      id: json['id'] as String?,
      role: role,
      text: json['text'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      diagnosisResult: json['diagnosisResult'] as Map<String, dynamic>?,
      error: json['error'] as bool? ?? false,
      loading: json['loading'] as bool? ?? false,
    );
  }
}

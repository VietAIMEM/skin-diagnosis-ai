import '../../models/diagnosis_result.dart';
import '../../models/user_profile.dart';
import '../../utils/constants.dart';

/// Builds system prompts and structured context for the LLM.
class PromptBuilder {
  const PromptBuilder();

  /// Base system instructions. The LLM is an explanation assistant, not a
  /// diagnostic authority.
  String buildSystemPrompt({
    UserProfile? profile,
    bool hasInternetContext = true,
    String? language,
  }) {
    final buffer = StringBuffer()
      ..writeln('You are an AI assistant that explains the output of a skin '
          'lesion image classification model.')
      ..writeln('')
      ..writeln('You are NOT a doctor and must NOT claim that the user '
          'definitely has a disease.')
      ..writeln('The classification model provides probabilistic predictions only.')
      ..writeln('')
      ..writeln('Your responsibilities:')
      ..writeln('1. Explain the model\'s predicted class in simple language.')
      ..writeln('2. Explain the confidence/probability.')
      ..writeln('3. Mention relevant alternative classes when useful.')
      ..writeln('4. Explain that image classification cannot replace professional '
          'medical examination.')
      ..writeln('5. Avoid definitive diagnosis.')
      ..writeln('6. Recommend professional dermatological evaluation when '
          'appropriate.')
      ..writeln('7. Be concise, calm, and understandable.')
      ..writeln('8. Never invent medical facts that are not supported by the '
          'provided information.')
      ..writeln('9. Do not be alarmed by any result and do not use alarming '
          'language.');

    if (profile != null && !profile.isEmpty) {
      buffer
        ..writeln('')
        ..writeln('User profile:')
        ..writeln(profile.describe());
    }

    if (language != null) {
      buffer
        ..writeln('')
        ..writeln('Language instruction: respond in ${_languageName(language)} '
            'when the user is writing in ${_languageName(language)}.');
    }

    return buffer.toString();
  }

  String _languageName(String language) {
    if (language == 'Vietnamese') return 'Vietnamese';
    return 'English';
  }

  /// Builds the structured image-analysis context block appended to a user
  /// message or injected as a system message.
  String buildAnalysisContext(DiagnosisResult result) {
    final buffer = StringBuffer()
      ..writeln('Image analysis:')
      ..writeln('Model: ${result.modelId}')
      ..writeln('Prediction: ${result.predictedClass}')
      ..writeln('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%')
      ..writeln('Class probabilities:');

    for (final entry in result.orderedProbabilities.entries) {
      buffer.writeln(
        '  ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}%',
      );
    }

    return buffer.toString();
  }

  /// Human-readable JSON-ish string used for the diagnosis card and chat text.
  String buildStructuredResultText(DiagnosisResult result) {
    final probs = result.orderedProbabilities.entries
        .map((e) => '"${e.key}": ${e.value.toStringAsFixed(4)}')
        .join(', ');
    return '{\n'
        '  "prediction": "${result.predictedClass}",\n'
        '  "confidence": ${result.confidence.toStringAsFixed(4)},\n'
        '  "probabilities": { $probs }\n'
        '}';
  }
}

/// Convenience mapping from class code to a friendly display name.
String displayNameFor(String cls) =>
    skinClassDisplayNames[cls] ?? cls;

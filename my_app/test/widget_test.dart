import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:skin_ai/models/chat_message.dart';
import 'package:skin_ai/models/diagnosis_result.dart';
import 'package:skin_ai/services/llm/prompt_builder.dart';
import 'package:skin_ai/services/onnx/image_preprocessor.dart';
import 'package:skin_ai/services/onnx/onnx_service.dart';
import 'package:skin_ai/utils/constants.dart';

void main() {
  group('InferenceOutput.probabilities', () {
    test('softmax normalizes to 1 and preserves argmax', () {
      final output = InferenceOutput(
        logits: const [2.0, 1.0, 0.1, 3.5, 0.0, 0.5, -1.0],
        outputShape: const [1, 7],
        inferenceTime: const Duration(milliseconds: 10),
      );

      final probs = output.probabilities;
      final sum = probs.fold<double>(0.0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-6));
      expect(probs[3], greaterThan(probs[0]));

      final maxLogitIndex = output.logits
          .indexOf(output.logits.reduce((a, b) => a > b ? a : b));
      expect(probs[maxLogitIndex],
          greaterThan(probs.fold<double>(0.0, (a, b) => a > b ? a : b) -
              1e-9));
    });

    test('softmax is invariant to constant shift', () {
      final a = InferenceOutput(
        logits: const [1.0, 2.0, 3.0],
        outputShape: const [1, 3],
        inferenceTime: Duration.zero,
      ).probabilities;
      final b = InferenceOutput(
        logits: const [101.0, 102.0, 103.0],
        outputShape: const [1, 3],
        inferenceTime: Duration.zero,
      ).probabilities;

      expect(a[0], closeTo(b[0], 1e-6));
      expect(a[1], closeTo(b[1], 1e-6));
      expect(a[2], closeTo(b[2], 1e-6));
    });
  });

  group('ImagePreprocessor', () {
    test('shapeOf validates tensor length', () {
      const preprocessor = ImagePreprocessor();
      final tensor = List<double>.filled(
        1 * modelInputChannels * modelInputSize * modelInputSize,
        0.0,
      );
      final shape = preprocessor.shapeOf(Float32List.fromList(tensor));
      expect(shape, [1, modelInputChannels, modelInputSize, modelInputSize]);
    });

    test('shapeOf throws on wrong length', () {
      const preprocessor = ImagePreprocessor();
      expect(
        () => preprocessor.shapeOf(Float32List.fromList([0.0])),
        throwsArgumentError,
      );
    });
  });

  group('DiagnosisResult', () {
    test('JSON round-trip preserves fields', () {
      final result = DiagnosisResult(
        modelId: modelIdSmartphone,
        predictedClass: 'mel',
        confidence: 0.83,
        probabilities: {
          'mel': 0.83,
          'nv': 0.1,
          'bcc': 0.05,
          'akiec': 0.005,
          'bkl': 0.005,
          'df': 0.005,
          'vasc': 0.005,
        },
        timestamp: DateTime(2026, 8, 9, 12, 0, 0),
        inferenceDuration: const Duration(milliseconds: 240),
      );

      final restored = DiagnosisResult.fromJson(result.toJson());

      expect(restored.modelId, result.modelId);
      expect(restored.predictedClass, result.predictedClass);
      expect(restored.confidence, closeTo(result.confidence, 1e-9));
      expect(restored.probabilities['mel'], closeTo(0.83, 1e-9));
      expect(restored.timestamp, result.timestamp);
      expect(restored.inferenceDuration!.inMilliseconds, 240);
    });

    test('orderedProbabilities always covers all classes', () {
      final result = DiagnosisResult(
        modelId: modelIdBaseline,
        predictedClass: 'nv',
        confidence: 0.9,
        probabilities: {'nv': 0.9},
        timestamp: DateTime.now(),
      );

      final ordered = result.orderedProbabilities;
      expect(ordered.keys.toList(), skinClasses);
      expect(ordered['mel'], 0.0);
    });

    test('sortedProbabilities sorts descending', () {
      final result = DiagnosisResult(
        modelId: modelIdSmartphone,
        predictedClass: 'nv',
        confidence: 0.9,
        probabilities: {
          'mel': 0.3,
          'nv': 0.5,
          'bcc': 0.2,
        },
        timestamp: DateTime.now(),
      );

      final sorted = result.sortedProbabilities;
      expect(sorted[0].key, 'nv');
      expect(sorted[1].key, 'mel');
      expect(sorted[2].key, 'bcc');
    });
  });

  group('ChatMessage', () {
    test('assigns unique id when omitted', () {
      final a = ChatMessage(
        role: MessageRole.user,
        text: 'hi',
        timestamp: DateTime.now(),
      );
      final b = ChatMessage(
        role: MessageRole.user,
        text: 'hello',
        timestamp: DateTime.now(),
      );
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(b.id));
    });

    test('fromJson restores id', () {
      final json = {
        'id': 'custom-id',
        'role': 'user',
        'text': 'hi',
        'timestamp': DateTime(2026, 8, 9).toIso8601String(),
        'error': false,
        'loading': false,
      };
      final message = ChatMessage.fromJson(json);
      expect(message.id, 'custom-id');
      expect(message.role, MessageRole.user);
      expect(message.text, 'hi');
    });
  });

  group('PromptBuilder', () {
    test('buildSystemPrompt includes non-diagnosis disclaimer', () {
      const builder = PromptBuilder();
      final prompt = builder.buildSystemPrompt();
      expect(prompt, contains('You are NOT a doctor'));
      expect(prompt, contains('probabilistic predictions only'));
    });

    test('buildAnalysisContext lists probabilities', () {
      const builder = PromptBuilder();
      final result = DiagnosisResult(
        modelId: modelIdSmartphone,
        predictedClass: 'mel',
        confidence: 0.83,
        probabilities: {'mel': 0.83, 'nv': 0.17},
        timestamp: DateTime.now(),
      );
      final context = builder.buildAnalysisContext(result);
      expect(context, contains('Prediction: mel'));
      expect(context, contains('mel: 83.0%'));
      expect(context, contains('nv: 17.0%'));
    });
  });
}

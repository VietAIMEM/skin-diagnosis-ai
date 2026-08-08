// ignore_for_file: prefer_initializing_formals
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../models/diagnosis_result.dart';
import '../../utils/constants.dart';
import '../onnx/image_preprocessor.dart';
import '../onnx/model_manager.dart';

/// Orchestrates local ONNX inference for a selected image.
class InferenceService {
  InferenceService({
    required ModelManager modelManager,
    required ImagePreprocessor preprocessor,
  })  : _modelManager = modelManager,
        _preprocessor = preprocessor;

  final ModelManager _modelManager;
  final ImagePreprocessor _preprocessor;

  /// Runs inference with the requested model selection and returns a
  /// DiagnosisResult. When [option] is compareBoth, a second result is
  /// embedded.
  Future<DiagnosisResult> analyze(
    XFile image, {
    required AnalysisModelOption option,
  }) async {
    final file = File(image.path);
    if (!await file.exists()) {
      throw const FormatException('Unable to process this image.');
    }

    final primaryModel = switch (option) {
      AnalysisModelOption.smartphone ||
      AnalysisModelOption.compareBoth =>
        (assetSmartphoneModel, modelIdSmartphone),
      AnalysisModelOption.baseline => (assetBaselineModel, modelIdBaseline),
    };

    final result = await _runOne(
      file,
      assetPath: primaryModel.$1,
      modelId: primaryModel.$2,
      imagePath: image.path,
    );

    if (option == AnalysisModelOption.compareBoth) {
      final second = await _runOne(
        file,
        assetPath: assetBaselineModel,
        modelId: modelIdBaseline,
        imagePath: image.path,
      );
      return DiagnosisResult(
        modelId: result.modelId,
        predictedClass: result.predictedClass,
        confidence: result.confidence,
        probabilities: result.probabilities,
        timestamp: result.timestamp,
        imagePath: result.imagePath,
        inferenceDuration: result.inferenceDuration,
        secondModelResult: second,
      );
    }

    return result;
  }

  Future<DiagnosisResult> _runOne(
    File file, {
    required String assetPath,
    required String modelId,
    required String imagePath,
  }) async {
    final session =
        await _modelManager.getSession(assetPath, modelId: modelId);

    final tensor = _preprocessor.preprocessFile(file);
    final expected = modelInputChannels * modelInputSize * modelInputSize;
    if (tensor.length != expected) {
      throw StateError('Preprocessing produced an unexpected tensor shape.');
    }

    final output = await session.runAsync(tensor);
    if (output.outputShape[1] != skinClasses.length) {
      throw StateError(
        'Model output has ${output.outputShape[1]} classes, expected ${skinClasses.length}.',
      );
    }

    final probs = output.probabilities;
    var bestIndex = 0;
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > probs[bestIndex]) bestIndex = i;
    }

    final probabilities = <String, double>{
      for (var i = 0; i < skinClasses.length; i++)
        skinClasses[i]: probs[i],
    };

    return DiagnosisResult(
      modelId: modelId,
      predictedClass: skinClasses[bestIndex],
      confidence: probs[bestIndex],
      probabilities: probabilities,
      timestamp: DateTime.now(),
      imagePath: imagePath,
      inferenceDuration: output.inferenceTime,
    );
  }
}

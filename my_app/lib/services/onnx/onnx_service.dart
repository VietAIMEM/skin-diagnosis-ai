import 'dart:math' as math;
import 'dart:typed_data';

import 'package:onnxruntime_v2/onnxruntime_v2.dart';

/// A single inference result produced by the ONNX runtime.
class InferenceOutput {
  final List<double> logits;
  final List<int> outputShape;
  final Duration inferenceTime;

  const InferenceOutput({
    required this.logits,
    required this.outputShape,
    required this.inferenceTime,
  });

  /// Probabilities computed via numerically stable softmax.
  List<double> get probabilities {
    final maxLogit = logits.reduce(math.max);
    final exps = logits.map((l) => math.exp(l - maxLogit)).toList();
    final sum = exps.fold<double>(0.0, (a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }
}

/// Wraps an ONNX Runtime session for a single model file.
class OnnxSession {
  final String modelAssetPath;
  final String modelId;
  final OrtSession _session;
  final List<String> inputNames;
  final List<String> outputNames;

  // ignore_for_file: prefer_initializing_formals
  OnnxSession._({
    required this.modelAssetPath,
    required this.modelId,
    required OrtSession session,
    required this.inputNames,
    required this.outputNames,
  }) : _session = session;

  factory OnnxSession.create({
    required String modelAssetPath,
    required String modelId,
    required Uint8List modelBytes,
  }) {
    final options = OrtSessionOptions()
      ..setIntraOpNumThreads(2)
      ..appendCPUProvider(CPUFlags.useArena);
    final session = OrtSession.fromBuffer(modelBytes, options);
    return OnnxSession._(
      modelAssetPath: modelAssetPath,
      modelId: modelId,
      session: session,
      inputNames: session.inputNames,
      outputNames: session.outputNames,
    );
  }

  /// Runs inference asynchronously (isolate managed by the plugin).
  Future<InferenceOutput> runAsync(Float32List input) async {
    final shape = [1, 3, 224, 224];
    final inputTensor = OrtValueTensor.createTensorWithDataList(input, shape);
    final runOptions = OrtRunOptions();
    final stopwatch = Stopwatch()..start();
    try {
      final outputs = await _session.runAsync(runOptions, {
        inputNames.first: inputTensor,
      });
      if (outputs == null || outputs.isEmpty || outputs.first == null) {
        throw StateError('ONNX session returned no outputs.');
      }
      final raw = outputs.first!.value;
      final logits = _extractLogits(raw);
      return InferenceOutput(
        logits: logits,
        outputShape: [1, logits.length],
        inferenceTime: stopwatch.elapsed,
      );
    } finally {
      stopwatch.stop();
      inputTensor.release();
      runOptions.release();
    }
  }

  List<double> _extractLogits(dynamic raw) {
    final logits = <double>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is List) {
          for (final inner in v) {
            logits.add((inner as num).toDouble());
          }
        } else {
          logits.add((v as num).toDouble());
        }
      }
    } else {
      logits.add((raw as num).toDouble());
    }
    return logits;
  }

  void release() {
    _session.release();
  }
}

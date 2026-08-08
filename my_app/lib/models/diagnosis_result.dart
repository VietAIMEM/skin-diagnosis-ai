import '../utils/constants.dart';

/// Structured result of a local ONNX image analysis.
class DiagnosisResult {
  final String modelId;
  final String predictedClass;
  final double confidence;
  final Map<String, double> probabilities;
  final DateTime timestamp;
  final String? imagePath;
  final Duration? inferenceDuration;
  final DiagnosisResult? secondModelResult;

  const DiagnosisResult({
    required this.modelId,
    required this.predictedClass,
    required this.confidence,
    required this.probabilities,
    required this.timestamp,
    this.imagePath,
    this.inferenceDuration,
    this.secondModelResult,
  });

  String get modelDisplayName => modelId == modelIdBaseline ? 'Baseline' : 'Smartphone Optimized';

  String get modelVersion => modelId;

  /// Raw logits in the canonical class order.
  Map<String, double> get orderedProbabilities {
    return {
      for (final cls in skinClasses) cls: probabilities[cls] ?? 0.0,
    };
  }

  /// Probabilities sorted descending for display.
  List<MapEntry<String, double>> get sortedProbabilities {
    final entries = orderedProbabilities.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Map<String, dynamic> toJson() {
    return {
      'modelId': modelId,
      'predictedClass': predictedClass,
      'confidence': confidence,
      'probabilities': orderedProbabilities,
      'timestamp': timestamp.toIso8601String(),
      if (imagePath != null) 'imagePath': imagePath,
      if (inferenceDuration != null)
        'inferenceDurationMs': inferenceDuration!.inMilliseconds,
      if (secondModelResult != null)
        'secondModelResult': secondModelResult!.toJson(),
    };
  }

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    final probs = <String, double>{};
    (json['probabilities'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      probs[k] = (v as num).toDouble();
    });
    return DiagnosisResult(
      modelId: json['modelId'] as String? ?? modelIdSmartphone,
      predictedClass: json['predictedClass'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      probabilities: probs,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      imagePath: json['imagePath'] as String?,
      inferenceDuration: json['inferenceDurationMs'] != null
          ? Duration(milliseconds: json['inferenceDurationMs'] as int)
          : null,
      secondModelResult: json['secondModelResult'] != null
          ? DiagnosisResult.fromJson(
              json['secondModelResult'] as Map<String, dynamic>)
          : null,
    );
  }
}

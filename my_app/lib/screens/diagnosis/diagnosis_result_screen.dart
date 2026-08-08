import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/diagnosis_result.dart';
import '../../services/llm/prompt_builder.dart';
import '../../utils/constants.dart';
import '../../utils/extensions.dart';
import '../../widgets/confidence_bar.dart';

/// Detailed view of a single analysis result.
class DiagnosisResultScreen extends StatelessWidget {
  const DiagnosisResultScreen({super.key, this.args});

  final Object? args;

  DiagnosisResult? get _result {
    if (args is DiagnosisResult) return args as DiagnosisResult;
    if (args is Map<String, dynamic>) {
      return DiagnosisResult.fromJson(args as Map<String, dynamic>);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;
    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No result to display.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (result.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(result.imagePath!),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _sectionTitle(theme, 'Top Prediction'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.predictedClass,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayNameFor(result.predictedClass),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${result.confidence.asPercent()}%',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(theme, 'All Predictions'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final entry in result.sortedProbabilities)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: LabeledConfidenceBar(
                          label: entry.key,
                          value: entry.value,
                          color: entry.key == result.predictedClass
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(theme, 'Model'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Architecture', 'EfficientNet-B0'),
                    const SizedBox(height: 8),
                    _infoRow('Input', '$modelInputSize × $modelInputSize'),
                    const SizedBox(height: 8),
                    _infoRow('Model', result.modelDisplayName),
                    if (result.inferenceDuration != null) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                          'Inference time',
                          '${result.inferenceDuration!.inMilliseconds} ms'),
                    ],
                  ],
                ),
              ),
            ),
            if (result.secondModelResult != null) ...[
              const SizedBox(height: 24),
              _sectionTitle(theme, 'Model Comparison'),
              const SizedBox(height: 8),
              _comparisonCard(theme, result, result.secondModelResult!),
            ],
            const SizedBox(height: 24),
            Text(
              'These are experimental model outputs, not a medical diagnosis. '
              'Please consult a qualified healthcare professional.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonCard(
    ThemeData theme,
    DiagnosisResult primary,
    DiagnosisResult secondary,
  ) {
    final smartphone = primary.modelId == modelIdSmartphone
        ? primary
        : secondary;
    final baseline =
        primary.modelId == modelIdBaseline ? primary : secondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smartphone Model',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${smartphone.predictedClass} ${smartphone.confidence.asPercent()}%',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Baseline Model',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${baseline.predictedClass} ${baseline.confidence.asPercent()}%',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

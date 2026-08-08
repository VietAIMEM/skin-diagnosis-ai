import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/chat_message.dart';
import '../models/diagnosis_result.dart';
import '../utils/extensions.dart';
import 'diagnosis_card.dart';
import 'image_message.dart';
import 'loading_indicator.dart';

/// Renders a single chat bubble for any message role.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onViewDetails,
  });

  final ChatMessage message;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.isImageAnalysis) {
      final result = message.diagnosisResult != null
          ? DiagnosisResult.fromJson(message.diagnosisResult!)
          : null;
      return _AnalysisBubble(
        message: message,
        result: result,
        onViewDetails: onViewDetails,
      );
    }

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 60, top: 6, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.imagePath != null) ...[
                ImageMessage(path: message.imagePath!),
                const SizedBox(height: 8),
              ],
              if (message.text.isNotEmpty)
                Text(
                  message.text,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onPrimary),
                ),
              const SizedBox(height: 4),
              Text(
                timeOf(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Assistant / system messages
    final isError = message.error;
    final bubbleColor = isError
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerLow;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 60, top: 6, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.loading) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingIndicator(),
                  SizedBox(width: 12),
                  Text('SkinAI is typing...'),
                ],
              ),
            ] else if (message.text.isNotEmpty) ...[
              MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    color: isError
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeOf(message.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisBubble extends StatelessWidget {
  const _AnalysisBubble({
    required this.message,
    required this.result,
    required this.onViewDetails,
  });

  final ChatMessage message;
  final DiagnosisResult? result;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (message.loading)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingIndicator(),
                  SizedBox(width: 12),
                  Text('Analyzing image...'),
                ],
              )
            else if (result != null)
              DiagnosisCard(result: result!, onViewDetails: onViewDetails)
            else
              Text(
                message.text,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

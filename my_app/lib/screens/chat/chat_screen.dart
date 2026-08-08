import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/routes.dart';
import '../../models/chat_message.dart';
import '../../models/diagnosis_result.dart';
import '../../providers/providers.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider.notifier).sendText(text);
  }

  Future<void> _pickImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    final imageService = ref.read(imageServiceProvider);
    final file = choice == 'camera'
        ? await imageService.takePhoto()
        : await imageService.pickFromGallery();
    if (file == null || !mounted) return;

    Navigator.of(context).pushNamed(
      AppRoutes.imagePreview,
      arguments: file.path,
    );
  }

  void _openDetails(ChatMessage m) {
    final result = m.diagnosisResult != null
        ? DiagnosisResult.fromJson(m.diagnosisResult!)
        : null;
    if (result == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.diagnosisResult,
      arguments: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = ref.watch(chatProvider);

    ref.listen(chatProvider, (_, _) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: Colors.teal),
            SizedBox(width: 8),
            Text('SkinAI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chat.loadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        return ChatBubble(
                          message: message,
                          onViewDetails: () => _openDetails(message),
                        );
                      },
                    ),
            ),
            _inputBar(theme, chat.isSending),
          ],
        ),
      ),
    );
  }

  Widget _inputBar(ThemeData theme, bool isSending) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Attach image',
            iconSize: 28,
            onPressed: isSending ? null : _pickImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                suffixIcon: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: isSending ? null : _send,
            icon: const Icon(Icons.arrow_upward),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }
}

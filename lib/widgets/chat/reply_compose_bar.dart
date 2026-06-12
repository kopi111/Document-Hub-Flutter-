// INTEGRATION: Place ReplyComposeBar directly above the text-input row inside
// the bottom composing Column in chat_thread_screen.dart, passing the shared
// controller — Column(children: [ReplyComposeBar(controller: _controller), InputRow()])
// The bar is invisible (zero-height) when nothing is being replied to and slides
// open automatically via AnimatedSize when controller.replyingTo becomes non-null.

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Animated quoted-preview strip rendered above the text-input field whenever
/// the user has initiated a reply. Shows the target sender and a one-line
/// preview of the quoted message, with an X button that calls
/// [ChatThreadController.clearCompose].
class ReplyComposeBar extends StatelessWidget {
  const ReplyComposeBar({super.key, required this.controller});

  final ChatThreadController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: controller.replyingTo == null
              ? const SizedBox.shrink()
              : _Bar(controller: controller),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.controller});

  final ChatThreadController controller;

  String _senderLabel() {
    final target = controller.replyingTo!;
    if (target.fromMe) return 'You';
    return target.senderName ?? 'Contact';
  }

  @override
  Widget build(BuildContext context) {
    final target = controller.replyingTo!;
    return Container(
      decoration: const BoxDecoration(
        color: ChatStyle.surface,
        border: Border(
          top: BorderSide(color: ChatStyle.hairline, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: ChatStyle.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.reply_rounded, size: 18, color: ChatStyle.gold),
          const SizedBox(width: 8),
          Expanded(
            child: _SenderAndPreview(
              sender: _senderLabel(),
              preview: target.preview,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: controller.clearCompose,
            child: const Icon(
              Icons.close_rounded,
              size: 20,
              color: ChatStyle.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SenderAndPreview extends StatelessWidget {
  const _SenderAndPreview({required this.sender, required this.preview});

  final String sender;
  final String preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sender,
          style: ChatStyle.body(
            size: 13,
            weight: FontWeight.w600,
            color: ChatStyle.gold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          preview,
          style: ChatStyle.body(size: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

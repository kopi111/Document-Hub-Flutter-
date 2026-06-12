// INTEGRATION: Render QuotedReply at the top of each bubble's content Column in
// chat_thread_screen.dart when message.replyToId != null, passing a scroll-to
// callback from your ScrollController:
//   if (msg.replyToId != null)
//     QuotedReply(message: msg, controller: _controller,
//                 onJumpTo: (id) => _scrollToMessage(id))

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Inset quoted-message snippet rendered inside a bubble for messages that have
/// a [ChatMessage.replyToId]. Tapping calls [onJumpTo] with the original
/// message id so the thread can scroll to it.
///
/// The preview is resolved live from [controller] (picks up edits and
/// deletions) and falls back to the cached [ChatMessage.replyToPreview] when
/// the original is no longer in the local message list.
class QuotedReply extends StatelessWidget {
  const QuotedReply({
    super.key,
    required this.message,
    required this.controller,
    required this.onJumpTo,
  });

  final ChatMessage message;
  final ChatThreadController controller;
  final void Function(String messageId) onJumpTo;

  @override
  Widget build(BuildContext context) {
    final replyId = message.replyToId;
    if (replyId == null) return const SizedBox.shrink();

    final original = controller.messageById(replyId);
    final sender = message.replyToSender ?? 'Unknown';
    final preview = original?.preview ?? message.replyToPreview ?? '…';

    return GestureDetector(
      onTap: () => onJumpTo(replyId),
      child: _QuotedSnippet(
        sender: sender,
        preview: preview,
        fromMe: message.fromMe,
      ),
    );
  }
}

class _QuotedSnippet extends StatelessWidget {
  const _QuotedSnippet({
    required this.sender,
    required this.preview,
    required this.fromMe,
  });

  final String sender;
  final String preview;
  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    final accentColor = fromMe ? ChatStyle.gold : ChatStyle.goldSoft;
    final bgColor =
        fromMe ? const Color(0xFFD0EFC0) : ChatStyle.surfaceRaised;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sender,
                      style: ChatStyle.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: accentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      preview,
                      style: ChatStyle.body(size: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

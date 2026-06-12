// INTEGRATION: Replace the entire bubble body with DeletedMessageBubble(fromMe: msg.fromMe)
// when message.isDeleted — skip all other content, action hooks, and ReactionChips.

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';

/// Tombstone shown in place of a deleted message's content.
///
/// Renders in the same bubble colour as surrounding messages so the thread
/// layout remains consistent.
class DeletedMessageBubble extends StatelessWidget {
  const DeletedMessageBubble({super.key, this.fromMe = false});

  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChatStyle.pageInset,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: fromMe ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble,
        borderRadius: BorderRadius.circular(ChatStyle.bubbleRadius),
        border: Border.all(color: ChatStyle.hairline, width: 0.5),
      ),
      child: Text(
        '🚫 This message was deleted',
        style: ChatStyle.body(
          size: 14,
          color: ChatStyle.textSecondary,
          weight: FontWeight.w400,
        ).copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';

// INTEGRATION: Place at the top of the message bubble content column in
// chat_thread_screen.dart, before the message text — if (msg.isForwarded)
// ForwardedTag(message: msg). The tag renders nothing when isForwarded is false,
// so it is safe to include unconditionally inside every bubble.

/// Telegram-style "Forwarded from name" header rendered at the top of a
/// forwarded message bubble. Reads [ChatMessage.isForwarded] and
/// [ChatMessage.forwardedFrom] directly and produces no pixels when the message
/// is not forwarded.
class ForwardedTag extends StatelessWidget {
  const ForwardedTag({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (!message.isForwarded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ForwardIcon(),
          const SizedBox(width: 4),
          Flexible(child: _ForwardLabel(forwardedFrom: message.forwardedFrom)),
        ],
      ),
    );
  }
}

class _ForwardIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: -1,
      child: const Icon(
        Icons.reply_rounded,
        size: 13,
        color: ChatStyle.gold,
      ),
    );
  }
}

class _ForwardLabel extends StatelessWidget {
  const _ForwardLabel({required this.forwardedFrom});

  final String? forwardedFrom;

  @override
  Widget build(BuildContext context) {
    final label = forwardedFrom != null
        ? 'Forwarded from $forwardedFrom'
        : 'Forwarded';
    return Text(
      label,
      style: ChatStyle.body(
        size: 11,
        color: ChatStyle.gold,
        weight: FontWeight.w600,
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

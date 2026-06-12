import 'package:flutter/material.dart';

import '../../models/chat/message_reaction.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// A horizontal wrap of emoji+count chips derived from [reactions].
///
/// Chips where [MessageReaction.byMe] is true render with the accent border
/// and background to signal the current user's active reaction. Tapping any
/// chip calls [controller.toggleReaction] to add or retract the reaction.
///
/// Renders nothing when [reactions] is empty.
class ReactionChips extends StatelessWidget {
  const ReactionChips({
    super.key,
    required this.messageId,
    required this.reactions,
    required this.controller,
  });

  final String messageId;
  final List<MessageReaction> reactions;
  final ChatThreadController controller;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions
            .map(
              (r) => _ReactionChip(
                reaction: r,
                onTap: () => controller.toggleReaction(messageId, r.emoji),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.reaction, required this.onTap});

  final MessageReaction reaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = reaction.byMe;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          // 0x26 ≈ 15 % opacity of ChatStyle.gold (0xFF3390EC)
          color: active ? const Color(0x263390EC) : ChatStyle.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? ChatStyle.gold : ChatStyle.hairline,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 14, height: 1.0),
            ),
            const SizedBox(width: 3),
            Text(
              '${reaction.count}',
              style: ChatStyle.body(
                size: 12,
                weight: FontWeight.w600,
                color: active ? ChatStyle.gold : ChatStyle.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

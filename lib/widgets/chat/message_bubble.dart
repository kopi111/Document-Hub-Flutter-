import 'package:flutter/material.dart';

import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_type.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';
import 'deleted_message_bubble.dart';
import 'disappearing_badge.dart';
import 'edited_tag.dart';
import 'file_message_bubble.dart';
import 'forward_sheet.dart';
import 'forwarded_tag.dart';
import 'highlighted_text.dart';
import 'image_message_bubble.dart';
import 'message_actions_sheet.dart';
import 'quoted_reply.dart';
import 'reaction_chips.dart';
import 'reaction_picker.dart';
import 'read_receipt_ticks.dart';
import 'swipe_to_reply.dart';
import 'voice_message_bubble.dart';

/// One message rendered with every Telegram-parity affordance: swipe-to-reply,
/// long-press actions, reactions, quoted replies, forward tags, read receipts,
/// search highlighting and a disappearing-message countdown.
///
/// Dispatches to the type-specific bubble widget for voice, image and file
/// content, and to [DeletedMessageBubble] once a message is tombstoned.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.conversation,
    required this.controller,
    required this.searchQuery,
    required this.onJumpToMessage,
  });

  final ChatMessage message;
  final ChatConversation conversation;
  final ChatThreadController controller;
  final String searchQuery;
  final void Function(String messageId) onJumpToMessage;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.fromMe ? Alignment.centerRight : Alignment.centerLeft;
    return SwipeToReply(
      message: message,
      controller: controller,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(alignment: alignment, child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isDeleted) {
      return DeletedMessageBubble(fromMe: message.fromMe);
    }
    return GestureDetector(
      onLongPress: () => _openActions(context),
      child: Column(
        crossAxisAlignment: message.fromMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBody(context),
          ReactionChips(
            messageId: message.id,
            reactions: message.reactions,
            controller: controller,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (message.type) {
      case MessageType.voice:
        return _wrapMedia(VoiceMessageBubble(message: message));
      case MessageType.image:
        return _wrapMedia(ImageMessageBubble(message: message));
      case MessageType.file:
        return _wrapMedia(FileMessageBubble(message: message));
      case MessageType.text:
      case MessageType.location:
      case MessageType.system:
        return _TextBubble(
          message: message,
          conversation: conversation,
          controller: controller,
          searchQuery: searchQuery,
          onJumpToMessage: onJumpToMessage,
        );
    }
  }

  Widget _wrapMedia(Widget bubble) {
    return Column(
      crossAxisAlignment: message.fromMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ForwardedTag(message: message),
        bubble,
        _MetaRow(message: message),
      ],
    );
  }

  void _openActions(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final bubbleRect = box == null
        ? Rect.zero
        : box.localToGlobal(Offset.zero) & box.size;
    MessageActionsSheet.show(
      context,
      message: message,
      controller: controller,
      onReply: () => controller.beginReply(message),
      onForward: (target) => ForwardSheet.show(
        context,
        conversations: [conversation],
        message: target,
        controller: controller,
      ),
      onReact: () =>
          showReactionPicker(context, controller, message.id, bubbleRect),
    );
  }
}

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.message,
    required this.conversation,
    required this.controller,
    required this.searchQuery,
    required this.onJumpToMessage,
  });

  final ChatMessage message;
  final ChatConversation conversation;
  final ChatThreadController controller;
  final String searchQuery;
  final void Function(String messageId) onJumpToMessage;

  static const List<Color> _senderPalette = [
    Color(0xFF53BDEB),
    Color(0xFF7FD06B),
    Color(0xFFE07C68),
    Color(0xFFC58AF0),
    Color(0xFFF0B05A),
  ];

  bool get _showSender =>
      conversation.isGroup && !message.fromMe && message.senderName != null;

  Color _senderColor(String name) =>
      _senderPalette[name.hashCode.abs() % _senderPalette.length];

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(ChatStyle.bubbleRadius),
      topRight: const Radius.circular(ChatStyle.bubbleRadius),
      bottomLeft: Radius.circular(message.fromMe ? ChatStyle.bubbleRadius : 4),
      bottomRight: Radius.circular(message.fromMe ? 4 : ChatStyle.bubbleRadius),
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      decoration: BoxDecoration(
        color:
            message.fromMe ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ForwardedTag(message: message),
          if (message.replyToId != null)
            QuotedReply(
              message: message,
              controller: controller,
              onJumpTo: onJumpToMessage,
            ),
          if (_showSender) _SenderLabel(name: message.senderName!, color: _senderColor),
          HighlightedText(
            text: message.text,
            query: searchQuery,
            style: ChatStyle.body(size: 14, color: ChatStyle.textPrimary),
          ),
          const SizedBox(height: 3),
          _MetaRow(message: message),
        ],
      ),
    );
  }
}

class _SenderLabel extends StatelessWidget {
  const _SenderLabel({required this.name, required this.color});

  final String name;
  final Color Function(String) color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        name,
        style: ChatStyle.title(
          size: 12,
          weight: FontWeight.w700,
          color: color(name),
        ),
      ),
    );
  }
}

/// Trailing meta line: a disappearing countdown, the "edited" tag, the send
/// time and outbound read-receipt ticks.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.message});

  final ChatMessage message;

  String _formatTime(DateTime sentAt) {
    final hour = sentAt.hour.toString().padLeft(2, '0');
    final minute = sentAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (message.ttlSeconds != null) ...[
          DisappearingBadge(message: message),
          const SizedBox(width: 4),
        ],
        if (message.editedAt != null) ...[
          const EditedTag(),
          const SizedBox(width: 4),
        ],
        Text(
          _formatTime(message.sentAt),
          style: ChatStyle.mono(
            size: 9,
            color: ChatStyle.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        ReadReceiptTicks(status: message.status, fromMe: message.fromMe),
      ],
    );
  }
}

// INTEGRATION: In each bubble's GestureDetector.onLongPress, call:
//   MessageActionsSheet.show(context, message: msg, controller: _controller,
//     onReply: () {}, onForward: (m) => ForwardSheet.show(context, message: m, ...),
//     onReact: () => showReactionPicker(context, _controller, msg.id, bubbleRect));
// beginEdit() puts msg.text into the composer — commit by calling controller.applyEdit(id, newText).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Telegram-style long-press action sheet for a single message.
///
/// Shows Reply, Copy Text (when applicable), React, Forward, Edit and Delete
/// (own messages only), and Pin/Unpin. Edit calls [controller.beginEdit]; the
/// integrator's composer then commits via [controller.applyEdit]. Delete shows
/// a confirmation dialog before calling [controller.deleteMessage].
class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.controller,
    required this.onReply,
    required this.onForward,
    required this.onReact,
  });

  final ChatMessage message;
  final ChatThreadController controller;

  /// Called after the sheet dismisses — integrator should trigger reply compose.
  final VoidCallback onReply;

  /// Called after the sheet dismisses — integrator should open a ForwardSheet.
  final ValueChanged<ChatMessage> onForward;

  /// Called after the sheet dismisses — integrator should open the reaction picker.
  final VoidCallback onReact;

  static Future<void> show(
    BuildContext context, {
    required ChatMessage message,
    required ChatThreadController controller,
    required VoidCallback onReply,
    required ValueChanged<ChatMessage> onForward,
    required VoidCallback onReact,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MessageActionsSheet(
        message: message,
        controller: controller,
        onReply: onReply,
        onForward: onForward,
        onReact: onReact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: ChatStyle.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ChatStyle.cardRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _DragHandle(),
            _ActionTile(
              label: 'Reply',
              icon: Icons.reply_rounded,
              onTap: () {
                _dismiss(context);
                onReply();
              },
            ),
            if (message.text.isNotEmpty && !message.isDeleted)
              _ActionTile(
                label: 'Copy Text',
                icon: Icons.copy_rounded,
                onTap: () => _copyText(context),
              ),
            _ActionTile(
              label: 'React',
              icon: Icons.emoji_emotions_outlined,
              onTap: () {
                _dismiss(context);
                onReact();
              },
            ),
            _ActionTile(
              label: 'Forward',
              icon: Icons.forward_rounded,
              onTap: () {
                _dismiss(context);
                onForward(message);
              },
            ),
            if (message.fromMe && !message.isDeleted)
              _ActionTile(
                label: 'Edit',
                icon: Icons.edit_rounded,
                onTap: () {
                  _dismiss(context);
                  controller.beginEdit(message);
                },
              ),
            _ActionTile(
              label: message.isPinned ? 'Unpin' : 'Pin',
              icon: message.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              onTap: () {
                _dismiss(context);
                controller.togglePin(message.id);
              },
            ),
            if (message.fromMe && !message.isDeleted)
              _ActionTile(
                label: 'Delete',
                icon: Icons.delete_rounded,
                labelColor: const Color(0xFFFF3B30),
                onTap: () => _confirmDelete(context),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _copyText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    final messenger = ScaffoldMessenger.of(context);
    _dismiss(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Text copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete message?', style: ChatStyle.title(size: 16)),
        content: Text(
          'This message will be deleted for everyone.',
          style: ChatStyle.body(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (!context.mounted) return;
      _dismiss(context);
      if (confirmed == true) controller.deleteMessage(message.id);
    });
  }

  void _dismiss(BuildContext context) => Navigator.pop(context);
}

// ---------------------------------------------------------------------------

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ChatStyle.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.labelColor = ChatStyle.textPrimary,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatStyle.pageInset,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: labelColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: ChatStyle.body(
                size: 16,
                color: labelColor,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

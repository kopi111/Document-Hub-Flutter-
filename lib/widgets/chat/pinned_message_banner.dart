// INTEGRATION: Place PinnedMessageBanner directly below the AppBar inside
// chat_thread_screen.dart's body Column, before the Expanded message list:
//   body: Column(children: [
//     PinnedMessageBanner(controller: controller, onJumpTo: (id) => _scrollToMessage(id)),
//     Expanded(child: messageListView),
//   ])

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Slim banner rendered under the app bar when the thread has a pinned message.
/// Tapping anywhere on the banner invokes [onJumpTo] with the pinned message's
/// id. The X button calls [ChatThreadController.togglePin] to unpin. Returns a
/// zero-height [SizedBox.shrink] when nothing is pinned — callers never see null.
class PinnedMessageBanner extends StatelessWidget {
  const PinnedMessageBanner({
    super.key,
    required this.controller,
    required this.onJumpTo,
  });

  final ChatThreadController controller;
  final void Function(String messageId) onJumpTo;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: controller.pinnedMessage == null
              ? const SizedBox.shrink()
              : _BannerContent(
                  message: controller.pinnedMessage!,
                  controller: controller,
                  onJumpTo: onJumpTo,
                ),
        );
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.message,
    required this.controller,
    required this.onJumpTo,
  });

  final ChatMessage message;
  final ChatThreadController controller;
  final void Function(String messageId) onJumpTo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatStyle.surface,
      child: InkWell(
        onTap: () => onJumpTo(message.id),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: ChatStyle.hairline, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _AccentBar(),
              const SizedBox(width: 10),
              const Icon(
                Icons.push_pin_rounded,
                size: 16,
                color: ChatStyle.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PinnedText(preview: message.preview),
              ),
              const SizedBox(width: 8),
              _UnpinButton(
                onUnpin: () => controller.togglePin(message.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 36,
      decoration: BoxDecoration(
        color: ChatStyle.gold,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PinnedText extends StatelessWidget {
  const _PinnedText({required this.preview});

  final String preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pinned message',
          style: ChatStyle.body(
            size: 12,
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

class _UnpinButton extends StatelessWidget {
  const _UnpinButton({required this.onUnpin});

  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUnpin,
      child: const Icon(
        Icons.close_rounded,
        size: 20,
        color: ChatStyle.textSecondary,
      ),
    );
  }
}

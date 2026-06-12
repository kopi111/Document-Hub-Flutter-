// INTEGRATION: In the bubble widget's onLongPress handler, resolve the bubble's
// global bounds and call: showReactionPicker(context, controller, msg.id,
//   (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero) & context.size!);
// Place ReactionChips(...) below the bubble container in the bubble's Column.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

const List<String> _kQuickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '✅'];

/// Shows a Telegram-style floating emoji picker anchored near [bubbleRect].
///
/// Auto-dismisses when the user picks an emoji or taps outside the bar.
/// Calls [controller.toggleReaction] with the selected emoji.
void showReactionPicker(
  BuildContext context,
  ChatThreadController controller,
  String messageId,
  Rect bubbleRect,
) {
  final overlay = Overlay.of(context);
  OverlayEntry? entry;

  entry = OverlayEntry(
    builder: (_) => _ReactionPickerOverlay(
      bubbleRect: bubbleRect,
      onPick: (emoji) {
        controller.toggleReaction(messageId, emoji);
        entry?.remove();
      },
      onDismiss: () => entry?.remove(),
    ),
  );

  overlay.insert(entry);
}

// ---------------------------------------------------------------------------

class _ReactionPickerOverlay extends StatefulWidget {
  const _ReactionPickerOverlay({
    required this.bubbleRect,
    required this.onPick,
    required this.onDismiss,
  });

  final Rect bubbleRect;
  final ValueChanged<String> onPick;
  final VoidCallback onDismiss;

  @override
  State<_ReactionPickerOverlay> createState() => _ReactionPickerOverlayState();
}

class _ReactionPickerOverlayState extends State<_ReactionPickerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Positions the bar above the bubble; flips below when it would clip the top.
  Offset _resolvePosition(Size screenSize) {
    const barWidth = 316.0;
    const barHeight = 56.0;
    const gap = 8.0;
    const edgePad = 8.0;

    final double centeredLeft = widget.bubbleRect.left +
        (widget.bubbleRect.width - barWidth) / 2;
    final double left =
        centeredLeft.clamp(edgePad, screenSize.width - barWidth - edgePad);

    final double aboveTop = widget.bubbleRect.top - barHeight - gap;
    final double top =
        aboveTop < edgePad ? widget.bubbleRect.bottom + gap : aboveTop;

    return Offset(left, top);
  }

  @override
  Widget build(BuildContext context) {
    final pos = _resolvePosition(MediaQuery.of(context).size);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
          ),
        ),
        Positioned(
          left: pos.dx,
          top: pos.dy,
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.bottomCenter,
              child: _PickerBar(onPick: widget.onPick),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PickerBar extends StatelessWidget {
  const _PickerBar({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: ChatStyle.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _kQuickEmojis
              .map((emoji) => _EmojiButton(
                    emoji: emoji,
                    onTap: () => onPick(emoji),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmojiButton extends StatefulWidget {
  const _EmojiButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
      },
      onTapUp: (_) => widget.onTap(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 28, height: 1.0),
          ),
        ),
      ),
    );
  }
}

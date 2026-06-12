// INTEGRATION: In chat_thread_screen.dart, wrap each message bubble widget with
// SwipeToReply inside the ListView builder:
//   SwipeToReply(message: msg, controller: _controller, child: ChatBubble(msg))
// Set clipBehavior: Clip.none on the surrounding ScrollView / ListView so the
// translated bubble can overflow its item slot during the drag gesture.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Wraps a message bubble with a Telegram-style rightward swipe gesture.
///
/// Dragging past [_triggerThreshold] triggers haptic feedback and records the
/// intent. On finger-up the bubble springs back, and if the threshold was
/// reached [ChatThreadController.beginReply] is called with the message.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.message,
    required this.controller,
    required this.child,
  });

  final ChatMessage message;
  final ChatThreadController controller;
  final Widget child;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const double _triggerThreshold = 72.0;
  static const double _maxDrag = 96.0;

  late final AnimationController _snapController;

  double _dragOffset = 0;
  double _snapStartOffset = 0;
  bool _thresholdReached = false;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onSnapTick);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    if (!mounted) return;
    final t = Curves.easeOutBack.transform(_snapController.value);
    setState(() => _dragOffset = _snapStartOffset * (1.0 - t));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.message.isDeleted) return;
    _snapController.stop();
    final next = (_dragOffset + details.delta.dx).clamp(0.0, _maxDrag);
    if (next == _dragOffset) return;

    setState(() => _dragOffset = next);

    if (!_thresholdReached && _dragOffset >= _triggerThreshold) {
      _thresholdReached = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    if (_thresholdReached) {
      widget.controller.beginReply(widget.message);
    }
    _thresholdReached = false;
    _snapBack();
  }

  void _onDragCancel() {
    _thresholdReached = false;
    _snapBack();
  }

  void _snapBack() {
    _snapStartOffset = _dragOffset;
    _snapController.reset();
    _snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _onDragCancel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: _ReplyArrow(
              dragOffset: _dragOffset,
              threshold: _triggerThreshold,
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _ReplyArrow extends StatelessWidget {
  const _ReplyArrow({required this.dragOffset, required this.threshold});

  final double dragOffset;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final progress = (dragOffset / threshold).clamp(0.0, 1.0);
    return Align(
      alignment: Alignment.centerLeft,
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          scale: 0.4 + 0.6 * progress,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ChatStyle.textSecondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.reply_rounded,
              size: 18,
              color: ChatStyle.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

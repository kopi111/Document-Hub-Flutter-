// INTEGRATION: Add a `peerIsTyping` bool and optional `typingPeerName` to
// your presence layer (or ChatThreadController). In chat_thread_screen.dart
// insert before the last item of the message ListView, or just above the
// input bar, inside an Align:
//   if (peerIsTyping)
//     Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(8, 0, 64, 4),
//         child: TypingIndicator(typistName: typingPeerName),
//       ),
//     )

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';

/// Animated three-bouncing-dots "peer is typing" bubble.
///
/// Renders an incoming-style bubble containing three staggered-bounce dots.
/// Provide [typistName] to display "Name is typing" above the bubble — helpful
/// in group threads where multiple people may type simultaneously.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.typistName});

  final String? typistName;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.typistName != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              '${widget.typistName} is typing',
              style: ChatStyle.body(size: 11, color: ChatStyle.textSecondary),
            ),
          ),
        _TypingBubble(controller: _controller),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ChatStyle.incomingBubble,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ChatStyle.bubbleRadius),
          topRight: Radius.circular(ChatStyle.bubbleRadius),
          bottomRight: Radius.circular(ChatStyle.bubbleRadius),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => _BouncingDot(controller: controller, index: i),
        ),
      ),
    );
  }
}

class _BouncingDot extends StatelessWidget {
  const _BouncingDot({required this.controller, required this.index});

  final AnimationController controller;
  final int index;

  static const double _dotSize = 7;
  static const double _dotRisePx = 5;
  static const double _totalMs = 1200;
  static const double _dotActiveMs = 600;
  static const double _staggerMs = 200;

  @override
  Widget build(BuildContext context) {
    final double start = (index * _staggerMs) / _totalMs;
    final double end = (index * _staggerMs + _dotActiveMs) / _totalMs;

    final Animation<double> bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -_dotRisePx)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -_dotRisePx, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(start, end),
    ));

    return AnimatedBuilder(
      animation: bounce,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, bounce.value),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Container(
          width: _dotSize,
          height: _dotSize,
          decoration: const BoxDecoration(
            color: ChatStyle.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

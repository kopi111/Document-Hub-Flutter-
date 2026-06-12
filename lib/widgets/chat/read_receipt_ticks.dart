// INTEGRATION: Place immediately to the right of the timestamp Text inside
// each bubble's bottom-trailing Row in chat_thread_screen.dart:
//   Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Text(timeLabel, style: ...),
//       const SizedBox(width: 3),
//       ReadReceiptTicks(status: message.status, fromMe: message.fromMe),
//     ],
//   )
// Renders nothing (zero-size) for inbound messages, so no conditional needed.

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';

/// Single/double/blue-double tick marks conveying delivery state of an outbound
/// message, matching Telegram's visual convention:
///
/// - [MessageStatus.sent]      → single gray tick  (✓)
/// - [MessageStatus.delivered] → double gray ticks (✓✓)
/// - [MessageStatus.read]      → double blue ticks (✓✓ in [ChatStyle.readTick])
///
/// Renders nothing when [fromMe] is false — inbound messages have no delivery
/// state from the current user's perspective.
class ReadReceiptTicks extends StatelessWidget {
  const ReadReceiptTicks({
    super.key,
    required this.status,
    required this.fromMe,
  });

  final MessageStatus status;
  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    if (!fromMe) return const SizedBox.shrink();
    return _TickMark(status: status);
  }
}

class _TickMark extends StatelessWidget {
  const _TickMark({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = status == MessageStatus.read
        ? ChatStyle.readTick
        : ChatStyle.textSecondary;

    final IconData icon =
        status == MessageStatus.sent ? Icons.done : Icons.done_all;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        icon,
        key: ValueKey(status),
        size: 16,
        color: color,
      ),
    );
  }
}

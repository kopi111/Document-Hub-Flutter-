// INTEGRATION: In chat_thread_screen.dart, wrap each message bubble row in a
// Stack and position DisappearingBadge(message: msg) at Alignment.bottomRight
// (inside the bubble padding) when msg.ttlSeconds != null. The badge renders
// nothing ([SizedBox.shrink]) when there is no TTL or after the TTL elapses.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';

/// Flame-icon badge with a live countdown for a disappearing [message].
///
/// Ticks every second while mounted. Returns [SizedBox.shrink] for messages
/// without a TTL, deleted messages, and messages whose TTL has already elapsed
/// (the [DisappearingSweeper] handles the actual tombstone shortly after).
class DisappearingBadge extends StatefulWidget {
  const DisappearingBadge({super.key, required this.message});

  final ChatMessage message;

  @override
  State<DisappearingBadge> createState() => _DisappearingBadgeState();
}

class _DisappearingBadgeState extends State<DisappearingBadge> {
  Timer? _ticker;

  bool get _shouldShow =>
      widget.message.ttlSeconds != null && !widget.message.isDeleted;

  Duration _remaining() {
    final ttl = widget.message.ttlSeconds!;
    final expiry = widget.message.sentAt.add(Duration(seconds: ttl));
    final diff = expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void initState() {
    super.initState();
    if (_shouldShow) _startTicker();
  }

  @override
  void didUpdateWidget(DisappearingBadge old) {
    super.didUpdateWidget(old);
    if (_shouldShow && _ticker == null) {
      _startTicker();
    } else if (!_shouldShow) {
      _stopTicker();
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();
    final remaining = _remaining();
    if (remaining.inSeconds <= 0) return const SizedBox.shrink();
    return _CountdownBadge(remaining: remaining);
  }
}

// ---------------------------------------------------------------------------

class _CountdownBadge extends StatelessWidget {
  const _CountdownBadge({required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        // 0x1F ≈ 12 % alpha of ChatStyle.gold (0xFF3390EC)
        color: const Color(0x1F3390EC),
        borderRadius: BorderRadius.circular(8),
        // 0x4D ≈ 30 % alpha
        border: Border.all(color: const Color(0x4D3390EC), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 12,
            color: ChatStyle.gold,
          ),
          const SizedBox(width: 2),
          Text(
            _formatRemaining(remaining),
            style: ChatStyle.mono(size: 10),
          ),
        ],
      ),
    );
  }

  static String _formatRemaining(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

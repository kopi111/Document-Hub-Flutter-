import 'dart:async';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Periodically tombstones messages whose self-destruct TTL has elapsed.
///
/// Call [start] when the thread screen mounts and [stop] when it unmounts.
/// The sweeper runs a one-second tick and calls
/// [ChatThreadController.deleteMessage] for each expired message, which sets
/// [ChatMessage.isDeleted] and triggers a UI rebuild.
class DisappearingSweeper {
  DisappearingSweeper({required ChatThreadController controller})
      : _controller = controller;

  final ChatThreadController _controller;
  Timer? _timer;

  static const _interval = Duration(seconds: 1);

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _sweep());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _sweep() {
    final now = DateTime.now();
    final expired = List.of(_controller.messages)
        .where((m) => _isExpired(m, now))
        .toList();
    for (final message in expired) {
      _controller.deleteMessage(message.id);
    }
  }

  static bool _isExpired(ChatMessage message, DateTime now) {
    if (message.ttlSeconds == null || message.isDeleted) return false;
    return message.sentAt
        .add(Duration(seconds: message.ttlSeconds!))
        .isBefore(now);
  }
}

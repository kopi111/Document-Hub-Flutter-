// INTEGRATION: In chat_thread_screen.dart replace the AppBar title with a
// Column combining the contact's name and this subtitle:
//   title: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Text(contact.name,
//            style: ChatStyle.title(size: 16, weight: FontWeight.w700,
//                                   color: Colors.white)),
//       PresenceSubtitle(contact: contact, isTyping: peerIsTyping),
//     ],
//   )
// Trigger a rebuild every ~60 s (e.g. a periodic Timer) to keep relative
// last-seen labels current.

import 'package:flutter/material.dart';

import '../../models/chat/chat_contact.dart';
import '../../screens/chat/chat_style.dart';

/// App-bar subtitle reflecting real-time presence of [contact].
///
/// Priority: [isTyping] → "typing…" · [contact.isOnline] → "online" ·
/// else → relative "last seen …" label computed from [contact.lastSeen].
///
/// Purely presentational — no internal timer. Rebuild from your presence layer
/// (WebSocket stream, polling Timer, etc.) to keep the label current.
class PresenceSubtitle extends StatelessWidget {
  const PresenceSubtitle({
    super.key,
    required this.contact,
    this.isTyping = false,
  });

  final ChatContact contact;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final bool prominent = isTyping || contact.isOnline;
    return Text(
      _label(),
      style: ChatStyle.body(
        size: 12,
        color: prominent
            ? Colors.white
            : Colors.white.withValues(alpha: 0.80),
      ),
    );
  }

  String _label() {
    if (isTyping) return 'typing…';
    if (contact.isOnline) return 'online';
    return _relativeLastSeen(contact.lastSeen);
  }

  static String _relativeLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'last seen recently';

    final now = DateTime.now().toLocal();
    final local = lastSeen.toLocal();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) return 'last seen just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return 'last seen $m ${m == 1 ? "minute" : "minutes"} ago';
    }

    final todayMidnight = DateTime(now.year, now.month, now.day);
    final seenMidnight = DateTime(local.year, local.month, local.day);
    final calendarDays = todayMidnight.difference(seenMidnight).inDays;

    if (calendarDays == 0) return 'last seen today at ${_hhMm(local)}';
    if (calendarDays == 1) return 'last seen yesterday at ${_hhMm(local)}';
    if (calendarDays < 7) return 'last seen ${_weekdayName(local)} at ${_hhMm(local)}';
    return 'last seen ${_shortDate(local)}';
  }

  static String _hhMm(DateTime local) =>
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String _weekdayName(DateTime local) => _weekdays[local.weekday - 1];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _shortDate(DateTime local) =>
      '${local.day} ${_months[local.month - 1]} ${local.year}';
}

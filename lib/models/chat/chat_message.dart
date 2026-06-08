/// Delivery state of a message the current user sent, shown as WhatsApp-style
/// ticks. Inbound messages ignore this and always read as [delivered].
enum MessageStatus { sent, delivered, read }

/// A single message in an officer-to-officer conversation.
class ChatMessage {
  final String id;
  final String text;
  final DateTime sentAt;
  final bool fromMe;

  /// Delivery state for outbound messages. Drives the tick marks.
  final MessageStatus status;

  /// Display name of the sender, used to label bubbles in group threads. Null
  /// in one-to-one threads, where the contact is already named in the app bar.
  final String? senderName;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.fromMe,
    this.status = MessageStatus.sent,
    this.senderName,
  });

  /// Returns a copy with the given fields replaced. Keeps read-receipt and
  /// other in-place updates from silently dropping fields added later.
  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        id: id,
        text: text,
        sentAt: sentAt,
        fromMe: fromMe,
        status: status ?? this.status,
        senderName: senderName,
      );
}

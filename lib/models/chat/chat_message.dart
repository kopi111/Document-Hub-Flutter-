import 'chat_attachment.dart';
import 'message_reaction.dart';
import 'message_type.dart';

/// Delivery state of a message the current user sent, shown as WhatsApp-style
/// ticks. Inbound messages ignore this and always read as [delivered].
enum MessageStatus { sent, delivered, read }

/// A single message in an officer-to-officer conversation.
class ChatMessage {
  final String id;

  /// Identifies the owning thread; populated from the API `conversation_id`
  /// field. Empty string for in-memory-only messages.
  final String conversationId;

  final String text;
  final DateTime sentAt;
  final bool fromMe;

  /// Delivery state for outbound messages. Drives the tick marks.
  final MessageStatus status;

  /// Display name of the sender, used to label bubbles in group threads. Null
  /// in one-to-one threads, where the contact is already named in the app bar.
  final String? senderName;

  // --- Telegram-parity content fields (all optional, additive) -------------

  /// What kind of content this message carries. Defaults to [MessageType.text].
  final MessageType type;

  /// Non-text payload (voice note, image, file). Null for plain text.
  final ChatAttachment? attachment;

  /// Id of the message this one replies to. Null when not a reply.
  final String? replyToId;

  /// Cached one-line preview of the replied-to message, so a reply renders its
  /// quoted snippet without resolving [replyToId] against the full list.
  final String? replyToPreview;

  /// Display name of the replied-to message's sender.
  final String? replyToSender;

  /// Emoji reaction tallies on this message. Empty when unreacted.
  final List<MessageReaction> reactions;

  /// When the message was last edited. Null when never edited; drives the
  /// "edited" tag.
  final DateTime? editedAt;

  /// True once the sender deletes the message; the bubble shows a tombstone.
  final bool isDeleted;

  /// Whether the message is pinned in its thread.
  final bool isPinned;

  /// True when the message was forwarded from another thread.
  final bool isForwarded;

  /// Original author shown on a forwarded message, e.g. "Forwarded from Sgt Reid".
  final String? forwardedFrom;

  /// Self-destruct lifetime in seconds for disappearing messages. Null when the
  /// message does not expire.
  final int? ttlSeconds;

  const ChatMessage({
    required this.id,
    this.conversationId = '',
    required this.text,
    required this.sentAt,
    required this.fromMe,
    this.status = MessageStatus.sent,
    this.senderName,
    this.type = MessageType.text,
    this.attachment,
    this.replyToId,
    this.replyToPreview,
    this.replyToSender,
    this.reactions = const [],
    this.editedAt,
    this.isDeleted = false,
    this.isPinned = false,
    this.isForwarded = false,
    this.forwardedFrom,
    this.ttlSeconds,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        sentAt: DateTime.parse(json['sent_at'] as String).toUtc(),
        fromMe: json['from_me'] as bool? ?? false,
        status: _parseStatus(json['status'] as String?),
        senderName: json['sender_name'] as String?,
        type: MessageTypeWire.fromWire(json['type'] as String?),
        attachment: json['attachment'] == null
            ? null
            : ChatAttachment.fromJson(
                json['attachment'] as Map<String, dynamic>),
        replyToId: json['reply_to_id'] as String?,
        replyToPreview: json['reply_to_preview'] as String?,
        replyToSender: json['reply_to_sender'] as String?,
        reactions: (json['reactions'] as List<dynamic>?)
                ?.map((r) => MessageReaction.fromJson(r as Map<String, dynamic>))
                .toList(growable: false) ??
            const [],
        editedAt: json['edited_at'] == null
            ? null
            : DateTime.parse(json['edited_at'] as String).toUtc(),
        isDeleted: json['is_deleted'] as bool? ?? false,
        isPinned: json['is_pinned'] as bool? ?? false,
        isForwarded: json['is_forwarded'] as bool? ?? false,
        forwardedFrom: json['forwarded_from'] as String?,
        ttlSeconds: json['ttl_seconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'text': text,
        'sent_at': sentAt.toUtc().toIso8601String(),
        'from_me': fromMe,
        'status': _wireStatus(status),
        if (senderName != null) 'sender_name': senderName,
        'type': type.wire,
        if (attachment != null) 'attachment': attachment!.toJson(),
        if (replyToId != null) 'reply_to_id': replyToId,
        if (replyToPreview != null) 'reply_to_preview': replyToPreview,
        if (replyToSender != null) 'reply_to_sender': replyToSender,
        if (reactions.isNotEmpty)
          'reactions': reactions.map((r) => r.toJson()).toList(growable: false),
        if (editedAt != null) 'edited_at': editedAt!.toUtc().toIso8601String(),
        if (isDeleted) 'is_deleted': true,
        if (isPinned) 'is_pinned': true,
        if (isForwarded) 'is_forwarded': true,
        if (forwardedFrom != null) 'forwarded_from': forwardedFrom,
        if (ttlSeconds != null) 'ttl_seconds': ttlSeconds,
      };

  static MessageStatus _parseStatus(String? value) {
    switch (value) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }

  static String _wireStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return 'sent';
      case MessageStatus.delivered:
        return 'delivered';
      case MessageStatus.read:
        return 'read';
    }
  }

  /// Short preview used when this message is quoted in a reply or shown as a
  /// conversation's last line. Reflects the content type.
  String get preview {
    if (isDeleted) return 'This message was deleted';
    switch (type) {
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 ${attachment?.name ?? 'File'}';
      case MessageType.location:
        return '📍 Location';
      case MessageType.text:
      case MessageType.system:
        return text;
    }
  }

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    MessageType? type,
    ChatAttachment? attachment,
    String? replyToId,
    String? replyToPreview,
    String? replyToSender,
    List<MessageReaction>? reactions,
    DateTime? editedAt,
    bool? isDeleted,
    bool? isPinned,
    bool? isForwarded,
    String? forwardedFrom,
    int? ttlSeconds,
  }) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        text: text ?? this.text,
        sentAt: sentAt,
        fromMe: fromMe,
        status: status ?? this.status,
        senderName: senderName,
        type: type ?? this.type,
        attachment: attachment ?? this.attachment,
        replyToId: replyToId ?? this.replyToId,
        replyToPreview: replyToPreview ?? this.replyToPreview,
        replyToSender: replyToSender ?? this.replyToSender,
        reactions: reactions ?? this.reactions,
        editedAt: editedAt ?? this.editedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isPinned: isPinned ?? this.isPinned,
        isForwarded: isForwarded ?? this.isForwarded,
        forwardedFrom: forwardedFrom ?? this.forwardedFrom,
        ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      );
}

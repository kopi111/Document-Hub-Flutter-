import 'chat_contact.dart';
import 'chat_group.dart';
import 'chat_message.dart';

/// An ordered exchange of messages, either one-to-one with a single officer or
/// within a [group]. The [contact] is always present — for a group it holds a
/// representative member so name/rank/station are never blank — while the
/// display getters prefer the group when one is set.
class ChatConversation {
  final String id;
  final ChatContact contact;
  final ChatGroup? group;
  final List<ChatMessage> messages;

  /// Most-recent message in this thread, or null when the thread is empty.
  /// Populated from [messages].last for in-memory conversations, or from the
  /// API `last_message` field in the conversation summary response.
  final ChatMessage? lastMessage;

  /// When this thread was first created. Null when not returned by the API.
  final DateTime? createdAt;

  /// How many inbound messages the user has already seen. Advanced by
  /// [markRead] when the thread is opened so [unreadCount] can return to zero.
  int _seenInbound;

  ChatConversation({
    required this.id,
    required this.contact,
    required this.messages,
    this.group,
    this.createdAt,
    ChatMessage? lastMessage,
    int seenInbound = 0,
  })  : lastMessage = lastMessage ?? (messages.isNotEmpty ? messages.last : null),
        _seenInbound = seenInbound;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? <dynamic>[];
    final msgs = rawMessages
        .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
        .toList(growable: true);
    final inboundCount = msgs.where((m) => !m.fromMe).length;
    final apiUnreadCount = json['unread_count'] as int? ?? 0;
    return ChatConversation(
      id: json['id'] as String,
      contact: ChatContact.fromJson(json['contact'] as Map<String, dynamic>),
      group: json['group'] == null
          ? null
          : ChatGroup.fromJson(json['group'] as Map<String, dynamic>),
      messages: msgs,
      lastMessage: json['last_message'] == null
          ? null
          : ChatMessage.fromJson(
              json['last_message'] as Map<String, dynamic>),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String).toUtc(),
      // seenInbound is set so that unreadCount == apiUnreadCount at construction
      seenInbound: inboundCount - apiUnreadCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contact': contact.toJson(),
        if (group != null) 'group': group!.toJson(),
        'messages': messages.map((m) => m.toJson()).toList(growable: false),
        if (lastMessage != null) 'last_message': lastMessage!.toJson(),
        if (createdAt != null)
          'created_at': createdAt!.toUtc().toIso8601String(),
        'unread_count': unreadCount,
      };

  bool get isGroup => group != null;

  /// Title shown in the list and thread app bar.
  String get title => group?.name ?? contact.name;

  /// Secondary line: members for a group, rank and station for an officer.
  String get subtitle =>
      group?.membersSummary ?? '${contact.rank} · ${contact.station}';

  /// Profile photo URL for the conversation, or null to fall back to initials.
  String? get avatarUrl => group?.avatarUrl ?? contact.avatarUrl;

  /// Initials shown when there is no photo.
  String get avatarInitials => group?.initials ?? contact.initials;

  /// Whether to show the online presence dot.
  bool get isOnline => group?.anyOnline ?? contact.isOnline;

  /// Total inbound messages (received from others, not sent by the user).
  int get _inboundCount => messages.where((m) => !m.fromMe).length;

  /// Inbound messages the user has not yet seen. Returns to zero once the
  /// thread is opened and [markRead] is called.
  int get unreadCount {
    final unread = _inboundCount - _seenInbound;
    return unread < 0 ? 0 : unread;
  }

  /// Marks every current inbound message as seen, clearing [unreadCount].
  void markRead() => _seenInbound = _inboundCount;
}

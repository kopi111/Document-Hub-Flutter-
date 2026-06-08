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

  ChatConversation({
    required this.id,
    required this.contact,
    required this.messages,
    this.group,
  });

  /// How many inbound messages the user has already seen. Advanced by
  /// [markRead] when the thread is opened so [unreadCount] can return to zero.
  int _seenInbound = 0;

  bool get isGroup => group != null;

  /// Title shown in the list and thread app bar.
  String get title => group?.name ?? contact.name;

  /// Secondary line: members for a group, rank and station for an officer.
  String get subtitle =>
      group?.membersSummary ?? '${contact.rank} · ${contact.station}';

  /// Profile photo for the conversation, or null to fall back to initials.
  String? get avatarUrl => group?.avatarUrl ?? contact.avatarUrl;

  /// Initials shown when there is no photo.
  String get avatarInitials => group?.initials ?? contact.initials;

  /// Whether to show the online presence dot.
  bool get isOnline => group?.anyOnline ?? contact.isOnline;

  /// The most-recent message in the thread, or a blank sentinel when the
  /// thread is empty (avoids null returns in display logic).
  ChatMessage get lastMessage {
    if (messages.isEmpty) {
      return ChatMessage(
        id: '',
        text: '',
        sentAt: DateTime(2000),
        fromMe: false,
      );
    }
    return messages.last;
  }

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

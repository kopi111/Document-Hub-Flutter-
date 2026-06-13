import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/chat/chat_attachment.dart';
import '../../models/chat/chat_contact.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_group.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_reaction.dart';
import '../../models/chat/message_type.dart';
import '../api/api_config.dart';
import '../api/api_exception.dart';
import '../api/token_provider.dart';

// INTEGRATION: Swap InMemoryChatRepository for HttpChatRepository at the
// composition root once the v1/chat API is live. Wire the new mutation methods
// (editMessage, deleteMessage, togglePin, toggleReaction, forwardMessage,
// sendAttachment, uploadAttachment, searchMessages, sendTyping, markMessageRead)
// from ChatThreadController callbacks instead of touching conversation.messages
// directly.

/// Deterministic placeholder portrait for a given officer or group id.
String officerAvatar(String id) => 'https://i.pravatar.cc/200?u=$id';

/// Who is currently typing in a thread, as reported by the backend.
class ChatTypingState {
  const ChatTypingState({required this.isTyping, this.usernames = const []});

  const ChatTypingState.idle()
      : isTyping = false,
        usernames = const [];

  final bool isTyping;
  final List<String> usernames;
}

/// Contract for loading and mutating officer conversations.
abstract class ChatRepository {
  /// Returns all conversations, sorted descending by last-message time.
  Future<List<ChatConversation>> conversations();

  /// Officers the user can start a fresh conversation with — i.e. those not
  /// already in a one-to-one [conversations] thread.
  Future<List<ChatContact>> availableContacts();

  /// All known contacts with no filter applied. Used by the group-picker.
  Future<List<ChatContact>> allContacts();

  /// Opens a conversation with [contact]: returns the existing thread if one
  /// exists, otherwise creates and stores an empty one. The returned thread is
  /// also added to [conversations].
  Future<ChatConversation> startConversation(ChatContact contact);

  /// Creates a new group thread with the given [name] and [members], stores it,
  /// and returns it. Repositories without group support throw.
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) =>
      throw UnsupportedError('This repository does not support group threads.');

  /// Returns the messages for a single thread, oldest first.
  Future<List<ChatMessage>> messagesFor(String conversationId);

  /// Sends [text] in the given thread and returns the server-confirmed message.
  Future<ChatMessage> sendMessage(String conversationId, String text);

  /// Tells the server that all messages in this thread have been read.
  Future<void> markRead(String conversationId);

  // --- Telegram-parity mutations -------------------------------------------

  Future<ChatMessage> editMessage(
    String conversationId,
    String messageId,
    String newText,
  ) =>
      throw UnsupportedError('This repository does not support message editing.');

  Future<void> deleteMessage(String conversationId, String messageId) =>
      throw UnsupportedError('This repository does not support message deletion.');

  Future<ChatMessage> togglePin(String conversationId, String messageId) =>
      throw UnsupportedError('This repository does not support message pinning.');

  /// Adds or removes the current user's [emoji] reaction; updates the tally.
  Future<ChatMessage> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) =>
      throw UnsupportedError('This repository does not support reactions.');

  Future<ChatMessage> forwardMessage(
    String fromConversationId,
    String messageId,
    String toConversationId,
  ) =>
      throw UnsupportedError('This repository does not support message forwarding.');

  /// Sends an attachment-bearing message. Call [uploadAttachment] first to
  /// obtain a [ChatAttachment] with a server-side URL.
  Future<ChatMessage> sendAttachment(
    String conversationId,
    ChatAttachment attachment, {
    required MessageType type,
    String text = '',
  }) =>
      throw UnsupportedError('This repository does not support attachments.');

  /// Uploads raw bytes and returns a [ChatAttachment] whose [url] is the
  /// remote storage location, ready to hand to [sendAttachment].
  Future<ChatAttachment> uploadAttachment(
    Uint8List bytes, {
    String? filename,
    String? mimeType,
  }) =>
      throw UnsupportedError('This repository does not support attachment uploads.');

  Future<List<ChatMessage>> searchMessages(
    String conversationId,
    String query,
  ) =>
      throw UnsupportedError('This repository does not support message search.');

  /// Signals the peer that the current user is composing. Fire-and-forget —
  /// callers need not await the result.
  Future<void> sendTyping(String conversationId) =>
      throw UnsupportedError('This repository does not support typing indicators.');

  /// Returns who (other than the current user) is typing in the thread right
  /// now. Repositories without live typing report nobody.
  Future<ChatTypingState> fetchTyping(String conversationId) =>
      Future.value(const ChatTypingState.idle());

  Future<void> markMessageRead(String conversationId, String messageId) =>
      throw UnsupportedError(
          'This repository does not support per-message read receipts.');
}

// ---------------------------------------------------------------------------
// In-memory implementation
// ---------------------------------------------------------------------------

/// In-memory implementation seeded with realistic JCF officer data.
///
/// The seed list is per-instance so that sessions are isolated and auth-scoped
/// replacements work correctly at the composition root.
class InMemoryChatRepository implements ChatRepository {
  InMemoryChatRepository();

  int _groupSequence = 0;
  static int _messageSequence = 0;

  final List<ChatConversation> _conversations = _buildSeedConversations();

  @override
  Future<List<ChatConversation>> conversations() async {
    _conversations.sort((a, b) {
      final aTime = a.lastMessage?.sentAt ?? DateTime(2000);
      final bTime = b.lastMessage?.sentAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return List<ChatConversation>.unmodifiable(_conversations);
  }

  @override
  Future<List<ChatContact>> availableContacts() async {
    final inThread = _conversations
        .where((conversation) => !conversation.isGroup)
        .map((conversation) => conversation.contact.id)
        .toSet();
    return _roster
        .where((contact) => !inThread.contains(contact.id))
        .toList(growable: false);
  }

  @override
  Future<List<ChatContact>> allContacts() async =>
      List<ChatContact>.unmodifiable(_roster);

  @override
  Future<ChatConversation> startConversation(ChatContact contact) async {
    final existing = _conversations.where((conversation) =>
        !conversation.isGroup && conversation.contact.id == contact.id);
    if (existing.isNotEmpty) return existing.first;
    final conversation = ChatConversation(
      id: 'conv-${contact.id}',
      contact: contact,
      messages: [],
    );
    _conversations.insert(0, conversation);
    return conversation;
  }

  @override
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) async {
    if (members.isEmpty) {
      throw ArgumentError('A group conversation needs at least one member.');
    }
    _groupSequence++;
    final group = ChatGroup(
      id: 'grp-new-$_groupSequence',
      name: name,
      members: List<ChatContact>.unmodifiable(members),
      avatarUrl: officerAvatar('grp-new-$_groupSequence'),
    );
    final conversation = ChatConversation(
      id: 'conv-${group.id}',
      contact: members.first,
      group: group,
      messages: [],
    );
    _conversations.insert(0, conversation);
    return conversation;
  }

  @override
  Future<List<ChatMessage>> messagesFor(String conversationId) async {
    final conversation = _requireConversation(conversationId);
    return List<ChatMessage>.unmodifiable(conversation.messages);
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    final index = _requireConversationIndex(conversationId);
    _messageSequence++;
    final message = ChatMessage(
      id: 'msg-sent-$_messageSequence',
      conversationId: conversationId,
      text: text,
      sentAt: DateTime.now().toUtc(),
      fromMe: true,
      status: MessageStatus.delivered,
    );
    _conversations[index].messages.add(message);
    return message;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final conversation =
        _conversations.where((c) => c.id == conversationId).firstOrNull;
    conversation?.markRead();
  }

  // --- Telegram-parity mutations -------------------------------------------

  @override
  Future<ChatMessage> editMessage(
    String conversationId,
    String messageId,
    String newText,
  ) async {
    final original = _requireMessage(conversationId, messageId);
    final updated =
        original.copyWith(text: newText.trim(), editedAt: DateTime.now().toUtc());
    _replaceMessage(conversationId, updated);
    return updated;
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final original = _requireMessage(conversationId, messageId);
    _replaceMessage(
      conversationId,
      original.copyWith(isDeleted: true, text: '', reactions: const []),
    );
  }

  @override
  Future<ChatMessage> togglePin(
      String conversationId, String messageId) async {
    final original = _requireMessage(conversationId, messageId);
    final updated = original.copyWith(isPinned: !original.isPinned);
    _replaceMessage(conversationId, updated);
    return updated;
  }

  @override
  Future<ChatMessage> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final original = _requireMessage(conversationId, messageId);
    final updated =
        original.copyWith(reactions: _updatedReactions(original.reactions, emoji));
    _replaceMessage(conversationId, updated);
    return updated;
  }

  @override
  Future<ChatMessage> forwardMessage(
    String fromConversationId,
    String messageId,
    String toConversationId,
  ) async {
    final original = _requireMessage(fromConversationId, messageId);
    final index = _requireConversationIndex(toConversationId);
    _messageSequence++;
    final forwarded = ChatMessage(
      id: 'msg-fwd-$_messageSequence',
      conversationId: toConversationId,
      text: original.text,
      sentAt: DateTime.now().toUtc(),
      fromMe: true,
      status: MessageStatus.sent,
      type: original.type,
      attachment: original.attachment,
      isForwarded: true,
      forwardedFrom:
          original.senderName ?? original.forwardedFrom ?? 'Unknown',
    );
    _conversations[index].messages.add(forwarded);
    return forwarded;
  }

  @override
  Future<ChatMessage> sendAttachment(
    String conversationId,
    ChatAttachment attachment, {
    required MessageType type,
    String text = '',
  }) async {
    final index = _requireConversationIndex(conversationId);
    _messageSequence++;
    final message = ChatMessage(
      id: 'msg-att-$_messageSequence',
      conversationId: conversationId,
      text: text.trim(),
      sentAt: DateTime.now().toUtc(),
      fromMe: true,
      status: MessageStatus.sent,
      type: type,
      attachment: attachment,
    );
    _conversations[index].messages.add(message);
    return message;
  }

  @override
  Future<ChatAttachment> uploadAttachment(
    Uint8List bytes, {
    String? filename,
    String? mimeType,
  }) async {
    _messageSequence++;
    return ChatAttachment(
      url: 'local://attachment-$_messageSequence',
      name: filename,
      sizeBytes: bytes.length,
      mimeType: mimeType,
    );
  }

  @override
  Future<List<ChatMessage>> searchMessages(
    String conversationId,
    String query,
  ) async {
    final conversation = _requireConversation(conversationId);
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    return conversation.messages
        .where((m) => !m.isDeleted && m.text.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  @override
  Future<void> sendTyping(String conversationId) async {
    // No-op: no network layer to notify.
  }

  @override
  Future<ChatTypingState> fetchTyping(String conversationId) async =>
      const ChatTypingState.idle();

  @override
  Future<void> markMessageRead(
      String conversationId, String messageId) async {
    final original = _requireMessage(conversationId, messageId);
    if (original.status == MessageStatus.read) return;
    _replaceMessage(
        conversationId, original.copyWith(status: MessageStatus.read));
  }

  // --- Private helpers -----------------------------------------------------

  int _requireConversationIndex(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      throw StateError('No conversation with id $conversationId');
    }
    return index;
  }

  ChatConversation _requireConversation(String conversationId) =>
      _conversations[_requireConversationIndex(conversationId)];

  ChatMessage _requireMessage(String conversationId, String messageId) {
    final conversation = _requireConversation(conversationId);
    final found =
        conversation.messages.where((m) => m.id == messageId).firstOrNull;
    if (found == null) {
      throw StateError(
          'No message $messageId in conversation $conversationId');
    }
    return found;
  }

  void _replaceMessage(String conversationId, ChatMessage updated) {
    final convIndex = _requireConversationIndex(conversationId);
    final msgIndex = _conversations[convIndex]
        .messages
        .indexWhere((m) => m.id == updated.id);
    if (msgIndex == -1) return;
    _conversations[convIndex].messages[msgIndex] = updated;
  }

  List<MessageReaction> _updatedReactions(
    List<MessageReaction> current,
    String emoji,
  ) {
    final reactions = List<MessageReaction>.from(current);
    final index = reactions.indexWhere((r) => r.emoji == emoji);
    if (index == -1) {
      reactions.add(MessageReaction(emoji: emoji, count: 1, byMe: true));
      return reactions;
    }
    final existing = reactions[index];
    if (existing.byMe) {
      final newCount = existing.count - 1;
      if (newCount <= 0) {
        reactions.removeAt(index);
      } else {
        reactions[index] = existing.copyWith(count: newCount, byMe: false);
      }
    } else {
      reactions[index] =
          existing.copyWith(count: existing.count + 1, byMe: true);
    }
    return reactions;
  }

  /// Roster of officers available to start a new conversation with.
  static final List<ChatContact> _roster = [
    ChatContact(
      id: 'off-201',
      name: 'Marlon Stewart',
      rank: 'Sergeant',
      station: 'Denham Town',
      avatarUrl: officerAvatar('off-201'),
      isOnline: true,
    ),
    ChatContact(
      id: 'off-202',
      name: 'Camille Foster',
      rank: 'Inspector',
      station: 'St. Catherine North',
      avatarUrl: officerAvatar('off-202'),
      lastSeen: DateTime(2026, 5, 31, 8, 40),
    ),
    ChatContact(
      id: 'off-203',
      name: 'Ricardo Bennett',
      rank: 'Constable',
      station: 'Portmore',
      avatarUrl: officerAvatar('off-203'),
      isOnline: true,
    ),
    ChatContact(
      id: 'off-204',
      name: 'Shelly-Ann Grant',
      rank: 'Detective Sergeant',
      station: 'MOCA',
      avatarUrl: officerAvatar('off-204'),
      lastSeen: DateTime(2026, 5, 30, 19, 12),
    ),
    ChatContact(
      id: 'off-205',
      name: 'Andre Walker',
      rank: 'Corporal',
      station: 'Mandeville',
      avatarUrl: officerAvatar('off-205'),
      lastSeen: DateTime(2026, 5, 31, 6, 5),
    ),
    ChatContact(
      id: 'off-206',
      name: 'Keisha Morgan',
      rank: 'Superintendent',
      station: 'Area 4 HQ',
      avatarUrl: officerAvatar('off-206'),
      isOnline: true,
    ),
  ];

  /// Members of the seeded demonstration group.
  static final List<ChatContact> _groupMembers = [
    _roster[0],
    _roster[2],
    _roster[5],
  ];

  /// Builds the seed conversation list and marks every thread read so that
  /// no phantom unread badges appear on first launch.
  static List<ChatConversation> _buildSeedConversations() {
    final list = [
      ChatConversation(
        id: 'conv-grp-901',
        contact: _groupMembers.first,
        group: ChatGroup(
          id: 'grp-901',
          name: 'Operation Restore Order',
          members: _groupMembers,
          avatarUrl: officerAvatar('grp-901'),
        ),
        messages: [
          ChatMessage(
            id: 'msg-901-1',
            text: 'Team, briefing at 06:00 sharp at Area 4 HQ. Full kit.',
            sentAt: DateTime(2026, 5, 31, 5, 10),
            fromMe: false,
            senderName: 'Keisha Morgan',
          ),
          ChatMessage(
            id: 'msg-901-2',
            text: 'Copy. Denham Town unit will be there.',
            sentAt: DateTime(2026, 5, 31, 5, 14),
            fromMe: false,
            senderName: 'Marlon Stewart',
          ),
          ChatMessage(
            id: 'msg-901-3',
            text: 'Understood. Rolling out from Portmore now.',
            sentAt: DateTime(2026, 5, 31, 5, 18),
            fromMe: true,
            status: MessageStatus.read,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-001',
        contact: ChatContact(
          id: 'off-101',
          name: 'Tamara Brown',
          rank: 'Sergeant',
          station: 'Half-Way-Tree',
          avatarUrl: officerAvatar('off-101'),
          isOnline: true,
        ),
        messages: [
          ChatMessage(
            id: 'msg-001-1',
            text:
                'Good morning Constable. Please confirm the patrol roster for tonight.',
            sentAt: DateTime(2026, 5, 30, 7, 15),
            fromMe: false,
          ),
          ChatMessage(
            id: 'msg-001-2',
            text: 'Morning Sarge. Roster confirmed — four officers on Echo shift.',
            sentAt: DateTime(2026, 5, 30, 7, 22),
            fromMe: true,
            status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'msg-001-3',
            text: 'Copy that. Ensure they sign the duty log before deployment.',
            sentAt: DateTime(2026, 5, 30, 7, 25),
            fromMe: false,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-002',
        contact: ChatContact(
          id: 'off-102',
          name: 'Devon Clarke',
          rank: 'Inspector',
          station: 'Barnett Street',
          avatarUrl: officerAvatar('off-102'),
          lastSeen: DateTime(2026, 5, 31, 7, 50),
        ),
        messages: [
          ChatMessage(
            id: 'msg-002-1',
            text:
                "The exhibit from last night's seizure has been logged under EX-2026-0891.",
            sentAt: DateTime(2026, 5, 29, 22, 40),
            fromMe: false,
          ),
          ChatMessage(
            id: 'msg-002-2',
            text:
                'Acknowledged Inspector. I will update the case file first thing tomorrow.',
            sentAt: DateTime(2026, 5, 29, 22, 47),
            fromMe: true,
            status: MessageStatus.read,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-003',
        contact: ChatContact(
          id: 'off-103',
          name: 'Nadine Wright',
          rank: 'Corporal',
          station: 'CTOC',
          avatarUrl: officerAvatar('off-103'),
          isOnline: true,
        ),
        messages: [
          ChatMessage(
            id: 'msg-003-1',
            text: 'Can you send over the intelligence brief for Operation Curtain?',
            sentAt: DateTime(2026, 5, 31, 9, 5),
            fromMe: true,
            status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'msg-003-2',
            text: 'Sending it through secure channel now. Check your inbox.',
            sentAt: DateTime(2026, 5, 31, 9, 11),
            fromMe: false,
          ),
          ChatMessage(
            id: 'msg-003-3',
            text: 'Received. Thank you Corporal.',
            sentAt: DateTime(2026, 5, 31, 9, 14),
            fromMe: true,
            status: MessageStatus.delivered,
          ),
          ChatMessage(
            id: 'msg-003-4',
            text: 'Stand by — the ACP wants an update by 14:00.',
            sentAt: DateTime(2026, 5, 31, 9, 18),
            fromMe: false,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-004',
        contact: ChatContact(
          id: 'off-104',
          name: 'Omar Reid',
          rank: 'Constable',
          station: 'Spanish Town',
          avatarUrl: officerAvatar('off-104'),
          lastSeen: DateTime(2026, 5, 28, 15, 5),
        ),
        messages: [
          ChatMessage(
            id: 'msg-004-1',
            text: 'Vehicle check on plate PB7341 came back clear.',
            sentAt: DateTime(2026, 5, 28, 14, 30),
            fromMe: false,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-005',
        contact: ChatContact(
          id: 'off-105',
          name: 'Patricia Henry',
          rank: 'Superintendent',
          station: 'Kingston Central',
          avatarUrl: officerAvatar('off-105'),
        ),
        messages: [
          ChatMessage(
            id: 'msg-005-1',
            text: "Ensure your division's stats are submitted by Friday COB.",
            sentAt: DateTime(2026, 5, 27, 11, 0),
            fromMe: false,
          ),
          ChatMessage(
            id: 'msg-005-2',
            text: "Understood Ma'am. Will have them in by Thursday.",
            sentAt: DateTime(2026, 5, 27, 11, 8),
            fromMe: true,
            status: MessageStatus.read,
          ),
        ],
      ),
      ChatConversation(
        id: 'conv-006',
        contact: ChatContact(
          id: 'off-106',
          name: 'Garfield Thomas',
          rank: 'Detective Corporal',
          station: 'Hunts Bay',
          avatarUrl: officerAvatar('off-106'),
          isOnline: true,
        ),
        messages: [
          ChatMessage(
            id: 'msg-006-1',
            text:
                'Witness statement for case CR-2026-1144 is ready for your signature.',
            sentAt: DateTime(2026, 5, 26, 16, 45),
            fromMe: false,
          ),
          ChatMessage(
            id: 'msg-006-2',
            text: 'I will come by Hunts Bay tomorrow morning to sign.',
            sentAt: DateTime(2026, 5, 26, 17, 2),
            fromMe: true,
            status: MessageStatus.read,
          ),
          ChatMessage(
            id: 'msg-006-3',
            text: 'Works for me. I will be in from 08:00.',
            sentAt: DateTime(2026, 5, 26, 17, 10),
            fromMe: false,
          ),
        ],
      ),
    ];
    for (final conversation in list) {
      conversation.markRead();
    }
    return list;
  }
}

// ---------------------------------------------------------------------------
// HTTP implementation
// ---------------------------------------------------------------------------

/// HTTP-backed implementation of [ChatRepository] against the `v1/chat` routes.
///
/// Uses the same [ApiConfig] and [TokenProvider] infrastructure as
/// [HttpDocumentHubApiClient]. Wire this at the composition root in place of
/// [InMemoryChatRepository] once the API is reachable.
class HttpChatRepository implements ChatRepository {
  final ApiConfig _config;
  final TokenProvider _tokenProvider;
  final http.Client _httpClient;

  HttpChatRepository({
    ApiConfig config = const ApiConfig(),
    TokenProvider tokenProvider = const NullTokenProvider(),
    http.Client? httpClient,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<List<ChatConversation>> conversations() async {
    final uri = _resolve('/chat/conversations');
    final body = await _getJson(uri);
    final rawItems = body['items'] as List<dynamic>? ?? <dynamic>[];
    final list = rawItems
        .map((item) =>
            ChatConversation.fromJson(item as Map<String, dynamic>))
        .toList(growable: true);
    list.sort((a, b) {
      final aTime = a.lastMessage?.sentAt ?? DateTime(2000);
      final bTime = b.lastMessage?.sentAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  @override
  Future<List<ChatContact>> availableContacts() async {
    final all = await allContacts();
    final existing = await conversations();
    final inThread = existing
        .where((c) => !c.isGroup)
        .map((c) => c.contact.id)
        .toSet();
    return all.where((contact) => !inThread.contains(contact.id)).toList();
  }

  @override
  Future<List<ChatContact>> allContacts() async {
    final uri = _resolve('/chat/contacts');
    final body = await _getJson(uri);
    final rawItems = body['items'] as List<dynamic>? ?? <dynamic>[];
    return rawItems
        .map((item) => ChatContact.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ChatConversation> startConversation(ChatContact contact) async {
    final uri = _resolve('/chat/conversations');
    final payload = jsonEncode({'contact_id': contact.id});
    final body = await _postJson(uri, payload);
    return ChatConversation.fromJson(body);
  }

  @override
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) async {
    if (members.isEmpty) {
      throw ArgumentError('A group conversation needs at least one member.');
    }
    final uri = _resolve('/chat/conversations');
    final payload = jsonEncode({
      'name': name,
      'member_ids': members.map((m) => m.id).toList(),
    });
    final body = await _postJson(uri, payload);
    return ChatConversation.fromJson(body);
  }

  @override
  Future<List<ChatMessage>> messagesFor(String conversationId) async {
    final uri = _resolve('/chat/conversations/$conversationId/messages');
    final body = await _getJson(uri);
    final rawItems = body['items'] as List<dynamic>? ?? <dynamic>[];
    return rawItems
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    final uri = _resolve('/chat/conversations/$conversationId/messages');
    final payload = jsonEncode({'text': text});
    final body = await _postJson(uri, payload);
    return ChatMessage.fromJson(body);
  }

  @override
  Future<void> markRead(String conversationId) async {
    final uri = _resolve('/chat/conversations/$conversationId/read');
    await _postVoid(uri);
  }

  // --- Telegram-parity mutations -------------------------------------------

  @override
  Future<ChatMessage> editMessage(
    String conversationId,
    String messageId,
    String newText,
  ) async {
    final uri =
        _resolve('/chat/conversations/$conversationId/messages/$messageId');
    final payload = jsonEncode({'text': newText.trim()});
    final body = await _patchJson(uri, payload);
    return ChatMessage.fromJson(body);
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    final uri =
        _resolve('/chat/conversations/$conversationId/messages/$messageId');
    await _deleteRequest(uri);
  }

  @override
  Future<ChatMessage> togglePin(
      String conversationId, String messageId) async {
    final uri = _resolve(
        '/chat/conversations/$conversationId/messages/$messageId/pin');
    final body = await _postJson(uri, '{}');
    return ChatMessage.fromJson(body);
  }

  @override
  Future<ChatMessage> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final uri = _resolve(
        '/chat/conversations/$conversationId/messages/$messageId/reactions');
    final payload = jsonEncode({'emoji': emoji});
    final body = await _postJson(uri, payload);
    return ChatMessage.fromJson(body);
  }

  @override
  Future<ChatMessage> forwardMessage(
    String fromConversationId,
    String messageId,
    String toConversationId,
  ) async {
    final uri = _resolve(
        '/chat/conversations/$fromConversationId/messages/$messageId/forward');
    final payload = jsonEncode({'to_conversation_id': toConversationId});
    final body = await _postJson(uri, payload);
    return ChatMessage.fromJson(body);
  }

  @override
  Future<ChatMessage> sendAttachment(
    String conversationId,
    ChatAttachment attachment, {
    required MessageType type,
    String text = '',
  }) async {
    final uri = _resolve('/chat/conversations/$conversationId/messages');
    final payload = jsonEncode({
      'type': type.wire,
      'text': text.trim(),
      'attachment': attachment.toJson(),
    });
    final body = await _postJson(uri, payload);
    return ChatMessage.fromJson(body);
  }

  @override
  Future<ChatAttachment> uploadAttachment(
    Uint8List bytes, {
    String? filename,
    String? mimeType,
  }) async {
    final uri = _resolve('/chat/attachments');
    final token = await _tokenProvider.currentAccessToken();
    final file = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename ?? 'attachment',
    );
    final request = http.MultipartRequest('POST', uri)
      ..files.add(file)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (mimeType != null) request.fields['mime_type'] = mimeType;
    if (filename != null) request.fields['filename'] = filename;
    final response = await _sendMultipart(request);
    _throwForStatus(response);
    return ChatAttachment.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  @override
  Future<List<ChatMessage>> searchMessages(
    String conversationId,
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final uri = _resolve(
      '/chat/conversations/$conversationId/search',
      {'q': trimmed},
    );
    final body = await _getJson(uri);
    final rawItems = body['items'] as List<dynamic>? ?? <dynamic>[];
    return rawItems
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<void> sendTyping(String conversationId) async {
    final uri = _resolve('/chat/conversations/$conversationId/typing');
    await _postVoid(uri);
  }

  @override
  Future<ChatTypingState> fetchTyping(String conversationId) async {
    final uri = _resolve('/chat/conversations/$conversationId/typing');
    try {
      final body = await _getJson(uri);
      final usernames = (body['usernames'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false);
      return ChatTypingState(
        isTyping: body['is_typing'] as bool? ?? usernames.isNotEmpty,
        usernames: usernames,
      );
    } catch (_) {
      return const ChatTypingState.idle();
    }
  }

  @override
  Future<void> markMessageRead(
      String conversationId, String messageId) async {
    final uri = _resolve(
        '/chat/conversations/$conversationId/messages/$messageId/read');
    await _postVoid(uri);
  }

  // --- HTTP helpers ---------------------------------------------------------

  Uri _resolve(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final headers = await _buildHeaders();
    final response =
        await _execute(() => _httpClient.get(uri, headers: headers));
    _throwForStatus(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _postJson(Uri uri, String payload) async {
    final headers = await _buildHeaders(
      extra: {'Content-Type': 'application/json'},
    );
    final response = await _execute(
      () => _httpClient.post(uri, headers: headers, body: payload),
    );
    _throwForStatus(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _patchJson(Uri uri, String payload) async {
    final headers = await _buildHeaders(
      extra: {'Content-Type': 'application/json'},
    );
    final response = await _execute(
      () => _httpClient.patch(uri, headers: headers, body: payload),
    );
    _throwForStatus(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> _deleteRequest(Uri uri) async {
    final headers = await _buildHeaders();
    final response =
        await _execute(() => _httpClient.delete(uri, headers: headers));
    _throwForStatus(response);
  }

  Future<void> _postVoid(Uri uri, [String body = '']) async {
    final headers = await _buildHeaders(
      extra: {'Content-Type': 'application/json'},
    );
    final response = await _execute(
      () => _httpClient.post(uri, headers: headers, body: body),
    );
    _throwForStatus(response);
  }

  Future<http.Response> _sendMultipart(http.MultipartRequest request) async {
    try {
      final streamed = await request.send().timeout(_config.timeout);
      return http.Response.fromStream(streamed);
    } on SocketException catch (error) {
      throw NetworkException('Network unreachable: ${error.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on http.ClientException catch (error) {
      throw NetworkException(error.message);
    }
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_config.timeout);
    } on SocketException catch (error) {
      throw NetworkException('Network unreachable: ${error.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on http.ClientException catch (error) {
      throw NetworkException(error.message);
    }
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? extra,
  }) async {
    final token = await _tokenProvider.currentAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final envelope = _parseErrorEnvelope(response);
    final code = envelope.errorCode;
    final id = envelope.requestId;
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(envelope.message,
            errorCode: code, requestId: id);
      case 401:
        throw UnauthorizedException(envelope.message,
            errorCode: code, requestId: id);
      case 403:
        throw ForbiddenException(envelope.message,
            errorCode: code, requestId: id);
      case 404:
        throw NotFoundException(envelope.message,
            errorCode: code, requestId: id);
      case 429:
        throw RateLimitedException(
          envelope.message,
          _config.fallbackRetryDelayWhenHeaderMissing,
          errorCode: code,
          requestId: id,
        );
      default:
        if (response.statusCode >= 500) {
          throw ServerException(envelope.message,
              errorCode: code, requestId: id);
        }
        throw ApiException(envelope.message, errorCode: code, requestId: id);
    }
  }

  _ErrorEnvelope _parseErrorEnvelope(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return _ErrorEnvelope(
          message: (body['message'] as String?) ?? 'HTTP ${response.statusCode}',
          errorCode: body['error'] as String?,
          requestId: body['request_id'] as String?,
        );
      }
    } catch (_) {
      // fall through to default envelope
    }
    return _ErrorEnvelope(message: 'HTTP ${response.statusCode}');
  }
}

class _ErrorEnvelope {
  final String message;
  final String? errorCode;
  final String? requestId;

  const _ErrorEnvelope({required this.message, this.errorCode, this.requestId});
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/chat/chat_attachment.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_reaction.dart';
import '../../models/chat/message_type.dart';
import '../../services/chat/chat_repository.dart';

/// Owns the live message list for one open thread and exposes every mutation the
/// chat features need. Widgets listen for rebuilds and call the typed methods
/// below instead of touching [ChatConversation.messages] directly — this is the
/// single integration seam the chat feature widgets share.
///
/// The controller is deliberately backend-agnostic: it mutates the in-memory
/// model so the UI is responsive, and an optional [onSend]-style hook can later
/// forward the same actions to [ChatRepository] without changing call sites.
class ChatThreadController extends ChangeNotifier {
  ChatThreadController(this.conversation, {ChatRepository? repository})
      : _repository = repository;

  final ChatConversation conversation;

  /// When present, every send is forwarded to the live backend and the thread
  /// syncs from the server. When null, the controller runs the in-memory demo.
  final ChatRepository? _repository;

  /// True when a live backend is wired in, so the screen can disable demo-only
  /// behaviour such as the canned auto-reply.
  bool get isBackedByServer => _repository != null;

  bool _disposed = false;

  /// Monotonic counter for locally-created message ids. Avoids `DateTime.now()`
  /// collisions when several messages are created in the same millisecond.
  int _localSequence = 0;

  /// Whether the other party is currently typing, per the last server sync.
  bool _peerTyping = false;
  bool get peerTyping => _peerTyping;

  /// Name to show beside the typing dots in a group thread; null for 1-to-1.
  String? _typistName;
  String? get typistName => _typistName;

  /// Last time we told the server the current user is composing, for throttling.
  DateTime? _lastTypingSentAt;

  /// Id of the message currently being replied to, or null. The composer reads
  /// this to show its quoted preview bar.
  ChatMessage? _replyingTo;
  ChatMessage? get replyingTo => _replyingTo;

  /// Id of the message currently being edited, or null.
  ChatMessage? _editing;
  ChatMessage? get editing => _editing;

  /// Active per-thread disappearing-message lifetime, applied to new messages.
  int? _disappearingTtlSeconds;
  int? get disappearingTtlSeconds => _disappearingTtlSeconds;

  List<ChatMessage> get messages => conversation.messages;

  bool get isGroup => conversation.isGroup;

  /// The pinned message, or null when nothing is pinned. Only the most recent
  /// pin is surfaced in the thread banner.
  ChatMessage? get pinnedMessage {
    for (final message in messages.reversed) {
      if (message.isPinned && !message.isDeleted) return message;
    }
    return null;
  }

  String _nextLocalId(String kind) =>
      'msg-$kind-${++_localSequence}-${messages.length}';

  // --- Compose state ------------------------------------------------------

  void beginReply(ChatMessage target) {
    _replyingTo = target;
    _editing = null;
    _notify();
  }

  void beginEdit(ChatMessage target) {
    _editing = target;
    _replyingTo = null;
    _notify();
  }

  void clearCompose() {
    _replyingTo = null;
    _editing = null;
    _notify();
  }

  void setDisappearing(int? ttlSeconds) {
    _disappearingTtlSeconds = ttlSeconds;
    _notify();
  }

  // --- Sending ------------------------------------------------------------

  /// Sends a plain-text (or reply) message from the current user and returns it.
  ChatMessage sendText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Cannot send an empty message.');
    }
    final reply = _replyingTo;
    final message = ChatMessage(
      id: _nextLocalId('sent'),
      conversationId: conversation.id,
      text: trimmed,
      sentAt: _now(),
      fromMe: true,
      status: MessageStatus.sent,
      replyToId: reply?.id,
      replyToPreview: reply?.preview,
      replyToSender: reply == null
          ? null
          : (reply.fromMe ? 'You' : (reply.senderName ?? conversation.title)),
      ttlSeconds: _disappearingTtlSeconds,
    );
    _append(message);
    _replyingTo = null;
    unawaited(_forwardToServer(trimmed));
    return message;
  }

  /// Sends an attachment-bearing message (voice/image/file).
  ChatMessage sendAttachment(
    ChatAttachment attachment, {
    required MessageType type,
    String text = '',
  }) {
    final reply = _replyingTo;
    final message = ChatMessage(
      id: _nextLocalId(type.wire),
      conversationId: conversation.id,
      text: text.trim(),
      sentAt: _now(),
      fromMe: true,
      status: MessageStatus.sent,
      type: type,
      attachment: attachment,
      replyToId: reply?.id,
      replyToPreview: reply?.preview,
      replyToSender:
          reply == null ? null : (reply.fromMe ? 'You' : reply.senderName),
      ttlSeconds: _disappearingTtlSeconds,
    );
    _append(message);
    _replyingTo = null;
    unawaited(_forwardAttachmentToServer(attachment, type, message.text));
    return message;
  }

  /// Forwards [original] into this thread, tagging its origin.
  ChatMessage forwardIn(ChatMessage original, {String? fromLabel}) {
    final message = ChatMessage(
      id: _nextLocalId('fwd'),
      conversationId: conversation.id,
      text: original.text,
      sentAt: _now(),
      fromMe: true,
      status: MessageStatus.sent,
      type: original.type,
      attachment: original.attachment,
      isForwarded: true,
      forwardedFrom:
          fromLabel ?? original.senderName ?? original.forwardedFrom ?? 'Unknown',
    );
    _append(message);
    return message;
  }

  /// Appends an inbound message (used by auto-reply / simulated peers).
  ChatMessage receive(ChatMessage inbound) {
    _append(inbound);
    return inbound;
  }

  // --- Editing message content -------------------------------------------

  void applyEdit(String messageId, String newText) {
    _replace(messageId, (m) => m.copyWith(text: newText.trim(), editedAt: _now()));
    _editing = null;
  }

  void deleteMessage(String messageId) {
    _replace(
      messageId,
      (m) => m.copyWith(isDeleted: true, text: '', reactions: const []),
    );
  }

  void togglePin(String messageId) {
    _replace(messageId, (m) => m.copyWith(isPinned: !m.isPinned));
  }

  // --- Reactions ----------------------------------------------------------

  /// Toggles [emoji] on a message for the current user, updating the tally.
  void toggleReaction(String messageId, String emoji) {
    _replace(messageId, (m) {
      final reactions = List<MessageReaction>.from(m.reactions);
      final index = reactions.indexWhere((r) => r.emoji == emoji);
      if (index == -1) {
        reactions.add(MessageReaction(emoji: emoji, count: 1, byMe: true));
      } else {
        final current = reactions[index];
        if (current.byMe) {
          final count = current.count - 1;
          if (count <= 0) {
            reactions.removeAt(index);
          } else {
            reactions[index] = current.copyWith(count: count, byMe: false);
          }
        } else {
          reactions[index] = current.copyWith(count: current.count + 1, byMe: true);
        }
      }
      return m.copyWith(reactions: reactions);
    });
  }

  // --- Read state ---------------------------------------------------------

  /// Promotes every outbound message to read (peer has seen them).
  void markMyMessagesRead() {
    var changed = false;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.fromMe && m.status != MessageStatus.read) {
        messages[i] = m.copyWith(status: MessageStatus.read);
        changed = true;
      }
    }
    if (changed) _notify();
  }

  void markThreadRead() {
    conversation.markRead();
    _notify();
  }

  // --- Lookup -------------------------------------------------------------

  ChatMessage? messageById(String id) {
    for (final m in messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Indices of messages whose text contains [query] (case-insensitive).
  List<int> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final hits = <int>[];
    for (var i = 0; i < messages.length; i++) {
      if (!messages[i].isDeleted &&
          messages[i].text.toLowerCase().contains(needle)) {
        hits.add(i);
      }
    }
    return hits;
  }

  // --- Server sync --------------------------------------------------------

  /// Replaces the local message list with the server's copy of this thread.
  /// Only notifies listeners when the contents actually changed, so the list
  /// view does not rebuild (and fight scrolling) on idle polls.
  Future<void> syncFromServer() async {
    final repository = _repository;
    if (repository == null) return;

    var changed = false;

    List<ChatMessage>? fetched;
    try {
      fetched = await repository.messagesFor(conversation.id);
    } catch (_) {
      fetched = null;
    }
    if (_disposed) return;
    if (fetched != null && !_sameMessages(fetched)) {
      messages
        ..clear()
        ..addAll(fetched);
      changed = true;
    }

    try {
      final typing = await repository.fetchTyping(conversation.id);
      final name = isGroup && typing.usernames.isNotEmpty
          ? typing.usernames.first
          : null;
      if (typing.isTyping != _peerTyping || name != _typistName) {
        _peerTyping = typing.isTyping;
        _typistName = name;
        changed = true;
      }
    } catch (_) {
      // Typing is best-effort; leave the last known state on failure.
    }

    if (_disposed || !changed) return;
    _notify();
  }

  /// Tells the backend the current user is composing. Throttled to one ping per
  /// few seconds so a burst of keystrokes is a single request. Fire-and-forget.
  void userIsTyping() {
    final repository = _repository;
    if (repository == null) return;
    final now = _now();
    final last = _lastTypingSentAt;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    _lastTypingSentAt = now;
    unawaited(_sendTypingSafely(repository));
  }

  Future<void> _sendTypingSafely(ChatRepository repository) async {
    try {
      await repository.sendTyping(conversation.id);
    } catch (_) {
      // Offline / transient — the indicator simply won't show this round.
    }
  }

  bool _sameMessages(List<ChatMessage> incoming) {
    if (incoming.length != messages.length) return false;
    for (var i = 0; i < incoming.length; i++) {
      if (incoming[i].id != messages[i].id ||
          incoming[i].text != messages[i].text ||
          incoming[i].status != messages[i].status) {
        return false;
      }
    }
    return true;
  }

  /// Fire-and-forget send to the backend. Network failures are swallowed so a
  /// dropped request never crashes the composer; the optimistic local message
  /// stays put and the next sync reconciles it.
  Future<void> _forwardToServer(String text) async {
    final repository = _repository;
    if (repository == null || text.isEmpty) return;
    try {
      await repository.sendMessage(conversation.id, text);
    } catch (_) {
      // Offline / transient error — keep the optimistic message; sync recovers.
    }
  }

  /// Persists an attachment message (voice/image/file) to the backend so it
  /// survives the server sync. Without this the optimistic bubble is wiped by
  /// the next poll because the attachment never reached the server.
  Future<void> _forwardAttachmentToServer(
    ChatAttachment attachment,
    MessageType type,
    String text,
  ) async {
    final repository = _repository;
    if (repository == null) return;
    try {
      await repository.sendAttachment(
        conversation.id,
        attachment,
        type: type,
        text: text,
      );
    } catch (_) {
      // Offline / transient error — keep the optimistic message; sync recovers.
    }
  }

  // --- internals ----------------------------------------------------------

  void _append(ChatMessage message) {
    messages.add(message);
    _notify();
  }

  void _replace(String messageId, ChatMessage Function(ChatMessage) update) {
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;
    messages[index] = update(messages[index]);
    _notify();
  }

  /// Single timestamp source. Kept here so a test clock can be injected later
  /// without every feature widget importing DateTime.
  DateTime _now() => DateTime.now();

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

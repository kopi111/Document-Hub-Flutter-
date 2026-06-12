import 'package:flutter/material.dart';

import '../../models/chat/chat_contact.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../services/chat/chat_repository.dart';
import 'chat_style.dart';
import 'chat_presence.dart';
import 'chat_thread_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key, this.repository});

  final ChatRepository? repository;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatRepository _repository =
      widget.repository ?? InMemoryChatRepository();

  List<ChatConversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final result = await _repository.conversations();
      if (!mounted) return;
      setState(() {
        _conversations = result;
        _loading = false;
        _error = null; // clear any prior failure so a good reload recovers
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load messages: $error';
        _loading = false;
      });
    }
  }

  Future<void> _openThread(ChatConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          conversation: conversation,
          repository: _repository,
        ),
      ),
    );
    if (!mounted) return;
    await _loadConversations();
  }

  Future<void> _startNewConversation() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => NewChatScreen(repository: _repository),
      ),
    );
    if (!mounted || result == null) return;

    final ChatConversation conversation;
    if (result is ChatConversation) {
      conversation = result;
    } else if (result is ChatContact) {
      conversation = await _repository.startConversation(result);
    } else {
      return;
    }

    await _loadConversations();
    if (!mounted) return;
    await _openThread(conversation);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatStyle.theme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _startNewConversation,
          backgroundColor: ChatStyle.gold,
          foregroundColor: ChatStyle.onGold,
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            'New',
            style: ChatStyle.title(
              size: 14,
              weight: FontWeight.w700,
              color: ChatStyle.onGold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ChatStyle.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: ChatStyle.body(color: ChatStyle.textPrimary)),
      );
    }
    if (_conversations.isEmpty) {
      return Center(
        child: Text(
          'No conversations',
          style: ChatStyle.body(color: ChatStyle.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      color: ChatStyle.gold,
      backgroundColor: ChatStyle.surface,
      onRefresh: _loadConversations,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          thickness: 1,
          indent: ChatStyle.pageInset + 56 + 12,
          endIndent: ChatStyle.pageInset,
          color: ChatStyle.hairline,
        ),
        itemBuilder: (context, index) => _ConversationTile(
          conversation: _conversations[index],
          onTap: () => _openThread(_conversations[index]),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = conversation.lastMessage;
    final hasMessages = last != null && last.text.isNotEmpty;
    final unread = conversation.unreadCount;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatStyle.pageInset,
          vertical: 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ChatPresenceAvatar(
              initials: conversation.avatarInitials,
              avatarUrl: conversation.avatarUrl,
              isGroup: conversation.isGroup,
              isOnline: conversation.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (conversation.isGroup) ...[
                        const Icon(
                          Icons.groups_rounded,
                          size: 15,
                          color: ChatStyle.gold,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          conversation.title,
                          style: ChatStyle.title(
                            size: 15,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasMessages)
                        Text(
                          _formatTime(last.sentAt),
                          style: ChatStyle.mono(
                            size: 10,
                            color: ChatStyle.textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasMessages ? _previewText(last) : 'No messages yet',
                          style: ChatStyle.body(
                            size: 14,
                            color: ChatStyle.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: unread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime sentAt) {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Last-message preview, prefixed with the speaker the way WhatsApp does:
  /// "You: …" for outbound, "FirstName: …" for inbound group messages.
  String _previewText(ChatMessage last) {
    if (last.fromMe) return 'You: ${last.text}';
    if (conversation.isGroup && last.senderName != null) {
      return '${last.senderName!.split(' ').first}: ${last.text}';
    }
    return last.text;
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: ChatStyle.unread,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: ChatStyle.title(
          size: 12,
          weight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import 'chat_style.dart';
import 'chat_presence.dart';
import 'chat_wallpaper.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  static const List<String> _cannedReplies = [
    'Copy that.',
    'Understood, will action.',
    'Noted, thanks.',
    'Roger. Standing by.',
    'Acknowledged.',
    'On it — give me a few minutes.',
  ];

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _replyTimer;
  bool _isContactTyping = false;
  String? _typingName;

  ChatConversation get _conversation => widget.conversation;
  List<ChatMessage> get _messages => _conversation.messages;

  @override
  void initState() {
    super.initState();
    // Opening the thread clears its unread count and lands on the newest message.
    _conversation.markRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final outgoing = ChatMessage(
      id: 'msg-sent-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      sentAt: DateTime.now(),
      fromMe: true,
      status: MessageStatus.sent,
    );

    setState(() {
      _messages.add(outgoing);
      _inputController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _scheduleAutoReply();
  }

  void _scheduleAutoReply() {
    _replyTimer?.cancel();
    final replier = _nextReplier();
    setState(() {
      _isContactTyping = true;
      _typingName = replier;
    });
    _replyTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() {
        _isContactTyping = false;
        _markMyMessagesRead();
        _messages.add(
          ChatMessage(
            id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
            text: _nextReply(),
            sentAt: DateTime.now(),
            fromMe: false,
            senderName: _conversation.isGroup ? replier : null,
          ),
        );
        // The user is viewing the thread, so the reply is already seen.
        _conversation.markRead();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  /// The officer who will reply next. In a group this rotates through the
  /// members so different names appear; in a one-to-one it is the contact.
  String _nextReplier() {
    if (!_conversation.isGroup) return _conversation.contact.name;
    final members = _conversation.group!.members;
    if (members.isEmpty) return _conversation.contact.name;
    final replyCount = _messages.where((message) => !message.fromMe).length;
    return members[replyCount % members.length].name;
  }

  String _nextReply() {
    final replyCount = _messages.where((message) => !message.fromMe).length;
    return _cannedReplies[replyCount % _cannedReplies.length];
  }

  /// Promotes every message the user sent to "read" once the contact responds,
  /// turning the ticks blue like WhatsApp.
  void _markMyMessagesRead() {
    for (var i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      if (message.fromMe && message.status != MessageStatus.read) {
        _messages[i] = message.copyWith(status: MessageStatus.read);
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatStyle.theme(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: ChatWallpaper(
          child: Column(
            children: [
              Expanded(
                child: _MessageList(
                  messages: _messages,
                  isGroup: _conversation.isGroup,
                  scrollController: _scrollController,
                ),
              ),
              if (_isContactTyping)
                _TypingIndicator(name: _typingName ?? _conversation.title),
              _MessageInputRow(
                controller: _inputController,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          ChatPresenceAvatar(
            initials: _conversation.avatarInitials,
            avatarUrl: _conversation.avatarUrl,
            isGroup: _conversation.isGroup,
            isOnline: _conversation.isOnline,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _conversation.title,
                  style: ChatStyle.title(
                    size: 16,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isContactTyping ? 'typing…' : _conversation.subtitle,
                  style: ChatStyle.body(
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ChatStyle.pageInset,
        vertical: 6,
      ),
      child: Text(
        '$name is typing…',
        style: ChatStyle.body(size: 12, color: ChatStyle.textSecondary),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isGroup,
    required this.scrollController,
  });

  final List<ChatMessage> messages;
  final bool isGroup;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet. Start the conversation.',
          style: ChatStyle.body(color: ChatStyle.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: ChatStyle.pageInset,
        vertical: 12,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) => _MessageBubble(
        message: messages[index],
        precedingMessage: index > 0 ? messages[index - 1] : null,
        isGroup: isGroup,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isGroup,
    this.precedingMessage,
  });

  final ChatMessage message;
  final ChatMessage? precedingMessage;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final showTimestamp = _shouldShowTimestamp();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTimestamp) _TimestampLabel(sentAt: message.sentAt),
        Align(
          alignment:
              message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: _BubbleBody(message: message, isGroup: isGroup),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  bool _shouldShowTimestamp() {
    if (precedingMessage == null) return true;
    final gap = message.sentAt.difference(precedingMessage!.sentAt);
    return gap.inMinutes >= 10;
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.message, required this.isGroup});

  final ChatMessage message;
  final bool isGroup;

  static const List<Color> _senderPalette = [
    Color(0xFF53BDEB),
    Color(0xFF7FD06B),
    Color(0xFFE07C68),
    Color(0xFFC58AF0),
    Color(0xFFF0B05A),
  ];

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        message.fromMe ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble;

    const textColor = ChatStyle.textPrimary;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(ChatStyle.bubbleRadius),
      topRight: const Radius.circular(ChatStyle.bubbleRadius),
      bottomLeft: Radius.circular(message.fromMe ? ChatStyle.bubbleRadius : 4),
      bottomRight: Radius.circular(message.fromMe ? 4 : ChatStyle.bubbleRadius),
    );

    final showSender =
        isGroup && !message.fromMe && message.senderName != null;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSender)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                message.senderName!,
                style: ChatStyle.title(
                  size: 12,
                  weight: FontWeight.w700,
                  color: _senderColor(message.senderName!),
                ),
              ),
            ),
          Text(
            message.text,
            style: ChatStyle.body(size: 14, color: textColor),
          ),
          const SizedBox(height: 3),
          _BubbleFooter(message: message),
        ],
      ),
    );
  }

  Color _senderColor(String name) =>
      _senderPalette[name.hashCode.abs() % _senderPalette.length];
}

/// Time and, for outbound messages, the WhatsApp-style delivery ticks.
class _BubbleFooter extends StatelessWidget {
  const _BubbleFooter({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatTime(message.sentAt),
          style: ChatStyle.mono(
            size: 9,
            color: ChatStyle.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        if (message.fromMe) ...[
          const SizedBox(width: 4),
          _StatusTicks(status: message.status),
        ],
      ],
    );
  }

  String _formatTime(DateTime sentAt) {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusTicks extends StatelessWidget {
  const _StatusTicks({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final isRead = status == MessageStatus.read;
    final icon =
        status == MessageStatus.sent ? Icons.check_rounded : Icons.done_all_rounded;
    final color = isRead ? ChatStyle.readTick : ChatStyle.textSecondary;
    return Icon(icon, size: 15, color: color);
  }
}

class _TimestampLabel extends StatelessWidget {
  const _TimestampLabel({required this.sentAt});

  final DateTime sentAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatTimestamp(sentAt),
            style: ChatStyle.mono(
              size: 10,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi';
  }
}

class _MessageInputRow extends StatelessWidget {
  const _MessageInputRow({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ChatStyle.pageInset,
        8,
        ChatStyle.pageInset,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: ChatStyle.surface,
        border: Border(top: BorderSide(color: ChatStyle.hairline, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: ChatStyle.body(size: 14, color: ChatStyle.textPrimary),
              maxLines: 5,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle:
                    ChatStyle.body(size: 14, color: ChatStyle.textSecondary),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: ChatStyle.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChatStyle.cardRadius),
                  borderSide: BorderSide(color: ChatStyle.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChatStyle.cardRadius),
                  borderSide: BorderSide(color: ChatStyle.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChatStyle.cardRadius),
                  borderSide: BorderSide(color: ChatStyle.gold, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _SendButton(controller: controller, onPressed: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.controller, required this.onPressed});

  final TextEditingController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final enabled = value.text.trim().isNotEmpty;
        return Semantics(
          button: true,
          enabled: enabled,
          label: 'Send message',
          child: Material(
            color: enabled ? ChatStyle.gold : ChatStyle.hairline,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.send_rounded,
                  color: enabled ? ChatStyle.onGold : ChatStyle.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../models/chat/message_type.dart';
import '../../services/chat/chat_repository.dart';
import '../../services/chat/disappearing_sweeper.dart';
import '../../services/chat/file_attachment_picker.dart';
import '../../services/chat/image_attachment_picker.dart';
import '../../services/chat/voice_recorder.dart';
import '../../widgets/chat/attachment_menu.dart';
import '../../widgets/chat/disappearing_timer_menu.dart';
import '../../widgets/chat/in_chat_search_bar.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/pinned_message_banner.dart';
import '../../widgets/chat/presence_subtitle.dart';
import '../../widgets/chat/reply_compose_bar.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/voice_record_button.dart';
import 'chat_presence.dart';
import 'chat_style.dart';
import 'chat_thread_controller.dart';
import 'chat_wallpaper.dart';

class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({
    super.key,
    required this.conversation,
    this.repository,
  });

  final ChatConversation conversation;

  /// Live backend for this thread. When present the thread sends through and
  /// polls the API; when null it runs the in-memory demo with canned replies.
  final ChatRepository? repository;

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

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImageAttachmentPicker _imagePicker = const StubImageAttachmentPicker();
  final FileAttachmentPicker _filePicker = const StubFileAttachmentPicker();
  final VoiceRecorder _voiceRecorder = StubVoiceRecorder();
  final Map<String, GlobalKey> _messageKeys = {};

  late final ChatThreadController _controller;
  late final DisappearingSweeper _sweeper;

  static const Duration _pollInterval = Duration(seconds: 3);

  Timer? _replyTimer;
  Timer? _pollTimer;
  bool _peerIsTyping = false;
  String? _typingPeerName;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _editingMessageId;

  ChatConversation get _conversation => widget.conversation;

  @override
  void initState() {
    super.initState();
    _controller = ChatThreadController(
      _conversation,
      repository: widget.repository,
    );
    _controller.addListener(_onControllerChanged);
    _sweeper = DisappearingSweeper(controller: _controller);
    _sweeper.start();
    _controller.markThreadRead();
    _startServerSync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _startServerSync() {
    if (!_controller.isBackedByServer) return;
    _controller.syncFromServer();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => _controller.syncFromServer(),
    );
  }

  @override
  void dispose() {
    _replyTimer?.cancel();
    _pollTimer?.cancel();
    _sweeper.stop();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _syncComposerWithEditing();
    setState(() {});
  }

  void _syncComposerWithEditing() {
    final editing = _controller.editing;
    if (editing?.id == _editingMessageId) return;
    _editingMessageId = editing?.id;
    if (editing != null) {
      _input.text = editing.text;
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  // --- Sending and the simulated peer --------------------------------------

  void _submitInput() {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final editing = _controller.editing;
    if (editing != null) {
      _controller.applyEdit(editing.id, text);
      _input.clear();
      return;
    }

    _controller.sendText(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _scheduleAutoReply();
  }

  void _scheduleAutoReply() {
    if (_controller.isBackedByServer) return;
    _replyTimer?.cancel();
    final replier = _nextReplier();
    setState(() {
      _peerIsTyping = true;
      _typingPeerName = _conversation.isGroup ? replier : null;
    });
    _replyTimer = Timer(const Duration(milliseconds: 1600), _deliverAutoReply);
  }

  void _deliverAutoReply() {
    if (!mounted) return;
    setState(() => _peerIsTyping = false);
    _controller.markMyMessagesRead();
    _controller.receive(_buildAutoReply());
    _controller.markThreadRead();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  ChatMessage _buildAutoReply() {
    final replier = _nextReplier();
    return ChatMessage(
      id: 'msg-reply-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversation.id,
      text: _nextReply(),
      sentAt: DateTime.now(),
      fromMe: false,
      senderName: _conversation.isGroup ? replier : null,
    );
  }

  String _nextReplier() {
    if (!_conversation.isGroup) return _conversation.contact.name;
    final members = _conversation.group!.members;
    if (members.isEmpty) return _conversation.contact.name;
    final inbound = _controller.messages.where((m) => !m.fromMe).length;
    return members[inbound % members.length].name;
  }

  String _nextReply() {
    final inbound = _controller.messages.where((m) => !m.fromMe).length;
    return _cannedReplies[inbound % _cannedReplies.length];
  }

  // --- Attachments ---------------------------------------------------------

  void _openAttachmentMenu() {
    AttachmentMenu.show(
      context,
      onPhoto: _attachGalleryPhoto,
      onCamera: _attachCameraPhoto,
      onFile: _attachFile,
      onLocation: _attachLocation,
    );
  }

  Future<void> _attachGalleryPhoto() async {
    final attachment = await _imagePicker.pickFromGallery();
    if (attachment == null) return;
    _controller.sendAttachment(attachment, type: MessageType.image);
    _afterAttachment();
  }

  Future<void> _attachCameraPhoto() async {
    final attachment = await _imagePicker.captureFromCamera();
    if (attachment == null) return;
    _controller.sendAttachment(attachment, type: MessageType.image);
    _afterAttachment();
  }

  Future<void> _attachFile() async {
    final attachment = await _filePicker.pickFile();
    if (attachment == null) return;
    _controller.sendAttachment(attachment, type: MessageType.file);
    _afterAttachment();
  }

  void _attachLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing is not available yet.')),
    );
  }

  void _afterAttachment() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    _scheduleAutoReply();
  }

  // --- Search and navigation ----------------------------------------------

  void _openSearch() => setState(() => _isSearching = true);

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
    });
  }

  void _onSearchQueryChanged(String query) =>
      setState(() => _searchQuery = query);

  void _jumpToIndex(int index) {
    final messages = _controller.messages;
    if (index < 0 || index >= messages.length) return;
    _scrollToMessage(messages[index].id);
  }

  void _scrollToMessage(String messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _messageKeys[messageId];
      final target = key?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    });
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatStyle.theme(),
      child: Scaffold(
        appBar: _isSearching ? _buildSearchBar() : _buildAppBar(),
        body: ChatWallpaper(
          child: Column(
            children: [
              PinnedMessageBanner(
                controller: _controller,
                onJumpTo: _scrollToMessage,
              ),
              Expanded(child: _buildMessageList()),
              if (_peerIsTyping) _buildTypingRow(),
              ReplyComposeBar(controller: _controller),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return InChatSearchBar(
      controller: _controller,
      onJumpTo: _jumpToIndex,
      onClose: _closeSearch,
      onQueryChanged: _onSearchQueryChanged,
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
                PresenceSubtitle(
                  contact: _conversation.contact,
                  isTyping: _peerIsTyping,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search messages',
          onPressed: _openSearch,
        ),
        _buildOverflowMenu(),
      ],
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<_ThreadMenuAction>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: _onMenuAction,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ThreadMenuAction.disappearing,
          child: Text('Disappearing messages'),
        ),
      ],
    );
  }

  void _onMenuAction(_ThreadMenuAction action) {
    switch (action) {
      case _ThreadMenuAction.disappearing:
        DisappearingTimerMenu.show(context, _controller);
    }
  }

  Widget _buildMessageList() {
    final messages = _controller.messages;
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
      controller: _scroll,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(
        horizontal: ChatStyle.pageInset,
        vertical: 12,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return KeyedSubtree(
          key: _keyFor(message.id),
          child: MessageBubble(
            message: message,
            conversation: _conversation,
            controller: _controller,
            searchQuery: _searchQuery,
            onJumpToMessage: _scrollToMessage,
          ),
        );
      },
    );
  }

  GlobalKey _keyFor(String messageId) =>
      _messageKeys.putIfAbsent(messageId, GlobalKey.new);

  Widget _buildTypingRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(ChatStyle.pageInset, 0, 64, 6),
        child: TypingIndicator(typistName: _typingPeerName),
      ),
    );
  }

  Widget _buildComposer() {
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AttachButton(onPressed: _openAttachmentMenu),
          const SizedBox(width: 6),
          Expanded(child: _buildInputField()),
          const SizedBox(width: 10),
          _buildTrailingAction(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final editing = _controller.editing != null;
    return TextField(
      controller: _input,
      style: ChatStyle.body(size: 14, color: ChatStyle.textPrimary),
      maxLines: 5,
      minLines: 1,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: editing ? 'Edit message…' : 'Type a message…',
        hintStyle: ChatStyle.body(size: 14, color: ChatStyle.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        filled: true,
        fillColor: ChatStyle.background,
        border: _inputBorder(ChatStyle.hairline),
        enabledBorder: _inputBorder(ChatStyle.hairline),
        focusedBorder: _inputBorder(ChatStyle.gold, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(ChatStyle.cardRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildTrailingAction() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _input,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        if (hasText || _controller.editing != null) {
          return _SendButton(onPressed: _submitInput);
        }
        return VoiceRecordButton(
          controller: _controller,
          recorder: _voiceRecorder,
        );
      },
    );
  }
}

enum _ThreadMenuAction { disappearing }

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline_rounded),
      color: ChatStyle.textSecondary,
      tooltip: 'Attach',
      onPressed: onPressed,
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Send message',
      child: Material(
        color: ChatStyle.gold,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.send_rounded, color: ChatStyle.onGold, size: 20),
          ),
        ),
      ),
    );
  }
}

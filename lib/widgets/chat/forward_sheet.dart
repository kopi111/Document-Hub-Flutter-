import 'package:flutter/material.dart';

import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

// INTEGRATION: Show from the message long-press context menu in
// chat_thread_screen.dart — ForwardSheet.show(context, conversations: allConversations,
// message: tappedMsg, onPick: (id) { destinationController.forwardIn(tappedMsg); });
// allConversations comes from your conversation list provider / ChatRepository.

/// Bottom sheet that lets the user pick a destination conversation and forward
/// a message to it. Supports two dispatch modes: pass [controller] to have the
/// sheet call [ChatThreadController.forwardIn] directly, or pass [onPick] to
/// receive the chosen [ChatConversation.id] and route the forward yourself.
class ForwardSheet extends StatefulWidget {
  const ForwardSheet({
    super.key,
    required this.conversations,
    required this.message,
    this.controller,
    this.onPick,
    this.sourceLabel,
  }) : assert(
          controller != null || onPick != null,
          'Provide at least one of controller or onPick.',
        );

  /// All conversations the user can forward to.
  final List<ChatConversation> conversations;

  /// The message being forwarded.
  final ChatMessage message;

  /// When set, the sheet calls [ChatThreadController.forwardIn] on pick.
  final ChatThreadController? controller;

  /// When set, called with the chosen conversation's id on pick.
  final void Function(String conversationId)? onPick;

  /// Overrides the "Forwarded from" label that is stamped on the new message.
  /// Defaults to [ChatMessage.forwardedFrom], then [ChatMessage.senderName].
  final String? sourceLabel;

  static Future<void> show(
    BuildContext context, {
    required List<ChatConversation> conversations,
    required ChatMessage message,
    ChatThreadController? controller,
    void Function(String conversationId)? onPick,
    String? sourceLabel,
  }) {
    assert(
      controller != null || onPick != null,
      'Provide at least one of controller or onPick.',
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForwardSheet(
        conversations: conversations,
        message: message,
        controller: controller,
        onPick: onPick,
        sourceLabel: sourceLabel,
      ),
    );
  }

  @override
  State<ForwardSheet> createState() => _ForwardSheetState();
}

class _ForwardSheetState extends State<ForwardSheet> {
  final _searchController = TextEditingController();
  late List<ChatConversation> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.conversations;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.conversations
          : widget.conversations
              .where((c) =>
                  c.title.toLowerCase().contains(query) ||
                  c.subtitle.toLowerCase().contains(query))
              .toList(growable: false);
    });
  }

  void _forwardTo(ChatConversation destination) {
    final label = widget.sourceLabel ??
        widget.message.forwardedFrom ??
        widget.message.senderName;
    widget.controller?.forwardIn(widget.message, fromLabel: label);
    widget.onPick?.call(destination.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => _SheetSurface(
        searchController: _searchController,
        filtered: _filtered,
        onPick: _forwardTo,
        scrollController: scrollController,
        bottomPadding: bottomInset,
      ),
    );
  }
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({
    required this.searchController,
    required this.filtered,
    required this.onPick,
    required this.scrollController,
    required this.bottomPadding,
  });

  final TextEditingController searchController;
  final List<ChatConversation> filtered;
  final void Function(ChatConversation) onPick;
  final ScrollController scrollController;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatStyle.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(ChatStyle.cardRadius),
      ),
      child: Column(
        children: [
          _DragHandle(),
          _SheetTitle(),
          _SearchBar(controller: searchController),
          const Divider(height: 1, thickness: 1, color: ChatStyle.hairline),
          Expanded(
            child: _ConversationList(
              conversations: filtered,
              scrollController: scrollController,
              onPick: onPick,
              bottomPadding: bottomPadding,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: ChatStyle.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatStyle.pageInset, 0, ChatStyle.pageInset, 12,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Forward to…',
          style: ChatStyle.title(size: 17),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatStyle.pageInset, 0, ChatStyle.pageInset, 8,
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: ChatStyle.body(size: 14, color: ChatStyle.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search…',
          hintStyle: ChatStyle.body(size: 14),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChatStyle.textSecondary,
            size: 20,
          ),
          filled: true,
          fillColor: ChatStyle.surfaceRaised,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.conversations,
    required this.scrollController,
    required this.onPick,
    required this.bottomPadding,
  });

  final List<ChatConversation> conversations;
  final ScrollController scrollController;
  final void Function(ChatConversation) onPick;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Text('No chats found', style: ChatStyle.body()),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      itemCount: conversations.length,
      itemBuilder: (_, index) => _ConversationTile(
        conversation: conversations[index],
        onTap: () => onPick(conversations[index]),
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
    return ListTile(
      onTap: onTap,
      leading: _ConversationAvatar(conversation: conversation),
      title: Text(
        conversation.title,
        style: ChatStyle.body(
          size: 15,
          color: ChatStyle.textPrimary,
          weight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        conversation.lastMessage?.preview ?? conversation.subtitle,
        style: ChatStyle.body(size: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ChatStyle.pageInset,
        vertical: 4,
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) {
    final url = conversation.avatarUrl;
    return CircleAvatar(
      radius: 24,
      backgroundColor: ChatStyle.goldSoft,
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              conversation.avatarInitials,
              style: ChatStyle.title(size: 14, color: ChatStyle.onGold),
            )
          : null,
    );
  }
}

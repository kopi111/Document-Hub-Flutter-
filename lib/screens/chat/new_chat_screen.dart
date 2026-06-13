import 'package:flutter/material.dart';

import '../../models/chat/chat_contact.dart';
import '../../models/chat/chat_conversation.dart';
import '../../services/chat/chat_repository.dart';
import 'chat_style.dart';
import 'chat_presence.dart';
import 'new_group_screen.dart';

/// Roster picker for starting a new conversation. Pops the chosen [ChatContact]
/// for a one-to-one chat, a created [ChatConversation] for a new group, or null
/// when dismissed.
class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key, required this.repository});

  final ChatRepository repository;

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatContact> _contacts = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    // Show every officer (not just those without a thread) so search finds
    // anyone; selecting one opens the existing conversation or starts a new one.
    final contacts = await widget.repository.allContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  /// Officers matching the search box, filtered by name, rank, or station.
  List<ChatContact> get _filteredContacts {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _contacts;
    return _contacts
        .where((contact) =>
            contact.name.toLowerCase().contains(query) ||
            contact.rank.toLowerCase().contains(query) ||
            contact.station.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _createGroup() async {
    final conversation = await Navigator.push<ChatConversation>(
      context,
      MaterialPageRoute(
        builder: (_) => NewGroupScreen(repository: widget.repository),
      ),
    );
    if (!mounted || conversation == null) return;
    Navigator.of(context).pop(conversation);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatStyle.theme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Message')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: ChatStyle.gold),
      );
    }
    final searching = _query.trim().isNotEmpty;
    final results = _filteredContacts;
    return Column(
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          onClear: () => setState(() {
            _query = '';
            _searchController.clear();
          }),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (!searching) ...[
                _NewGroupTile(onTap: _createGroup),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: ChatStyle.hairline,
                  indent: ChatStyle.pageInset,
                  endIndent: ChatStyle.pageInset,
                ),
              ],
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    searching
                        ? 'No officer matches “$_query”.'
                        : 'No more officers to message individually.\nYou can still start a group above.',
                    textAlign: TextAlign.center,
                    style: ChatStyle.body(color: ChatStyle.textSecondary),
                  ),
                )
              else
                for (final contact in results)
                  _ContactTile(
                    contact: contact,
                    onTap: () => Navigator.of(context).pop(contact),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatStyle.pageInset,
        12,
        ChatStyle.pageInset,
        4,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: ChatStyle.body(color: ChatStyle.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search officers by name, rank, or station',
          hintStyle: ChatStyle.body(size: 13, color: ChatStyle.textSecondary),
          prefixIcon: const Icon(Icons.search, color: ChatStyle.textSecondary),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close,
                      color: ChatStyle.textSecondary, size: 20),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: ChatStyle.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ChatStyle.hairline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ChatStyle.hairline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: ChatStyle.gold, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _NewGroupTile extends StatelessWidget {
  const _NewGroupTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatStyle.pageInset,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: ChatStyle.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: ChatStyle.onGold),
            ),
            const SizedBox(width: 12),
            Text(
              'New group',
              style: ChatStyle.title(size: 15, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onTap});

  final ChatContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChatStyle.pageInset,
          vertical: 12,
        ),
        child: Row(
          children: [
            ChatPresenceAvatar(
              initials: contact.initials,
              avatarUrl: contact.avatarUrl,
              isOnline: contact.isOnline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: ChatStyle.title(size: 15, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${contact.rank} · ${contact.station}',
                    style: ChatStyle.mono(
                      size: 10,
                      color: ChatStyle.gold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    presenceLabel(contact),
                    style: ChatStyle.body(size: 11, color: ChatStyle.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: ChatStyle.textSecondary),
          ],
        ),
      ),
    );
  }
}

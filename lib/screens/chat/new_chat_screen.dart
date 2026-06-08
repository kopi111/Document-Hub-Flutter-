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
  List<ChatContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.repository.availableContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _NewGroupTile(onTap: _createGroup),
        Divider(
          height: 1,
          thickness: 1,
          color: ChatStyle.hairline,
          indent: ChatStyle.pageInset,
          endIndent: ChatStyle.pageInset,
        ),
        if (_contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No more officers to message individually.\nYou can still start a group above.',
              textAlign: TextAlign.center,
              style: ChatStyle.body(color: ChatStyle.textSecondary),
            ),
          )
        else
          for (final contact in _contacts)
            _ContactTile(
              contact: contact,
              onTap: () => Navigator.of(context).pop(contact),
            ),
      ],
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

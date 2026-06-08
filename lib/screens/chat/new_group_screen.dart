import 'package:flutter/material.dart';

import '../../models/chat/chat_contact.dart';
import '../../models/chat/chat_conversation.dart';
import '../../services/chat/chat_repository.dart';
import 'chat_style.dart';
import 'chat_presence.dart';

/// Builds a new group: name it, pick at least two officers, and create. Pops
/// the created [ChatConversation], or null when dismissed.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key, required this.repository});

  final ChatRepository repository;

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final Set<String> _selectedIds = {};

  List<ChatContact> _contacts = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await widget.repository.availableContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  bool get _canCreate =>
      _nameController.text.trim().isNotEmpty && _selectedIds.length >= 2;

  void _toggle(String contactId) {
    setState(() {
      if (!_selectedIds.remove(contactId)) _selectedIds.add(contactId);
    });
  }

  Future<void> _create() async {
    if (!_canCreate || _creating) return;
    setState(() => _creating = true);
    final members = _contacts
        .where((contact) => _selectedIds.contains(contact.id))
        .toList(growable: false);
    try {
      final conversation = await widget.repository
          .startGroupConversation(_nameController.text.trim(), members);
      if (!mounted) return;
      Navigator.of(context).pop<ChatConversation>(conversation);
    } catch (error) {
      if (!mounted) return;
      // Re-enable the button so the user can retry instead of being stuck.
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create group: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ChatStyle.theme(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Group'),
          actions: [
            TextButton(
              onPressed: _canCreate && !_creating ? _create : null,
              child: Text(
                'Create',
                style: ChatStyle.title(
                  size: 14,
                  weight: FontWeight.w700,
                  color: _canCreate ? ChatStyle.gold : ChatStyle.textSecondary,
                ),
              ),
            ),
          ],
        ),
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
    return Column(
      children: [
        _buildNameField(),
        _buildSelectionCount(),
        Expanded(child: _buildContactList()),
      ],
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChatStyle.pageInset,
        16,
        ChatStyle.pageInset,
        8,
      ),
      child: TextField(
        controller: _nameController,
        style: ChatStyle.body(size: 15, color: ChatStyle.textPrimary),
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Group name',
          hintStyle: ChatStyle.body(size: 15, color: ChatStyle.textSecondary),
          prefixIcon: const Icon(Icons.groups_rounded, color: ChatStyle.gold),
          filled: true,
          fillColor: ChatStyle.surface,
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
    );
  }

  Widget _buildSelectionCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChatStyle.pageInset),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _selectedIds.isEmpty
              ? 'Add at least two members'
              : '${_selectedIds.length} selected',
          style: ChatStyle.mono(size: 10, color: ChatStyle.gold),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No officers available to add.',
            textAlign: TextAlign.center,
            style: ChatStyle.body(color: ChatStyle.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        indent: ChatStyle.pageInset + 48 + 12,
        endIndent: ChatStyle.pageInset,
        color: ChatStyle.hairline,
      ),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return _SelectableContactTile(
          contact: contact,
          selected: _selectedIds.contains(contact.id),
          onTap: () => _toggle(contact.id),
        );
      },
    );
  }
}

class _SelectableContactTile extends StatelessWidget {
  const _SelectableContactTile({
    required this.contact,
    required this.selected,
    required this.onTap,
  });

  final ChatContact contact;
  final bool selected;
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
                ],
              ),
            ),
            _SelectionMark(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? ChatStyle.gold : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? ChatStyle.gold : ChatStyle.hairline,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 16, color: ChatStyle.onGold)
          : null,
    );
  }
}

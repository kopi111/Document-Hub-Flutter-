import 'package:flutter/material.dart';

import '../../models/email/email_message.dart';
import '../../models/notifications/app_notification.dart';
import '../../services/email/email_repository.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../theme/nam_style.dart';

/// Inbox view for the signed-in officer.
///
/// Loads messages from [EmailRepository] on first mount, fires one unread
/// notification into [AppNotificationsStore] (guarded to run once), then
/// presents a scrollable list. Tapping a row opens a detail sheet.
class EmailInboxScreen extends StatefulWidget {
  const EmailInboxScreen({super.key, required this.userEmail});

  final String userEmail;

  @override
  State<EmailInboxScreen> createState() => _EmailInboxScreenState();
}

class _EmailInboxScreenState extends State<EmailInboxScreen> {
  final EmailRepository _repository = const InMemoryEmailRepository();

  List<EmailMessage> _messages = [];
  bool _loading = true;
  String? _error;
  bool _notificationFired = false;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    try {
      final messages = await _repository.inbox();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _fireUnreadNotificationOnce(messages);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load inbox: $error';
        _loading = false;
      });
    }
  }

  void _fireUnreadNotificationOnce(List<EmailMessage> messages) {
    if (_notificationFired) return;
    final firstUnread = _firstUnreadOrNull(messages);
    if (firstUnread == null) return;
    _notificationFired = true;
    AppNotificationsStore.instance.recordEvent(
      kind: NotificationKind.email,
      title: 'New email from ${firstUnread.sender}',
      body: firstUnread.subject,
    );
  }

  EmailMessage? _firstUnreadOrNull(List<EmailMessage> messages) {
    for (final message in messages) {
      if (message.unread) return message;
    }
    return null;
  }

  void _openDetail(EmailMessage message) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NamStyle.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MessageDetailSheet(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inbox'),
          Text(
            widget.userEmail,
            style: NamStyle.body(size: 11, color: NamStyle.textSecondary),
          ),
        ],
      ),
      toolbarHeight: 64,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: NamStyle.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: NamStyle.body(color: NamStyle.textPrimary)),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages',
          style: NamStyle.body(color: NamStyle.textSecondary),
        ),
      );
    }
    return _MessageList(messages: _messages, onOpen: _openDetail);
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.onOpen});

  final List<EmailMessage> messages;
  final void Function(EmailMessage) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: NamStyle.hairline),
      itemBuilder: (_, index) => _MessageRow(
        message: messages[index],
        onTap: () => onOpen(messages[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single inbox row
// ---------------------------------------------------------------------------

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.onTap});

  final EmailMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NamStyle.pageInset,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SenderAvatar(initials: message.senderInitials, unread: message.unread),
            const SizedBox(width: 14),
            Expanded(child: _RowContent(message: message)),
          ],
        ),
      ),
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.initials, required this.unread});

  final String initials;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: NamStyle.gold.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: NamStyle.title(
              size: 14,
              weight: FontWeight.w700,
              color: NamStyle.gold,
            ),
          ),
        ),
        if (unread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: NamStyle.gold,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                message.sender,
                style: NamStyle.title(
                  size: 14,
                  weight:
                      message.unread ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _relativeTime(message.receivedAt),
              style: NamStyle.body(
                size: 11,
                color: message.unread
                    ? NamStyle.gold
                    : NamStyle.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          message.subject,
          style: NamStyle.body(
            size: 13,
            color: message.unread
                ? NamStyle.textPrimary
                : NamStyle.textSecondary,
            weight: message.unread ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          message.preview,
          style: NamStyle.body(size: 12, color: NamStyle.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _relativeTime(DateTime time) {
    final now = DateTime(2026, 5, 31, 23, 59);
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final month = _monthAbbrev(time.month);
    return '$month ${time.day}';
  }

  String _monthAbbrev(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

// ---------------------------------------------------------------------------
// Full message detail (bottom sheet)
// ---------------------------------------------------------------------------

class _MessageDetailSheet extends StatelessWidget {
  const _MessageDetailSheet({required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          _SheetHandle(),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                NamStyle.pageInset,
                0,
                NamStyle.pageInset,
                40,
              ),
              children: [
                _MessageHeader(message: message),
                const SizedBox(height: 20),
                Divider(color: NamStyle.hairline),
                const SizedBox(height: 20),
                Text(
                  message.body,
                  style: NamStyle.body(
                    size: 14,
                    color: NamStyle.textPrimary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: NamStyle.hairline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  const _MessageHeader({required this.message});

  final EmailMessage message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.subject,
          style: NamStyle.title(size: 18, weight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: NamStyle.gold.withValues(alpha: 0.15),
              child: Text(
                message.senderInitials,
                style: NamStyle.title(
                  size: 12,
                  weight: FontWeight.w700,
                  color: NamStyle.gold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.sender,
                    style: NamStyle.body(
                      size: 13,
                      color: NamStyle.textPrimary,
                      weight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    message.senderAddress,
                    style: NamStyle.body(
                      size: 12,
                      color: NamStyle.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatDateTime(message.receivedAt),
          style: NamStyle.mono(
            size: 10,
            color: NamStyle.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthAbbrev(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year · $hour:$minute';
  }

  String _monthAbbrev(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}

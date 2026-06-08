/// A single email message as displayed in the JCF officer inbox.
class EmailMessage {
  final String id;
  final String sender;
  final String senderAddress;
  final String subject;
  final String preview;
  final String body;
  final DateTime receivedAt;
  final bool unread;

  const EmailMessage({
    required this.id,
    required this.sender,
    required this.senderAddress,
    required this.subject,
    required this.preview,
    required this.body,
    required this.receivedAt,
    required this.unread,
  });

  /// Two-letter initials derived from the sender display name.
  String get senderInitials {
    final parts = sender.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.first.isNotEmpty) return parts.first[0].toUpperCase();
    return '?';
  }
}

import 'chat_contact.dart';

/// A named group thread with several JCF officers as members.
class ChatGroup {
  final String id;
  final String name;
  final List<ChatContact> members;

  /// Optional group photo. Falls back to [initials] when absent.
  final String? avatarUrl;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.members,
    this.avatarUrl,
  });

  /// Two-letter initials derived from the group name.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '#';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// First names of the members, joined for a subtitle line.
  String get membersSummary =>
      members.map((member) => member.name.split(' ').first).join(', ');

  /// Whether any member is currently online.
  bool get anyOnline => members.any((member) => member.isOnline);
}

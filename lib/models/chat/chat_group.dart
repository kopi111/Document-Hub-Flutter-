import 'chat_contact.dart';

/// A named group thread with several JCF officers as members.
class ChatGroup {
  final String id;
  final String name;
  final List<ChatContact> members;

  /// Optional group photo URL. Falls back to [initials] when absent.
  final String? avatarUrl;

  /// Base64-encoded group photo sent by the API when a photo is stored as
  /// binary. Takes display priority over [avatarUrl] when both are present.
  final String? avatarBase64;

  const ChatGroup({
    required this.id,
    required this.name,
    required this.members,
    this.avatarUrl,
    this.avatarBase64,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>? ?? <dynamic>[];
    return ChatGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: rawMembers
          .map((m) => ChatContact.fromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      avatarUrl: json['avatar_url'] as String?,
      avatarBase64: json['avatar_base64'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'members': members.map((m) => m.toJson()).toList(growable: false),
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (avatarBase64 != null) 'avatar_base64': avatarBase64,
      };

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

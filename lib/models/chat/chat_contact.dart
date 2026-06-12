/// A JCF officer who can exchange messages with the current user.
class ChatContact {
  final String id;
  final String name;
  final String rank;
  final String station;

  /// Remote profile photo URL. Null when the officer has no picture on file, in
  /// which case the UI falls back to [initials].
  final String? avatarUrl;

  /// Base64-encoded avatar image sent by the API when a photo is stored as
  /// binary. Takes display priority over [avatarUrl] when both are present.
  final String? avatarBase64;

  /// Whether the officer is currently reachable.
  final bool isOnline;

  /// When the officer was last active. Null when never recorded; ignored while
  /// [isOnline] is true.
  final DateTime? lastSeen;

  const ChatContact({
    required this.id,
    required this.name,
    required this.rank,
    required this.station,
    this.avatarUrl,
    this.avatarBase64,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) => ChatContact(
        id: json['id'] as String,
        name: json['name'] as String,
        rank: json['rank'] as String,
        station: json['station'] as String,
        avatarUrl: json['avatar_url'] as String?,
        avatarBase64: json['avatar_base64'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        lastSeen: json['last_seen'] == null
            ? null
            : DateTime.parse(json['last_seen'] as String).toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rank': rank,
        'station': station,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (avatarBase64 != null) 'avatar_base64': avatarBase64,
        'is_online': isOnline,
        if (lastSeen != null) 'last_seen': lastSeen!.toUtc().toIso8601String(),
      };

  /// Two-letter initials derived from the officer's name.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

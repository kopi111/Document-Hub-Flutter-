/// A JCF officer who can exchange messages with the current user.
class ChatContact {
  final String id;
  final String name;
  final String rank;
  final String station;

  /// Remote profile photo. Null when the officer has no picture on file, in
  /// which case the UI falls back to [initials].
  final String? avatarUrl;

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
    this.isOnline = false,
    this.lastSeen,
  });

  /// Two-letter initials derived from the officer's name.
  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

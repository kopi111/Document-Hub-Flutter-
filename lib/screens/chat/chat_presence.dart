import 'package:flutter/material.dart';

import '../../models/chat/chat_contact.dart';
import 'chat_style.dart';

const Color _onlineGreen = Color(0xFF34C759);

/// Human-readable presence: "Online", "Last seen 2h ago", or "Offline".
String presenceLabel(ChatContact contact) {
  if (contact.isOnline) return 'Online';
  final seen = contact.lastSeen;
  if (seen == null) return 'Offline';
  return 'Last seen ${_relativeFromNow(seen)}';
}

/// Colour for a presence dot — green when online, muted otherwise.
Color presenceColor(ChatContact contact) =>
    contact.isOnline ? _onlineGreen : ChatStyle.textSecondary;

String _relativeFromNow(DateTime moment) {
  final diff = DateTime.now().difference(moment);
  if (diff.isNegative || diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// Circular avatar showing a profile photo when [avatarUrl] is set, otherwise
/// the [initials] (or a group glyph). A presence dot sits in the lower-right
/// corner when [isOnline].
class ChatPresenceAvatar extends StatelessWidget {
  const ChatPresenceAvatar({
    super.key,
    required this.initials,
    required this.isOnline,
    this.avatarUrl,
    this.isGroup = false,
    this.size = 48,
  });

  final String initials;
  final bool isOnline;
  final String? avatarUrl;
  final bool isGroup;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipOval(
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: ChatStyle.surfaceRaised,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _buildContent(),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: _onlineGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: ChatStyle.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final url = avatarUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF59C0F0), Color(0xFF4E8FE8)],
    [Color(0xFF6FD06B), Color(0xFF3FAE5A)],
    [Color(0xFFF0A05A), Color(0xFFE07C68)],
    [Color(0xFFC58AF0), Color(0xFF9B6BE8)],
    [Color(0xFFF06B92), Color(0xFFE05C7C)],
  ];

  Widget _placeholder() {
    // Mask to 31 bits: `hashCode.abs()` can stay negative for int.minValue,
    // which would crash the gradient lookup with a RangeError.
    final gradient =
        _avatarGradients[(initials.hashCode & 0x7fffffff) % _avatarGradients.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Center(
        child: isGroup
            ? Icon(Icons.groups_rounded, color: Colors.white, size: size * 0.5)
            : Text(
                initials,
                style: ChatStyle.title(
                  size: size * 0.36,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

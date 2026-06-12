/// An emoji reaction tally on a single message. [byMe] flags whether the
/// current user is one of the [count] reactors, so the UI can highlight the
/// chip and toggle it on tap.
class MessageReaction {
  final String emoji;
  final int count;
  final bool byMe;

  const MessageReaction({
    required this.emoji,
    this.count = 1,
    this.byMe = false,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        emoji: json['emoji'] as String,
        count: json['count'] as int? ?? 1,
        byMe: json['by_me'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'count': count,
        'by_me': byMe,
      };

  MessageReaction copyWith({int? count, bool? byMe}) => MessageReaction(
        emoji: emoji,
        count: count ?? this.count,
        byMe: byMe ?? this.byMe,
      );
}

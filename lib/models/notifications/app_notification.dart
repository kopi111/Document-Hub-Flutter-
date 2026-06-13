import '../news/news_article.dart';
import '../news/news_priority.dart';

enum NotificationKind { news, reminder, alert, wanted, missing, stolen, email }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime occurredAt;
  final NewsPriority priority;
  final NewsArticle? sourceArticle;

  /// Id of the record this notification is about (wanted/missing/stolen), so a
  /// tap can open that exact record rather than the whole section. Carried by
  /// the backend as `source_article_id`.
  final String? sourceRecordId;

  /// The backend's own id for this notification (without the `api-` prefix used
  /// by [id]). Present only for notifications fetched from `/v1/notifications`,
  /// and used to mark them read on the server. Null for locally-raised events.
  final String? remoteId;

  /// Whether the backend already considers this notification read. Read
  /// notifications are kept out of the feed so the badge reflects unread only.
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.priority,
    this.sourceArticle,
    this.sourceRecordId,
    this.remoteId,
    this.isRead = false,
  });

  /// Builds a notification from the backend `/v1/notifications` JSON so pushes
  /// raised elsewhere (e.g. the admin portal's "Notify everyone") surface here.
  factory AppNotification.fromApiJson(Map<String, dynamic> json) {
    return AppNotification(
      id: 'api-${json['id']}',
      kind: _kindFromWire(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      occurredAt: DateTime.tryParse(
            (json['created_at'] ?? json['occurred_at'] ?? '') as String,
          )?.toLocal() ??
          DateTime.now(),
      priority: _priorityFromWire(json['priority'] as String?),
      sourceRecordId: json['source_article_id'] as String?,
      remoteId: json['id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  static NotificationKind _kindFromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'wanted':
        return NotificationKind.wanted;
      case 'missing':
        return NotificationKind.missing;
      case 'stolen':
        return NotificationKind.stolen;
      case 'reminder':
        return NotificationKind.reminder;
      case 'alert':
        return NotificationKind.alert;
      case 'email':
        return NotificationKind.email;
      default:
        return NotificationKind.news;
    }
  }

  static NewsPriority _priorityFromWire(String? value) {
    switch (value?.toLowerCase()) {
      case 'urgent':
        return NewsPriority.urgent;
      case 'high':
        return NewsPriority.high;
      default:
        return NewsPriority.normal;
    }
  }

  factory AppNotification.fromArticle(NewsArticle article) {
    return AppNotification(
      id: 'news-${article.id}',
      kind: NotificationKind.news,
      title: article.title,
      body: article.summary,
      occurredAt: article.publishedAt,
      priority: article.priority,
      sourceArticle: article,
    );
  }
}

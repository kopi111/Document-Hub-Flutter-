import '../news/news_article.dart';
import '../news/news_priority.dart';

enum NotificationKind { news, reminder, alert }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime occurredAt;
  final NewsPriority priority;
  final NewsArticle? sourceArticle;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.priority,
    this.sourceArticle,
  });

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

import 'news_priority.dart';

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String? imageUrl;
  final String category;
  final DateTime publishedAt;
  final String author;
  final NewsPriority priority;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.imageUrl,
    required this.category,
    required this.publishedAt,
    required this.author,
    required this.priority,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: (json['summary'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      category: (json['category'] as String?) ?? 'Force-wide',
      publishedAt: DateTime.parse(json['published_at'] as String),
      author: (json['author'] as String?) ?? 'JCF Public Affairs',
      priority: NewsPriorityWire.fromWire(json['priority'] as String?),
    );
  }
}

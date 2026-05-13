import '../../models/news/news_article.dart';

// TODO: Add `HttpNewsRepository` once the backend `/api/v1/news` endpoint lands.
// It should reuse the `TokenProvider` + retry plumbing from `lib/services/api/`
// and return the same domain models this abstraction exposes.
abstract class NewsRepository {
  Future<List<NewsArticle>> latestArticles({int limit = 20});

  Future<NewsArticle> articleById(String id);
}

class NewsArticleNotFoundException implements Exception {
  final String id;

  const NewsArticleNotFoundException(this.id);

  @override
  String toString() => 'NewsArticleNotFoundException: no article with id "$id"';
}

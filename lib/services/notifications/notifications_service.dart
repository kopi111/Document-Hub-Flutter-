import '../../models/news/news_priority.dart';
import '../../models/notifications/app_notification.dart';
import '../news/news_repository.dart';

abstract class NotificationsService {
  Future<List<AppNotification>> listAll();
  Future<int> unreadCount();
}

class NewsBackedNotificationsService implements NotificationsService {
  final NewsRepository _newsRepository;

  NewsBackedNotificationsService({required NewsRepository newsRepository})
      : _newsRepository = newsRepository;

  @override
  Future<List<AppNotification>> listAll() async {
    final articles = await _newsRepository.latestArticles();
    return articles
        .where((article) => article.priority != NewsPriority.normal)
        .map(AppNotification.fromArticle)
        .toList(growable: false);
  }

  @override
  Future<int> unreadCount() async {
    final notifications = await listAll();
    return notifications.length;
  }
}

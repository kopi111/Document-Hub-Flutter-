import 'package:flutter/foundation.dart';

import '../../models/news/news_priority.dart';
import '../../models/notifications/app_notification.dart';
import 'notifications_service.dart';

/// App-wide, in-memory notification feed.
///
/// A single shared instance ([instance]) collects two streams of activity:
///   * news-priority announcements, seeded once from a [NotificationsService];
///   * operational events raised in-app — a new wanted/missing/stolen record
///     filed, or new mail received.
///
/// Widgets ([NotificationsBell], [NotificationsScreen]) listen for changes and
/// rebuild, so a record filed on one screen lights up the bell on another. This
/// stays in-memory like the rest of the app; persistence and FCM push arrive
/// with the backend.
class AppNotificationsStore extends ChangeNotifier {
  AppNotificationsStore._();

  static final AppNotificationsStore instance = AppNotificationsStore._();

  final List<AppNotification> _items = [];
  bool _seeded = false;
  int _sequence = 0;

  /// Notifications newest-first.
  List<AppNotification> get items {
    final ordered = [..._items]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(ordered);
  }

  int get count => _items.length;

  /// Seeds the feed from news-priority announcements exactly once.
  Future<void> ensureSeeded(NotificationsService newsService) async {
    if (_seeded) return;
    _seeded = true;
    final seeded = await newsService.listAll();
    _items.addAll(seeded);
    notifyListeners();
  }

  /// Records an operational event and pushes it to the top of the feed.
  void recordEvent({
    required NotificationKind kind,
    required String title,
    required String body,
    NewsPriority priority = NewsPriority.high,
  }) {
    _sequence++;
    _items.add(
      AppNotification(
        id: 'event-$_sequence',
        kind: kind,
        title: title,
        body: body,
        occurredAt: DateTime.now(),
        priority: priority,
      ),
    );
    notifyListeners();
  }
}

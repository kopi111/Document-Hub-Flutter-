import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/news/news_priority.dart';
import '../../models/notifications/app_notification.dart';
import 'api_notifications_client.dart';
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

  static const _dismissedKey = 'dismissed_notification_ids_v1';

  final List<AppNotification> _items = [];
  final Set<String> _dismissed = {};
  final ApiNotificationsClient _remote = ApiNotificationsClient();
  bool _seeded = false;
  bool _dismissedLoaded = false;
  int _sequence = 0;

  /// Loads the persisted set of dismissed ids once, so notifications the officer
  /// cleared — including locally-seeded news, which has no backend record — stay
  /// cleared across refreshes instead of re-appearing on every load.
  Future<void> _ensureDismissedLoaded() async {
    if (_dismissedLoaded) return;
    _dismissedLoaded = true;
    final preferences = await SharedPreferences.getInstance();
    _dismissed.addAll(preferences.getStringList(_dismissedKey) ?? const []);
  }

  Future<void> _persistDismissed() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_dismissedKey, _dismissed.toList());
  }

  /// Notifications newest-first.
  List<AppNotification> get items {
    final ordered = [..._items]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return List.unmodifiable(ordered);
  }

  int get count => _items.length;

  /// Seeds the feed from news-priority announcements exactly once, skipping any
  /// the officer has already dismissed so they do not re-appear on refresh.
  Future<void> ensureSeeded(NotificationsService newsService) async {
    if (_seeded) return;
    _seeded = true;
    await _ensureDismissedLoaded();
    final seeded = await newsService.listAll();
    _items.addAll(seeded.where((item) => !_dismissed.contains(item.id)));
    notifyListeners();
  }

  /// Merges notifications fetched from the backend, skipping ones already in the
  /// feed, locally dismissed, or already marked read on the server. Returns the
  /// number newly added so callers can chime only on genuine arrivals. Drives
  /// live push delivery from `/v1/notifications`.
  int mergeApi(List<AppNotification> incoming) {
    final existing = _items.map((item) => item.id).toSet();
    var added = 0;
    for (final notification in incoming) {
      if (notification.isRead ||
          existing.contains(notification.id) ||
          _dismissed.contains(notification.id)) {
        continue;
      }
      existing.add(notification.id);
      _items.add(notification);
      added++;
    }
    if (added > 0) notifyListeners();
    return added;
  }

  /// Clears a single notification when the officer taps it: removes it locally,
  /// remembers the id so the poll does not re-add it, and marks it read on the
  /// backend so it stays cleared across restarts and reloads.
  void dismiss(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    final remoteId = index == -1 ? null : _items[index].remoteId;
    _dismissed.add(id);
    _persistDismissed();
    if (index != -1) {
      _items.removeAt(index);
      notifyListeners();
    }
    if (remoteId != null) _remote.markRead(remoteId);
  }

  /// Clears every notification of one [kind] — used when the officer opens that
  /// section (e.g. taps the Wanted tile), which counts as seeing those
  /// bulletins. Remembers the ids and marks them read on the backend so they do
  /// not re-stand after a poll or reload.
  void dismissKind(NotificationKind kind) {
    final matching = _items.where((item) => item.kind == kind).toList();
    if (matching.isEmpty) return;
    for (final item in matching) {
      _dismissed.add(item.id);
      if (item.remoteId != null) _remote.markRead(item.remoteId!);
    }
    _persistDismissed();
    _items.removeWhere((item) => item.kind == kind);
    notifyListeners();
  }

  /// Clears the whole feed ("mark all read"): remembers the ids so the poll does
  /// not bring them back, and marks them read on the backend.
  void clearAll() {
    if (_items.isEmpty) return;
    _dismissed.addAll(_items.map((item) => item.id));
    _persistDismissed();
    _items.clear();
    notifyListeners();
    _remote.markAllRead();
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

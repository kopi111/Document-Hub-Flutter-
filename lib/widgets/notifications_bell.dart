import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/notifications/notifications_screen.dart';
import '../services/news/in_memory_news_repository.dart';
import '../services/news/news_repository.dart';
import '../services/notifications/api_notifications_client.dart';
import '../services/notifications/app_notifications_store.dart';
import '../services/notifications/notification_sound_controller.dart';
import '../services/notifications/notifications_service.dart';

class NotificationsBell extends StatefulWidget {
  const NotificationsBell({super.key, this.newsRepository});

  final NewsRepository? newsRepository;

  @override
  State<NotificationsBell> createState() => _NotificationsBellState();
}

class _NotificationsBellState extends State<NotificationsBell> {
  late final NewsRepository _newsRepository =
      widget.newsRepository ?? InMemoryNewsRepository();
  final ApiNotificationsClient _apiNotifications = ApiNotificationsClient();
  Timer? _poll;
  int _count = 0;
  bool _firstPull = true;

  @override
  void initState() {
    super.initState();
    AppNotificationsStore.instance.addListener(_onStoreChanged);
    NotificationSoundController.instance.ensureLoaded();
    _seedAndRefresh();
    _startPolling();
  }

  @override
  void dispose() {
    _poll?.cancel();
    AppNotificationsStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> _seedAndRefresh() async {
    final service = NewsBackedNotificationsService(newsRepository: _newsRepository);
    await AppNotificationsStore.instance.ensureSeeded(service);
    _onStoreChanged();
  }

  /// Polls the backend push feed so notifications raised elsewhere (e.g. the
  /// admin portal's "Notify everyone") arrive live without a restart.
  void _startPolling() {
    _pullApi();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _pullApi());
  }

  Future<void> _pullApi() async {
    final incoming = await _apiNotifications.fetch();
    if (incoming.isEmpty) return;
    final added = AppNotificationsStore.instance.mergeApi(incoming);
    // Chime only on genuine new arrivals, never on the first poll that loads
    // the existing backlog when the app opens.
    if (added > 0 && !_firstPull) {
      await NotificationSoundController.instance.chime();
    }
    _firstPull = false;
  }

  void _onStoreChanged() {
    if (!mounted) return;
    setState(() => _count = AppNotificationsStore.instance.count);
  }

  Future<void> _open() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(newsRepository: _newsRepository),
      ),
    );
    _onStoreChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: _open,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (_count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: _Badge(count: _count, color: colors.error),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../screens/notifications/notifications_screen.dart';
import '../services/news/in_memory_news_repository.dart';
import '../services/news/news_repository.dart';
import '../services/notifications/app_notifications_store.dart';
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
  int _count = 0;

  @override
  void initState() {
    super.initState();
    AppNotificationsStore.instance.addListener(_onStoreChanged);
    _seedAndRefresh();
  }

  @override
  void dispose() {
    AppNotificationsStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> _seedAndRefresh() async {
    final service = NewsBackedNotificationsService(newsRepository: _newsRepository);
    await AppNotificationsStore.instance.ensureSeeded(service);
    _onStoreChanged();
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

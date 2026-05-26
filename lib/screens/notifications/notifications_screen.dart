import 'package:flutter/material.dart';

import '../../models/news/news_priority.dart';
import '../../theme/jcf_palette.dart';
import '../../models/notifications/app_notification.dart';
import '../../services/news/in_memory_news_repository.dart';
import '../../services/news/news_repository.dart';
import '../../services/notifications/notifications_service.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/news/news_date_label.dart';
import '../news/news_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, NewsRepository? newsRepository})
      : _newsRepository = newsRepository;

  final NewsRepository? _newsRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NewsRepository _newsRepository =
      widget._newsRepository ?? InMemoryNewsRepository();
  late final NotificationsService _service =
      NewsBackedNotificationsService(newsRepository: _newsRepository);

  List<AppNotification> _notifications = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await _service.listAll();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load notifications: $failure';
        _loading = false;
      });
    }
  }

  Future<void> _open(AppNotification notification) async {
    final article = notification.sourceArticle;
    if (article == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Enable push notifications',
            onPressed: () => _promptForPushPermission(context),
          ),
        ],
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments()),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments() {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'Notifications'),
    ];
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(message: _error!, onRetry: _load);
    if (_notifications.isEmpty) return const _EmptyState();
    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationTile(
          notification: notification,
          onTap: () => _open(notification),
        );
      },
    );
  }

  Future<void> _promptForPushPermission(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Push notifications'),
        content: const Text(
          'Real-time push notifications require Firebase Cloud Messaging and a '
          'VAPID key registered for this domain. Wire this dialog to '
          'firebase_messaging once ICTD provisions a Firebase project for '
          'JCF Duty.\n\n'
          'In-app notifications (this screen) are already active for urgent '
          'and high-priority news.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            notification.priority.backgroundColor(colors).withValues(alpha: 0.6),
        child: Icon(
          _iconFor(notification),
          color: notification.priority.foregroundColor(colors),
        ),
      ),
      title: Text(notification.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${relativePublishedLabel(notification.occurredAt)} · ${notification.priority.label.toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: notification.priority.foregroundColor(colors),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: JcfPalette.iconDefault),
      onTap: onTap,
    );
  }

  IconData _iconFor(AppNotification notification) {
    if (notification.priority == NewsPriority.urgent) {
      return Icons.priority_high;
    }
    switch (notification.kind) {
      case NotificationKind.news:
        return Icons.campaign;
      case NotificationKind.reminder:
        return Icons.alarm;
      case NotificationKind.alert:
        return Icons.warning_amber;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined,
                size: 64, color: JcfPalette.iconDefault),
            const SizedBox(height: 12),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Urgent and high-priority announcements will appear here.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: JcfPalette.iconCritical),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

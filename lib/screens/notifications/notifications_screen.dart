import 'package:flutter/material.dart';

import '../../models/news/news_priority.dart';
import '../../models/notifications/app_notification.dart';
import '../../services/news/in_memory_news_repository.dart';
import '../../services/news/news_repository.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../services/notifications/notifications_service.dart';
import '../../theme/hub_style.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/news/news_date_label.dart';
import '../news/news_detail_screen.dart';

/// The "Quick Filters" tabs, each derived from real notification fields.
enum _Filter { all, unread, alerts, updates }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.unread => 'Unread',
        _Filter.alerts => 'Alerts',
        _Filter.updates => 'Updates',
      };

  IconData get icon => switch (this) {
        _Filter.all => Icons.dashboard_outlined,
        _Filter.unread => Icons.mark_email_unread_outlined,
        _Filter.alerts => Icons.warning_amber_rounded,
        _Filter.updates => Icons.campaign_outlined,
      };
}

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

  final Set<String> _readIds = <String>{};

  List<AppNotification> _notifications = const [];
  _Filter _filter = _Filter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppNotificationsStore.instance.addListener(_onStoreChanged);
    _seedAndLoad();
  }

  @override
  void dispose() {
    AppNotificationsStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> _seedAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service =
          NewsBackedNotificationsService(newsRepository: _newsRepository);
      await AppNotificationsStore.instance.ensureSeeded(service);
      _applyStoreItems();
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load notifications: $failure';
        _loading = false;
      });
    }
  }

  void _onStoreChanged() {
    if (!mounted) return;
    _applyStoreItems();
  }

  void _applyStoreItems() {
    if (!mounted) return;
    setState(() {
      _notifications = AppNotificationsStore.instance.items;
      _loading = false;
    });
  }

  bool _isUnread(AppNotification notification) =>
      !_readIds.contains(notification.id);

  bool _isAlert(AppNotification notification) =>
      notification.priority == NewsPriority.urgent ||
      notification.priority == NewsPriority.high;

  int get _unreadCount => _notifications.where(_isUnread).length;

  int get _alertCount => _notifications.where(_isAlert).length;

  List<AppNotification> get _priorityAlerts =>
      _notifications.where(_isAlert).toList(growable: false);

  List<AppNotification> get _unreadItems =>
      _notifications.where(_isUnread).toList(growable: false);

  List<AppNotification> get _earlierItems =>
      _notifications.where((item) => !_isUnread(item)).toList(growable: false);

  List<AppNotification> get _visible {
    switch (_filter) {
      case _Filter.all:
        return _notifications;
      case _Filter.unread:
        return _unreadItems;
      case _Filter.alerts:
        return _priorityAlerts;
      case _Filter.updates:
        return _notifications
            .where((item) => item.kind == NotificationKind.news)
            .toList(growable: false);
    }
  }

  void _markAllRead() {
    if (_unreadCount == 0) return;
    setState(() {
      _readIds.addAll(_notifications.map((item) => item.id));
    });
  }

  Future<void> _open(AppNotification notification) async {
    setState(() => _readIds.add(notification.id));
    final article = notification.sourceArticle;
    if (article == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)),
    );
  }

  void _showPreferencesUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification preferences arrive with the JCF Duty backend.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Notifications',
            showBack: true,
            actions: [
              _MarkAllReadButton(
                enabled: _unreadCount > 0,
                onPressed: _markAllRead,
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _seedAndLoad);
    }
    if (_notifications.isEmpty) return const _EmptyState();

    final alerts = _priorityAlerts;
    final unread = _unreadItems;
    final earlier = _earlierItems;
    final visible = _visible;
    final filtered = _filter != _Filter.all;

    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        _buildFilterPills(),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _HeroBanner(unreadCount: _unreadCount),
        ),
        const SizedBox(height: 20),
        if (filtered)
          ..._buildFilteredList(visible)
        else
          ..._buildGroupedList(alerts, unread, earlier),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _PreferencesBanner(onManage: _showPreferencesUnavailable),
        ),
      ],
    );
  }

  Widget _buildFilterPills() {
    final pills = <Widget>[
      for (final filter in _Filter.values)
        HubFilterPill(
          label: _pillLabel(filter),
          icon: filter.icon,
          accent: filter == _Filter.alerts
              ? HubTint.red.foreground
              : const Color(0xFF2D6CDF),
          selected: _filter == filter,
          onTap: () => setState(() => _filter = filter),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  String _pillLabel(_Filter filter) {
    switch (filter) {
      case _Filter.unread:
        return 'Unread ($_unreadCount)';
      case _Filter.alerts:
        return 'Alerts ($_alertCount)';
      case _Filter.all:
      case _Filter.updates:
        return filter.label;
    }
  }

  List<Widget> _buildFilteredList(List<AppNotification> visible) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HubSectionHeading(
          title: _filter.label,
          actionLabel: 'Show All',
          onAction: () => setState(() => _filter = _Filter.all),
        ),
      ),
      const SizedBox(height: 10),
      if (visible.isEmpty)
        const _SectionEmpty(message: 'Nothing here right now')
      else
        ...visible.map(_buildListCard),
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildGroupedList(
    List<AppNotification> alerts,
    List<AppNotification> unread,
    List<AppNotification> earlier,
  ) {
    return [
      if (alerts.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Priority Alerts'),
        ),
        const SizedBox(height: 10),
        ...alerts.map(
          (item) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _PriorityAlertCard(
              notification: item,
              onTap: () => _open(item),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: HubSectionHeading(title: 'Unread'),
      ),
      const SizedBox(height: 10),
      if (unread.isEmpty)
        const _SectionEmpty(message: 'You are all caught up')
      else
        ...unread.map(_buildListCard),
      const SizedBox(height: 12),
      if (earlier.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Earlier'),
        ),
        const SizedBox(height: 10),
        ...earlier.map(_buildListCard),
        const SizedBox(height: 12),
      ],
    ];
  }

  Widget _buildListCard(AppNotification notification) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: _NotificationCard(
        notification: notification,
        unread: _isUnread(notification),
        onTap: () => _open(notification),
      ),
    );
  }
}

/// Maps a notification to its circular-icon tint and glyph.
HubTint _tintFor(AppNotification notification) {
  if (notification.priority == NewsPriority.urgent) return HubTint.red;
  if (notification.priority == NewsPriority.high) return HubTint.orange;
  return switch (notification.kind) {
    NotificationKind.wanted => HubTint.red,
    NotificationKind.missing => HubTint.purple,
    NotificationKind.stolen => HubTint.teal,
    NotificationKind.alert => HubTint.orange,
    NotificationKind.email => HubTint.blue,
    NotificationKind.reminder => HubTint.green,
    NotificationKind.news => HubTint.blue,
  };
}

IconData _iconFor(AppNotification notification) {
  if (notification.priority == NewsPriority.urgent) return Icons.priority_high;
  return switch (notification.kind) {
    NotificationKind.news => Icons.campaign,
    NotificationKind.reminder => Icons.alarm,
    NotificationKind.alert => Icons.warning_amber,
    NotificationKind.wanted => Icons.person_search,
    NotificationKind.missing => Icons.person_off,
    NotificationKind.stolen => Icons.directions_car,
    NotificationKind.email => Icons.email_outlined,
  };
}

String _kindLabel(NotificationKind kind) => switch (kind) {
      NotificationKind.news => 'News',
      NotificationKind.reminder => 'Reminder',
      NotificationKind.alert => 'Alert',
      NotificationKind.wanted => 'Wanted',
      NotificationKind.missing => 'Missing',
      NotificationKind.stolen => 'Stolen Vehicle',
      NotificationKind.email => 'Mail',
    };

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? HubStyle.onGradient
        : Colors.white.withValues(alpha: 0.45);
    return Tooltip(
      message: 'Mark all read',
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(Icons.done_all, size: 18, color: foreground),
        label: Text(
          'Mark All Read',
          style: TextStyle(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HubStyle.heroRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: HubStyle.headerGradient,
          boxShadow: HubStyle.cardShadow,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: HubStyle.onGradient,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stay informed.',
                          style: TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Urgent bulletins and West-Ops activity, in one feed.',
                          style: TextStyle(
                            color: HubStyle.onGradientMuted,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _UnreadBadge(count: unreadCount),
                ],
              ),
            ),
            HubStyle.accentBar(),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: HubStyle.onGradient,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'unread',
            style: TextStyle(
              color: HubStyle.onGradientMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityAlertCard extends StatelessWidget {
  const _PriorityAlertCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: HubTint.red.foreground,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(HubStyle.cardRadius),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: HubTint.red.foreground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'HIGH PRIORITY',
                              style: TextStyle(
                                color: HubTint.red.foreground,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              relativePublishedLabel(notification.occurredAt),
                              style: const TextStyle(
                                color: HubStyle.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HubStyle.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HubStyle.textSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.unread,
    required this.onTap,
  });

  final AppNotification notification;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(notification);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(notification),
                    color: tint.foreground,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HubStyle.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (unread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2D6CDF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _TypeChip(
                            label: _kindLabel(notification.kind),
                            tint: tint,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            relativePublishedLabel(notification.occurredAt),
                            style: const TextStyle(
                              color: HubStyle.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.tint});

  final String label;
  final HubTint tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreferencesBanner extends StatelessWidget {
  const _PreferencesBanner({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HubTint.purple.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_none,
                color: HubTint.purple.foreground,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Your Notifications',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Choose which alerts reach you.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onManage,
              child: const Text(
                'Manage Preferences',
                style: TextStyle(
                  color: Color(0xFF2D6CDF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        message,
        style: const TextStyle(color: HubStyle.textSecondary, fontSize: 13),
      ),
    );
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
            const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: HubStyle.textSecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No notifications',
              style: TextStyle(
                color: HubStyle.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Urgent announcements and new West-Ops records will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HubStyle.textSecondary, fontSize: 13),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: HubTint.red.foreground,
            ),
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

import 'package:flutter/material.dart';

import '../../models/notifications/app_notification.dart';
import '../../services/chat/chat_repository.dart';
import '../../services/news/in_memory_news_repository.dart';
import '../../services/news/news_repository.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../services/phone_dialer.dart';
import '../../theme/hub_style.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_service_tile.dart';
import '../../widgets/notifications_bell.dart';
import '../about_screen.dart';
import '../calendar/calendar_screen.dart';
import '../chat/chat_gate.dart';
import '../directory/directory_screen.dart';
import '../documents/documents_home_screen.dart';
import '../email/email_login_screen.dart';
import '../map/map_screen.dart';
import '../news/news_feed_screen.dart';
import '../notes/notes_screen.dart';
import '../notifications/notifications_screen.dart';
import '../westops/missing_list_screen.dart';
import '../westops/stolen_vehicles_list_screen.dart';
import '../westops/traffic_codes_list_screen.dart';
import '../westops/wanted_list_screen.dart';

const String _emergencyNumber = '119';

/// Redesigned home: gradient header, welcome hero, colour-coded service grid,
/// an awareness banner, and a dark bottom bar with a centred emergency-call
/// button. Communications tools (Directory, Chat, Email) also appear in the
/// drawer.
class ServicesHomeScreen extends StatefulWidget {
  const ServicesHomeScreen({super.key});

  @override
  State<ServicesHomeScreen> createState() => _ServicesHomeScreenState();
}

class _ServicesHomeScreenState extends State<ServicesHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NewsRepository _newsRepository = InMemoryNewsRepository();
  int _chatUnread = 0;

  @override
  void initState() {
    super.initState();
    AppNotificationsStore.instance.addListener(_onCountsChanged);
    _loadChatUnread();
  }

  @override
  void dispose() {
    AppNotificationsStore.instance.removeListener(_onCountsChanged);
    super.dispose();
  }

  void _onCountsChanged() {
    if (mounted) setState(() {});
  }

  /// Total unread officer messages across all conversations, shown on the Chat tile.
  Future<void> _loadChatUnread() async {
    try {
      final conversations = await InMemoryChatRepository().conversations();
      final unread = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);
      if (mounted) setState(() => _chatUnread = unread);
    } catch (_) {
      // Leave the badge at zero if the roster can't be read.
    }
  }

  int _kindCount(NotificationKind kind) =>
      AppNotificationsStore.instance.items.where((n) => n.kind == kind).length;

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// Opens a section after clearing its notification badge — viewing the
  /// section counts as seeing those bulletins, so the count must not re-stand.
  void _openSection(NotificationKind kind, Widget screen) {
    AppNotificationsStore.instance.dismissKind(kind);
    _open(screen);
  }

  void _openLibrary() => _open(const DocumentsHomeScreen());
  void _openWanted() => _openSection(NotificationKind.wanted, const WantedListScreen());
  void _openMissing() => _openSection(NotificationKind.missing, const MissingListScreen());
  void _openStolenVehicles() =>
      _openSection(NotificationKind.stolen, const StolenVehiclesListScreen());
  void _openTrafficCodes() => _open(const TrafficCodesListScreen());
  void _openNews() =>
      _openSection(NotificationKind.news, NewsFeedScreen(repository: _newsRepository));
  void _openCalendar() => _open(const CalendarScreen());
  void _openNotes() => _open(const NotesScreen());
  void _openMap() => _open(const MapScreen());
  void _openDirectory() => _open(const DirectoryScreen());
  void _openChat() => _open(const ChatGate());
  void _openEmail() => _openSection(NotificationKind.email, const EmailLoginScreen());
  void _openAbout() => _open(const AboutScreen());
  void _openNotifications() => _open(const NotificationsScreen());
  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _placeEmergencyCall() async {
    Navigator.of(context).pop();
    try {
      await dialNumber(_emergencyNumber);
    } on DialFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the dialer.')),
      );
    }
  }

  void _showEmergencyCall() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.call, color: HubStyle.textPrimary),
        title: const Text('Emergency'),
        content: const Text(
          'Place a call to police emergency ($_emergencyNumber)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _placeEmergencyCall,
            child: const Text('Call $_emergencyNumber'),
          ),
        ],
      ),
    );
  }

  List<_ServiceTileData> get _services => [
        _ServiceTileData(
          icon: Icons.menu_book,
          label: 'Document\nLibrary',
          tint: HubTint.blue,
          onTap: _openLibrary,
        ),
        _ServiceTileData(
          icon: Icons.person_pin_circle,
          label: 'Wanted\nPersons',
          tint: HubTint.green,
          onTap: _openWanted,
          badgeCount: _kindCount(NotificationKind.wanted),
        ),
        _ServiceTileData(
          icon: Icons.person_search,
          label: 'Missing\nPersons',
          tint: HubTint.orange,
          onTap: _openMissing,
          badgeCount: _kindCount(NotificationKind.missing),
        ),
        _ServiceTileData(
          icon: Icons.directions_car,
          label: 'Stolen\nVehicles',
          tint: HubTint.red,
          onTap: _openStolenVehicles,
          badgeCount: _kindCount(NotificationKind.stolen),
        ),
        _ServiceTileData(
          icon: Icons.traffic,
          label: 'Traffic\nCodes',
          tint: HubTint.purple,
          onTap: _openTrafficCodes,
        ),
        _ServiceTileData(
          icon: Icons.campaign,
          label: 'Force\nNews',
          tint: HubTint.blue,
          onTap: _openNews,
          badgeCount: _kindCount(NotificationKind.news),
        ),
        _ServiceTileData(
          icon: Icons.event_available,
          label: 'Calendar',
          tint: HubTint.teal,
          onTap: _openCalendar,
        ),
        _ServiceTileData(
          icon: Icons.edit_note,
          label: 'Notes',
          tint: HubTint.orange,
          onTap: _openNotes,
        ),
        _ServiceTileData(
          icon: Icons.map,
          label: 'Map',
          tint: HubTint.purple,
          onTap: _openMap,
        ),
        _ServiceTileData(
          icon: Icons.contact_phone,
          label: 'Directory',
          tint: HubTint.green,
          onTap: _openDirectory,
        ),
        _ServiceTileData(
          icon: Icons.forum,
          label: 'Chat',
          tint: HubTint.blue,
          onTap: _openChat,
          badgeCount: _chatUnread,
        ),
        _ServiceTileData(
          icon: Icons.email,
          label: 'Email',
          tint: HubTint.red,
          onTap: _openEmail,
          badgeCount: _kindCount(NotificationKind.email),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: HubStyle.pageBackground,
      drawer: const AppDrawer(),
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Home',
            leading: HubHeaderIconButton(
              icon: Icons.apps,
              tooltip: 'Menu',
              onPressed: _openMenu,
            ),
            actions: [
              IconTheme(
                data: const IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(newsRepository: _newsRepository),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _WelcomeCard(),
                  const SizedBox(height: 20),
                  _ServicesGrid(services: _services),
                  const SizedBox(height: 18),
                  _AlertBanner(onViewAlerts: _openNotifications),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _CallButton(onPressed: _showEmergencyCall),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _HomeBottomBar(
        onLibrary: _openLibrary,
        onNews: _openNews,
        onAbout: _openAbout,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HubStyle.heroRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: HubStyle.headerGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Row(
                children: [
                  const Expanded(child: _WelcomeText()),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.local_police,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
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

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome, Officer!',
          style: TextStyle(
            color: HubStyle.onGradient,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'JCF • Western Operations',
          style: TextStyle(color: HubStyle.onGradientMuted, fontSize: 14),
        ),
        const SizedBox(height: 14),
        const _MottoPill(),
      ],
    );
  }
}

class _MottoPill extends StatelessWidget {
  const _MottoPill();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Serve',
                  style: base.copyWith(color: HubStyle.accentStripe[0]),
                ),
                const TextSpan(
                  text: '  •  ',
                  style: TextStyle(color: HubStyle.onGradient, fontSize: 13),
                ),
                TextSpan(
                  text: 'Protect',
                  style: base.copyWith(color: HubStyle.accentStripe[1]),
                ),
                const TextSpan(
                  text: '  •  ',
                  style: TextStyle(color: HubStyle.onGradient, fontSize: 13),
                ),
                TextSpan(
                  text: 'Together',
                  style: base.copyWith(color: HubStyle.accentStripe[2]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.services});

  final List<_ServiceTileData> services;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final data = services[index];
        return HubServiceTile(
          icon: data.icon,
          label: data.label,
          tint: data.tint,
          onTap: data.onTap,
          badgeCount: data.badgeCount,
        );
      },
    );
  }
}

class _ServiceTileData {
  const _ServiceTileData({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final HubTint tint;
  final VoidCallback onTap;
  final int badgeCount;
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.onViewAlerts});

  final VoidCallback onViewAlerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: HubStyle.navBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Alert. Stay Safe.',
                  style: TextStyle(
                    color: HubStyle.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your awareness makes a difference.',
                  style:
                      TextStyle(color: HubStyle.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onViewAlerts,
            style: OutlinedButton.styleFrom(
              foregroundColor: HubTint.blue.foreground,
              side: BorderSide(color: HubTint.blue.foreground),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View Alerts', style: TextStyle(fontSize: 12.5)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: HubStyle.pageBackground, width: 4),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: HubTint.blue.foreground,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'Emergency call',
        child: const Icon(Icons.call),
      ),
    );
  }
}

class _HomeBottomBar extends StatelessWidget {
  const _HomeBottomBar({
    required this.onLibrary,
    required this.onNews,
    required this.onAbout,
  });

  final VoidCallback onLibrary;
  final VoidCallback onNews;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: HubStyle.navBackground,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomBarItem(
              icon: Icons.home,
              label: 'Home',
              selected: true,
              onTap: () {},
            ),
            _BottomBarItem(
              icon: Icons.menu_book,
              label: 'Library',
              onTap: onLibrary,
            ),
            const SizedBox(width: 56),
            _BottomBarItem(
              icon: Icons.campaign,
              label: 'News',
              onTap: onNews,
            ),
            _BottomBarItem(
              icon: Icons.info_outline,
              label: 'About',
              onTap: onAbout,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? HubTint.blue.foreground : Colors.white.withValues(alpha: 0.75);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

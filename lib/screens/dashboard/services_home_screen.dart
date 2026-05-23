import 'package:flutter/material.dart';

import '../../services/news/in_memory_news_repository.dart';
import '../../services/news/news_repository.dart';
import '../about_screen.dart';
import '../calendar/calendar_screen.dart';
import '../documents/documents_home_screen.dart';
import '../map/map_screen.dart';
import '../news/news_feed_screen.dart';
import '../notes/notes_screen.dart';
import '../westops/missing_list_screen.dart';
import '../westops/stolen_vehicles_list_screen.dart';
import '../westops/traffic_codes_list_screen.dart';
import '../westops/wanted_list_screen.dart';

/// Palette for the services-style landing. Kept local so the global
/// field-manual theme is untouched.
class _HomePalette {
  const _HomePalette._();

  static const Color inkBlack = Color(0xFF04080F);
  static const Color glaucous = Color(0xFF507DBC);
  static const Color powderBlue = Color(0xFFA1C6EA);
  static const Color alabasterGrey = Color(0xFFDAE3E5);

  static const Color headerBlue = glaucous;
  static const Color tileIconBackground = powderBlue;
  static const Color tileIcon = glaucous;
  static const Color navBar = inkBlack;
  static const Color callButton = glaucous;
  static const Color navSelected = powderBlue;
  static const Color scaffold = alabasterGrey;
}

const String _emergencyNumber = '119';

/// Reference-style home: welcome card, "Our Services" grid, red bottom nav
/// with a centred emergency-call button. The welcome card carries no photo.
class ServicesHomeScreen extends StatefulWidget {
  const ServicesHomeScreen({super.key});

  @override
  State<ServicesHomeScreen> createState() => _ServicesHomeScreenState();
}

class _ServicesHomeScreenState extends State<ServicesHomeScreen> {
  final NewsRepository _newsRepository = InMemoryNewsRepository();

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openLibrary() => _open(const DocumentsHomeScreen());
  void _openWanted() => _open(const WantedListScreen());
  void _openMissing() => _open(const MissingListScreen());
  void _openStolenVehicles() => _open(const StolenVehiclesListScreen());
  void _openTrafficCodes() => _open(const TrafficCodesListScreen());
  void _openNews() => _open(NewsFeedScreen(repository: _newsRepository));
  void _openCalendar() => _open(const CalendarScreen());
  void _openNotes() => _open(const NotesScreen());
  void _openMap() => _open(const MapScreen());
  void _openAbout() => _open(const AboutScreen());

  void _showEmergencyCall() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.call, color: _HomePalette.callButton),
        title: const Text('Emergency'),
        content: const Text('Place a call to police emergency ($_emergencyNumber)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
          onTap: _openLibrary,
        ),
        _ServiceTileData(
          icon: Icons.person_pin_circle,
          label: 'Wanted\nPersons',
          onTap: _openWanted,
        ),
        _ServiceTileData(
          icon: Icons.person_search,
          label: 'Missing\nPersons',
          onTap: _openMissing,
        ),
        _ServiceTileData(
          icon: Icons.directions_car,
          label: 'Stolen\nVehicles',
          onTap: _openStolenVehicles,
        ),
        _ServiceTileData(
          icon: Icons.traffic,
          label: 'Traffic\nCodes',
          onTap: _openTrafficCodes,
        ),
        _ServiceTileData(
          icon: Icons.campaign,
          label: 'Force\nNews',
          onTap: _openNews,
        ),
        _ServiceTileData(
          icon: Icons.event,
          label: 'Calendar',
          onTap: _openCalendar,
        ),
        _ServiceTileData(
          icon: Icons.note_alt,
          label: 'Notes',
          onTap: _openNotes,
        ),
        _ServiceTileData(
          icon: Icons.map,
          label: 'Map',
          onTap: _openMap,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomePalette.scaffold,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeCard(),
              const SizedBox(height: 24),
              _ServicesGrid(services: _services),
            ],
          ),
        ),
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _HomePalette.headerBlue,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.apps),
        tooltip: 'Menu',
        onPressed: _openLibrary,
      ),
      title: const Text(
        'Home',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          tooltip: 'Notifications',
          onPressed: _openNews,
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_HomePalette.glaucous, _HomePalette.inkBlack],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, Officer!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'JCF · Western Operations',
            style: TextStyle(color: Colors.white70, fontSize: 14),
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
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) => _ServiceTile(data: services[index]),
    );
  }
}

class _ServiceTileData {
  const _ServiceTileData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.data});

  final _ServiceTileData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _HomePalette.tileIconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: _HomePalette.tileIcon, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: _HomePalette.callButton,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      tooltip: 'Emergency call',
      child: const Icon(Icons.call),
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
      color: _HomePalette.navBar,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 56,
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
            const SizedBox(width: 48),
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
    final color = selected ? _HomePalette.navSelected : Colors.white;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

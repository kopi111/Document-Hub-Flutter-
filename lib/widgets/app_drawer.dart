import 'package:flutter/material.dart';

import '../screens/about_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/westops/stolen_vehicles_list_screen.dart';
import '../screens/westops/traffic_codes_list_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _DrawerHeader(),
            const _SectionLabel('Tools'),
            _Entry(
              icon: Icons.event_outlined,
              label: 'Calendar',
              screen: const CalendarScreen(),
            ),
            _Entry(
              icon: Icons.notes_outlined,
              label: 'Notes',
              screen: const NotesScreen(),
            ),
            _Entry(
              icon: Icons.map_outlined,
              label: 'Map',
              screen: const MapScreen(),
            ),
            const Divider(),
            const _SectionLabel('Western Operations'),
            _Entry(
              icon: Icons.directions_car_outlined,
              label: 'Stolen Vehicles',
              screen: const StolenVehiclesListScreen(),
            ),
            _Entry(
              icon: Icons.traffic_outlined,
              label: 'Traffic Codes',
              screen: const TrafficCodesListScreen(),
            ),
            const Divider(),
            const _SectionLabel('Other'),
            _Entry(
              icon: Icons.info_outline,
              label: 'About',
              screen: const AboutScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(color: colors.primaryContainer),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: colors.onPrimaryContainer.withValues(alpha: 0.12),
            child: Icon(Icons.shield, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JCF Duty',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Western Operations',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: colors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.label,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}

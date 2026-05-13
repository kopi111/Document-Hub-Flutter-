import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';
import 'about_screen.dart';
import 'westops/stolen_vehicles_list_screen.dart';
import 'westops/traffic_codes_list_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionLabel(label: 'Western Operations'),
          _MoreTile(
            icon: Icons.directions_car_outlined,
            title: 'Stolen Vehicles',
            subtitle: 'Vehicle theft registry',
            onTap: () => _open(context, const StolenVehiclesListScreen()),
          ),
          _MoreTile(
            icon: Icons.traffic_outlined,
            title: 'Traffic Codes',
            subtitle: 'Road Traffic Act reference',
            onTap: () => _open(context, const TrafficCodesListScreen()),
          ),
          const Divider(),
          _SectionLabel(label: 'About the app'),
          _MoreTile(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version, proposal, contacts, licences',
            onTap: () => _open(context, const AboutScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

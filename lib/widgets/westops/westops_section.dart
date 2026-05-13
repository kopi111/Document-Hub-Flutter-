import 'package:flutter/material.dart';

import '../../screens/westops/missing_list_screen.dart';
import '../../screens/westops/stolen_vehicles_list_screen.dart';
import '../../screens/westops/traffic_codes_list_screen.dart';
import '../../screens/westops/wanted_list_screen.dart';

/// Identifies the four ported Western Operations features.
///
/// The home screen uses this enum both to render its WestOps tile group and
/// to drive the tablet two-pane detail slot through `WestOpsSelection`.
enum WestOpsFeature {
  wantedPersons,
  missingPersons,
  stolenVehicles,
  trafficCodes,
}

/// Describes the metadata + builder pair for one WestOps feature.
class WestOpsFeatureSpec {
  final WestOpsFeature feature;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const WestOpsFeatureSpec({
    required this.feature,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

const List<WestOpsFeatureSpec> westOpsFeatureSpecs = [
  WestOpsFeatureSpec(
    feature: WestOpsFeature.wantedPersons,
    title: 'Wanted Persons',
    subtitle: 'Persons of interest',
    icon: Icons.person_pin_circle,
    color: Colors.red,
    builder: _buildWantedListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.missingPersons,
    title: 'Missing Persons',
    subtitle: 'Open missing reports',
    icon: Icons.person_search,
    color: Colors.orange,
    builder: _buildMissingListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.stolenVehicles,
    title: 'Stolen Vehicles',
    subtitle: 'Vehicle theft registry',
    icon: Icons.directions_car,
    color: Colors.indigo,
    builder: _buildStolenVehiclesListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.trafficCodes,
    title: 'Traffic Codes',
    subtitle: 'RTA offence lookup',
    icon: Icons.traffic,
    color: Colors.teal,
    builder: _buildTrafficCodesListScreen,
  ),
];

Widget _buildWantedListScreen(BuildContext _) => const WantedListScreen();
Widget _buildMissingListScreen(BuildContext _) => const MissingListScreen();
Widget _buildStolenVehiclesListScreen(BuildContext _) =>
    const StolenVehiclesListScreen();
Widget _buildTrafficCodesListScreen(BuildContext _) =>
    const TrafficCodesListScreen();

/// Renders a labelled "Western Operations" group of feature tiles for the
/// phone layout. Tablet layouts use `WestOpsSidebarSection` instead.
class WestOpsSection extends StatelessWidget {
  const WestOpsSection({super.key, required this.onSelect});

  final void Function(WestOpsFeatureSpec spec) onSelect;

  static const double _tileAspectRatio = 1.4;
  static const int _crossAxisCount = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: _crossAxisCount,
            childAspectRatio: _tileAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: westOpsFeatureSpecs
                .map((spec) => _WestOpsTile(spec: spec, onSelect: onSelect))
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Western Operations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _WestOpsTile extends StatelessWidget {
  const _WestOpsTile({required this.spec, required this.onSelect});

  final WestOpsFeatureSpec spec;
  final void Function(WestOpsFeatureSpec) onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onSelect(spec),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                spec.color.withValues(alpha: 0.15),
                spec.color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(spec.icon, size: 36, color: spec.color),
              const SizedBox(height: 8),
              Text(
                spec.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: spec.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                spec.subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sidebar block of WestOps entries for the tablet two-pane layout.
class WestOpsSidebarSection extends StatelessWidget {
  const WestOpsSidebarSection({
    super.key,
    required this.selectedFeature,
    required this.onSelect,
  });

  final WestOpsFeature? selectedFeature;
  final void Function(WestOpsFeatureSpec spec) onSelect;

  @override
  Widget build(BuildContext context) {
    final tiles = westOpsFeatureSpecs.map((spec) {
      final selected = spec.feature == selectedFeature;
      return ListTile(
        leading: Icon(spec.icon, color: spec.color),
        title: Text(spec.title),
        subtitle: Text(spec.subtitle),
        selected: selected,
        onTap: () => onSelect(spec),
      );
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'WESTERN OPERATIONS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...tiles,
      ],
    );
  }
}

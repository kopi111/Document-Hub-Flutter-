import 'package:flutter/material.dart';

import '../../screens/westops/missing_list_screen.dart';
import '../../screens/westops/stolen_vehicles_list_screen.dart';
import '../../screens/westops/traffic_codes_list_screen.dart';
import '../../screens/westops/wanted_list_screen.dart';

/// Identifies the four ported Western Operations features.
enum WestOpsFeature {
  wantedPersons,
  missingPersons,
  stolenVehicles,
  trafficCodes,
}

/// Metadata + builder pair for one WestOps feature.
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
    color: Color(0xFFB3261E),
    builder: _buildWantedListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.missingPersons,
    title: 'Missing Persons',
    subtitle: 'Open missing reports',
    icon: Icons.person_search,
    color: Color(0xFF356E78),
    builder: _buildMissingListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.stolenVehicles,
    title: 'Stolen Vehicles',
    subtitle: 'Vehicle theft registry',
    icon: Icons.directions_car,
    color: Color(0xFF11243C),
    builder: _buildStolenVehiclesListScreen,
  ),
  WestOpsFeatureSpec(
    feature: WestOpsFeature.trafficCodes,
    title: 'Traffic Codes',
    subtitle: 'RTA offence lookup',
    icon: Icons.traffic,
    color: Color(0xFF8C7A20),
    builder: _buildTrafficCodesListScreen,
  ),
];

Widget _buildWantedListScreen(BuildContext _) => const WantedListScreen();
Widget _buildMissingListScreen(BuildContext _) => const MissingListScreen();
Widget _buildStolenVehiclesListScreen(BuildContext _) =>
    const StolenVehiclesListScreen();
Widget _buildTrafficCodesListScreen(BuildContext _) =>
    const TrafficCodesListScreen();

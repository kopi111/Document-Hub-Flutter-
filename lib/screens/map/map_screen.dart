import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/map/police_locations.dart';
import '../../theme/hub_style.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/notifications_bell.dart';

/// Visual treatment for each kind of police location plotted on the map.
extension on PoliceLocationKind {
  String get label => switch (this) {
        PoliceLocationKind.station => 'Stations',
        PoliceLocationKind.post => 'Posts',
        PoliceLocationKind.headquarters => 'Headquarters',
      };

  IconData get icon => switch (this) {
        PoliceLocationKind.station => Icons.local_police,
        PoliceLocationKind.post => Icons.flag,
        PoliceLocationKind.headquarters => Icons.account_balance,
      };

  HubTint get tint => switch (this) {
        PoliceLocationKind.station => HubTint.blue,
        PoliceLocationKind.post => HubTint.teal,
        PoliceLocationKind.headquarters => HubTint.purple,
      };
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.locations = kJamaicaPoliceLocations});

  final List<PoliceLocation> locations;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _kingstonCenter = LatLng(17.9712, -76.7929);
  static const double _initialZoom = 11;
  static const double _focusZoom = 15;

  final MapController _controller = MapController();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  PoliceLocationKind? _kindFilter;

  /// The location kinds that actually appear in the dataset, in the order they
  /// are first encountered. Kinds with no records are never offered as filters.
  late final List<PoliceLocationKind> _availableKinds = _collectKinds();

  List<PoliceLocationKind> _collectKinds() {
    final seen = <PoliceLocationKind>[];
    for (final location in widget.locations) {
      if (!seen.contains(location.kind)) seen.add(location.kind);
    }
    return seen;
  }

  List<PoliceLocation> get _visibleLocations {
    final lower = _query.toLowerCase();
    return widget.locations.where((location) {
      if (_kindFilter != null && location.kind != _kindFilter) return false;
      if (lower.isNotEmpty && !location.name.toLowerCase().contains(lower)) {
        return false;
      }
      return true;
    }).toList();
  }

  int _countOf(PoliceLocationKind kind) =>
      widget.locations.where((location) => location.kind == kind).length;

  void _selectKind(PoliceLocationKind? kind) {
    setState(() => _kindFilter = _kindFilter == kind ? null : kind);
  }

  void _focusOn(PoliceLocation location) {
    _controller.move(LatLng(location.latitude, location.longitude), _focusZoom);
  }

  void _recenter() => _controller.move(_kingstonCenter, _initialZoom);

  Future<void> _openDirections() async {
    final target = _visibleLocations.isNotEmpty
        ? _visibleLocations.first
        : widget.locations.first;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${target.latitude},${target.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open directions to ${target.name}')),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Map',
            showBack: true,
            actions: [
              HubHeaderIconButton(
                icon: Icons.center_focus_strong,
                tooltip: 'Recenter',
                onPressed: _recenter,
              ),
              const IconTheme(
                data: IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 14),
        _buildStatChips(),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Quick Filters'),
        ),
        const SizedBox(height: 10),
        _buildFilterPills(),
        const SizedBox(height: 18),
        SizedBox(
          height: 360,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MapCard(
              controller: _controller,
              center: _kingstonCenter,
              zoom: _initialZoom,
              locations: _visibleLocations,
              onRecenter: _recenter,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Plan Your Route'),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _RouteBanner(onGetDirections: _openDirections),
        ),
        if (_visibleLocations.isNotEmpty) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(
              title: 'Locations',
              actionLabel: '${_visibleLocations.length} shown',
            ),
          ),
          const SizedBox(height: 10),
          ..._visibleLocations.take(8).map(
                (location) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _LocationCard(
                    location: location,
                    onTap: () => _focusOn(location),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildStatChips() {
    final chips = <Widget>[
      _StatChip(
        icon: Icons.public,
        count: widget.locations.length,
        label: 'Total Plotted',
        tint: HubTint.green,
      ),
      for (final kind in _availableKinds)
        _StatChip(
          icon: kind.icon,
          count: _countOf(kind),
          label: kind.label,
          tint: kind.tint,
        ),
    ];
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _buildFilterPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _kindFilter == null,
        onTap: () => _selectKind(null),
      ),
      for (final kind in _availableKinds)
        HubFilterPill(
          label: kind.label,
          icon: kind.icon,
          accent: kind.tint.foreground,
          selected: _kindFilter == kind,
          onTap: () => _selectKind(kind),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: HubStyle.cardShadow,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Search location, address, or area...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: HubStyle.textSecondary),
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final int count;
  final String label;
  final HubTint tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint.foreground, size: 18),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: HubStyle.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: HubStyle.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.controller,
    required this.center,
    required this.zoom,
    required this.locations,
    required this.onRecenter,
  });

  final MapController controller;
  final LatLng center;
  final double zoom;
  final List<PoliceLocation> locations;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.heroRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HubStyle.heroRadius),
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 6,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  // tile.openstreetmap.org is IPv6-only on the JCF network and
                  // fails to load; the OSM-France mirror is IPv4-reachable and
                  // CORS-enabled, with the same standard OSM cartography.
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'jm.gov.jcf.document_hub',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: [for (final l in locations) _markerFor(l)]),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onTap: () => controller.move(
                      controller.camera.center,
                      controller.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(
                    icon: Icons.remove,
                    onTap: () => controller.move(
                      controller.camera.center,
                      controller.camera.zoom - 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ZoomButton(icon: Icons.my_location, onTap: onRecenter),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _markerFor(PoliceLocation location) {
    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: 36,
      height: 36,
      child: Icon(
        Icons.location_pin,
        color: location.kind.tint.foreground,
        size: 32,
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HubStyle.cardSurface,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: HubStyle.textPrimary, size: 22),
        ),
      ),
    );
  }
}

class _RouteBanner extends StatelessWidget {
  const _RouteBanner({required this.onGetDirections});

  final VoidCallback onGetDirections;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HubTint.purple.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions,
              color: HubTint.purple.foreground,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Your Route',
                  style: TextStyle(
                    color: HubStyle.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Open turn-by-turn directions in Maps',
                  style: TextStyle(
                    color: HubStyle.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onGetDirections,
            child: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location, required this.onTap});

  final PoliceLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = location.kind.tint;
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
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: tint.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(location.kind.icon, color: tint.foreground, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${location.latitude.toStringAsFixed(4)}, '
                        '${location.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.near_me_outlined,
                  color: HubStyle.textSecondary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

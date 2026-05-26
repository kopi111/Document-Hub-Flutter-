import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/jcf_palette.dart';
import '../../widgets/breadcrumb_trail.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _kingstonCenter = LatLng(17.9712, -76.7929);
  static const double _initialZoom = 11;

  final MapController _controller = MapController();
  final List<Marker> _markers = const [
    Marker(
      point: LatLng(17.9712, -76.7929),
      width: 40,
      height: 40,
      child: Icon(Icons.location_pin, color: JcfPalette.danger, size: 36),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Recenter',
            onPressed: () => _controller.move(_kingstonCenter, _initialZoom),
          ),
        ],
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments()),
      ),
      body: FlutterMap(
        mapController: _controller,
        options: const MapOptions(
          initialCenter: _kingstonCenter,
          initialZoom: _initialZoom,
          minZoom: 6,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'jm.gov.jcf.document_hub',
            maxZoom: 19,
          ),
          MarkerLayer(markers: _markers),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
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
      const BreadcrumbSegment(label: 'Map'),
    ];
  }
}

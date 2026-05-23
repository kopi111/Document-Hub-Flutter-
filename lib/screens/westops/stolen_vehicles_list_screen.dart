import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/stolen_vehicle.dart';
import '../../services/westops/stolen_vehicles_repository.dart';
import '../../theme/duty_theme.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import 'stolen_vehicle_detail_screen.dart';

class StolenVehiclesListScreen extends StatefulWidget {
  const StolenVehiclesListScreen({super.key, this.repository});

  final StolenVehiclesRepository? repository;

  @override
  State<StolenVehiclesListScreen> createState() =>
      _StolenVehiclesListScreenState();
}

class _StolenVehiclesListScreenState extends State<StolenVehiclesListScreen> {
  late final StolenVehiclesRepository _repository =
      widget.repository ?? const InMemoryStolenVehiclesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<StolenVehicle> _all = [];
  List<StolenVehicle> _visible = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _repository.listAll();
      if (!mounted) return;
      setState(() {
        _all = records;
        _visible = records;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load stolen vehicles: $error';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _filtered(query);
    });
  }

  List<StolenVehicle> _filtered(String query) {
    if (query.isEmpty) return _all;
    final lower = query.toLowerCase();
    return _all.where((vehicle) {
      if (vehicle.make.toLowerCase().contains(lower)) return true;
      if (vehicle.model.toLowerCase().contains(lower)) return true;
      final plate = vehicle.licensePlate;
      if (plate != null && plate.toLowerCase().contains(lower)) return true;
      final color = vehicle.color;
      if (color != null && color.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _openDetail(StolenVehicle vehicle) {
    Navigator.push(
      context,
      sharedAxis(StolenVehicleDetailScreen(vehicle: vehicle)),
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
      appBar: AppBar(
        title: const Text('Stolen Vehicles'),
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: _buildBody(),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments(BuildContext context) {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'Western Operations'),
      const BreadcrumbSegment(label: 'Stolen Vehicles'),
    ];
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return Column(
      children: [
        _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        _ResultsHeader(count: _visible.length),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRecords,
            child: _VehicleList(vehicles: _visible, onOpen: _openDetail),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: DutyTheme.mono(size: 13),
        decoration: InputDecoration(
          hintText: 'Search by make, model, plate or colour',
          hintStyle: DutyTheme.mono(
            size: 12,
            color: colors.mutedGold,
            letterSpacing: 0.4,
          ),
          prefixIcon: Icon(Icons.search, size: 18, color: colors.mutedGold),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear search',
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Container(width: 18, height: 1, color: colors.mutedGold),
          const SizedBox(width: 10),
          Text(
            '${count.toString().padLeft(3, '0')}  STOLEN VEHICLES',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _VehicleList extends StatelessWidget {
  const _VehicleList({required this.vehicles, required this.onOpen});

  final List<StolenVehicle> vehicles;
  final void Function(StolenVehicle) onOpen;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No stolen vehicles found')),
        ],
      );
    }
    final colors = Theme.of(context).extension<DutyColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vehicles.length,
      separatorBuilder: (_, _) => Container(height: 1, color: colors.hairline),
      itemBuilder: (context, index) {
        return _VehicleRow(
          vehicle: vehicles[index],
          onTap: () => onOpen(vehicles[index]),
        );
      },
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle, required this.onTap});

  final StolenVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(photoUrl: vehicle.photoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vehicle.licensePlate != null)
                    _PlateChip(plate: vehicle.licensePlate!),
                  if (vehicle.licensePlate != null) const SizedBox(height: 8),
                  Text(
                    vehicle.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.15,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (vehicle.color != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      vehicle.color!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'STOLEN  ·  ${_formatDate(vehicle.dateStolen)}',
                    style: DutyTheme.mono(
                      size: 10,
                      color: colors.mutedGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.plate});
  final String plate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: colors.hairline),
        color: scheme.surface,
      ),
      child: Text(
        plate.toUpperCase(),
        style: DutyTheme.mono(
          size: 12,
          weight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: colors.hairline),
        color: scheme.surfaceContainerHighest,
      ),
      child: Icon(
        Icons.directions_car_outlined,
        size: 28,
        color: colors.mutedGold,
      ),
    );
    if (url == null || url.isEmpty) return placeholder;
    return SizedBox(
      width: 64,
      height: 64,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, url, error) => placeholder,
      ),
    );
  }
}

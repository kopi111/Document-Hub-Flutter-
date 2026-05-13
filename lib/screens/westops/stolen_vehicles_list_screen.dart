import 'package:flutter/material.dart';

import '../../models/westops/stolen_vehicle.dart';
import '../../services/westops/stolen_vehicles_repository.dart';
import '../../widgets/breadcrumb_trail.dart';
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
      MaterialPageRoute(
        builder: (_) => StolenVehicleDetailScreen(vehicle: vehicle),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stolen Vehicles'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
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
        _buildSearchField(),
        _buildResultsHeader(),
        const SizedBox(height: 4),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by make, model, plate or colour...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${_visible.length} stolen vehicles',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_visible.isEmpty) {
      return const Center(child: Text('No stolen vehicles found'));
    }
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) => _StolenVehicleTile(
        vehicle: _visible[index],
        onOpen: _openDetail,
      ),
    );
  }
}

class _StolenVehicleTile extends StatelessWidget {
  const _StolenVehicleTile({required this.vehicle, required this.onOpen});

  final StolenVehicle vehicle;
  final void Function(StolenVehicle) onOpen;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle.licensePlate ?? 'Plate unknown';
    final color = vehicle.color;
    final subtitle = color == null ? plate : '$color — $plate';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade100,
        child: const Icon(Icons.directions_car, color: Colors.indigo),
      ),
      title: Text(
        vehicle.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onOpen(vehicle),
    );
  }
}

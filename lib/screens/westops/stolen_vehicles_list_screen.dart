import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/stolen_vehicle.dart';
import '../../services/westops/stolen_vehicles_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';
import '../../widgets/notifications_bell.dart';
import 'add_stolen_vehicle_screen.dart';
import 'stolen_vehicle_detail_screen.dart';

/// A vehicle-type grouping derived from keywords in the make/model, since the
/// record has no explicit type column.
class _VehicleCategory {
  const _VehicleCategory({
    required this.label,
    required this.icon,
    required this.tint,
    required this.keywords,
  });

  final String label;
  final IconData icon;
  final HubTint tint;
  final List<String> keywords;

  bool matches(StolenVehicle vehicle) {
    final text = '${vehicle.make} ${vehicle.model}'.toLowerCase();
    return keywords.any(text.contains);
  }
}

const List<_VehicleCategory> _categories = [
  _VehicleCategory(
    label: 'Motorcycles',
    icon: Icons.two_wheeler,
    tint: HubTint.purple,
    keywords: ['bike', 'motorcycle', 'cbr', 'ninja', 'harley', 'yamaha', 'ktm'],
  ),
  _VehicleCategory(
    label: 'Trucks & Pickups',
    icon: Icons.local_shipping,
    tint: HubTint.orange,
    keywords: ['hilux', 'truck', 'pickup', 'tacoma', 'frontier', 'ranger',
        'navara', 'd-max', 'dmax', 'tundra'],
  ),
  _VehicleCategory(
    label: 'SUVs',
    icon: Icons.airport_shuttle,
    tint: HubTint.teal,
    keywords: ['cr-v', 'crv', 'rav4', 'pajero', 'prado', 'fortuner',
        'x-trail', 'xtrail', 'rush', 'terios', 'escape', 'cx-5', 'cx5'],
  ),
  _VehicleCategory(
    label: 'Cars',
    icon: Icons.directions_car,
    tint: HubTint.blue,
    keywords: ['corolla', 'tiida', 'swift', 'demio', 'lancer', 'civic',
        'sentra', 'axio', 'fielder', 'note', 'march', 'vitz', 'yaris'],
  ),
];

enum _Sort { newest, oldest, makeAlpha }

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
  bool _loading = true;
  String? _error;

  String _query = '';
  _VehicleCategory? _category;
  _Sort _sort = _Sort.newest;

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

  List<StolenVehicle> get _visible {
    final lower = _query.toLowerCase();
    final filtered = _all.where((vehicle) {
      if (lower.isNotEmpty && !_matchesQuery(vehicle, lower)) return false;
      if (_category != null && !_category!.matches(vehicle)) return false;
      return true;
    }).toList();
    _sortInPlace(filtered);
    return filtered;
  }

  bool _matchesQuery(StolenVehicle vehicle, String lower) {
    if (vehicle.make.toLowerCase().contains(lower)) return true;
    if (vehicle.model.toLowerCase().contains(lower)) return true;
    final plate = vehicle.licensePlate;
    if (plate != null && plate.toLowerCase().contains(lower)) return true;
    final color = vehicle.color;
    if (color != null && color.toLowerCase().contains(lower)) return true;
    return false;
  }

  void _sortInPlace(List<StolenVehicle> vehicles) {
    switch (_sort) {
      case _Sort.newest:
        vehicles.sort((a, b) => b.dateStolen.compareTo(a.dateStolen));
      case _Sort.oldest:
        vehicles.sort((a, b) => a.dateStolen.compareTo(b.dateStolen));
      case _Sort.makeAlpha:
        vehicles.sort((a, b) => a.displayName.compareTo(b.displayName));
    }
  }

  List<StolenVehicle> get _recentlyAdded {
    final sorted = List<StolenVehicle>.from(_all)
      ..sort((a, b) => b.dateStolen.compareTo(a.dateStolen));
    return sorted.take(6).toList();
  }

  bool get _hasFilters => _query.isNotEmpty || _category != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
    });
  }

  void _toggleCategory(_VehicleCategory value) =>
      setState(() => _category = _category == value ? null : value);

  Future<void> _openDetail(StolenVehicle vehicle) async {
    await Navigator.push(
      context,
      sharedAxis(
        StolenVehicleDetailScreen(vehicle: vehicle, repository: _repository),
      ),
    );
    await _loadRecords();
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      sharedAxis(AddStolenVehicleScreen(repository: _repository)),
    );
    if (created == true) await _loadRecords();
  }

  void _showTipFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report a tip: call 119 or Crime Stop 311')),
    );
  }

  Future<void> _openSortSheet() async {
    final chosen = await showModalBottomSheet<_Sort>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _SortSheet(current: _sort),
    );
    if (chosen != null) setState(() => _sort = chosen);
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
            title: 'Stolen Vehicles',
            showBack: true,
            actions: const [
              IconTheme(
                data: IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFF2D6CDF),
        foregroundColor: HubStyle.onGradient,
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final visible = _visible;
    final recent = _recentlyAdded;
    final newestId = recent.isEmpty ? null : recent.first.id;

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchRow(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onSort: _openSortSheet,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HubStatBanner(
              icon: Icons.directions_car,
              count: _all.length.toString(),
              label: 'Stolen Vehicles',
              caption: 'Across all jurisdictions',
              actionLabel: 'View Alerts',
              onAction: _resetFilters,
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(title: 'Quick Filters'),
          ),
          const SizedBox(height: 10),
          _buildCategoryPills(),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: HubSectionHeading(title: 'Recently Added'),
            ),
            const SizedBox(height: 10),
            _buildRecentRow(recent, newestId),
          ],
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(title: 'Browse by Category'),
          ),
          const SizedBox(height: 10),
          _buildCategoryGrid(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TipBanner(onReport: _showTipFlow),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(
              title: _hasFilters ? 'Matching Vehicles' : 'All Stolen Vehicles',
              actionLabel: _hasFilters ? 'Clear' : null,
              onAction: _hasFilters ? _resetFilters : null,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${visible.length} of ${_all.length} vehicles',
              style: const TextStyle(
                color: HubStyle.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 30),
              child: Center(
                child: Text(
                  'No matching vehicles',
                  style: TextStyle(color: HubStyle.textSecondary),
                ),
              ),
            )
          else
            ...visible.map(
              (vehicle) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _VehicleCard(
                  vehicle: vehicle,
                  onTap: () => _openDetail(vehicle),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _category == null,
        onTap: () => setState(() => _category = null),
      ),
      for (final category in _categories)
        HubFilterPill(
          label: category.label,
          icon: category.icon,
          accent: category.tint.foreground,
          selected: _category == category,
          onTap: () => _toggleCategory(category),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  Widget _buildRecentRow(List<StolenVehicle> recent, String? newestId) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final vehicle = recent[index];
          return _RecentCard(
            vehicle: vehicle,
            isNew: vehicle.id == newestId,
            onTap: () => _openDetail(vehicle),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: [
          for (final category in _categories)
            HubCategoryCard(
              icon: category.icon,
              title: category.label,
              count: '${_all.where(category.matches).length} vehicles',
              tint: category.tint,
              selected: _category == category,
              onTap: () => _toggleCategory(category),
            ),
        ],
      ),
    );
  }
}

/// Resolves the type icon for a vehicle from its category keywords, falling
/// back to a generic car when no category matches.
IconData _iconFor(StolenVehicle vehicle) {
  for (final category in _categories) {
    if (category.matches(vehicle)) return category.icon;
  }
  return Icons.directions_car;
}

HubTint _tintFor(StolenVehicle vehicle) {
  for (final category in _categories) {
    if (category.matches(vehicle)) return category.tint;
  }
  return HubTint.blue;
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _stolenAgo(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) return 'Stolen today';
  if (days == 1) return 'Stolen 1 day ago';
  if (days < 30) return 'Stolen $days days ago';
  final months = (days / 30).floor();
  if (months == 1) return 'Stolen 1 month ago';
  return 'Stolen $months months ago';
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onSort,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: HubStyle.cardSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: HubStyle.cardShadow,
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search stolen vehicles...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: HubStyle.textSecondary),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: HubStyle.cardSurface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onSort,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: HubStyle.cardShadow,
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, size: 18, color: HubStyle.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Sort',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final _Sort current;

  @override
  Widget build(BuildContext context) {
    const options = [
      (_Sort.newest, 'Newest first', Icons.schedule),
      (_Sort.oldest, 'Oldest first', Icons.history),
      (_Sort.makeAlpha, 'Make & model (A–Z)', Icons.sort_by_alpha),
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sort vehicles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HubStyle.textPrimary,
                ),
              ),
            ),
          ),
          for (final (sort, label, icon) in options)
            ListTile(
              leading: Icon(icon, color: HubStyle.textSecondary),
              title: Text(label),
              trailing: current == sort
                  ? const Icon(Icons.check, color: Color(0xFF2D6CDF))
                  : null,
              onTap: () => Navigator.of(context).pop(sort),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A small vehicle thumbnail: network photo, locally captured bytes, or a
/// tinted type icon when neither is present.
class _VehicleThumbnail extends StatelessWidget {
  const _VehicleThumbnail({required this.vehicle, required this.size});

  final StolenVehicle vehicle;
  final double size;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(vehicle);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Icon(_iconFor(vehicle), color: tint.foreground, size: size * 0.42),
    );

    final image = _imageProvider(vehicle.photoBytes, vehicle.photoUrl);
    if (image == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget? _imageProvider(Uint8List? bytes, String? url) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Icon(
          _iconFor(vehicle),
          color: _tintFor(vehicle).foreground,
          size: size * 0.42,
        ),
      );
    }
    return null;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final tint = status.toLowerCase().contains('recover')
        ? HubTint.green
        : HubTint.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: tint.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.vehicle,
    required this.isNew,
    required this.onTap,
  });

  final StolenVehicle vehicle;
  final bool isNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle.licensePlate;
    final location = vehicle.lastKnownLocation;
    return SizedBox(
      width: 180,
      child: DecoratedBox(
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _VehicleThumbnail(vehicle: vehicle, size: 156),
                      if (isNew)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0414C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _plateLine(plate, location),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stolenAgo(vehicle.dateStolen),
                    style: const TextStyle(
                      color: Color(0xFFE0414C),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _plateLine(String? plate, String? location) {
    if (plate != null && plate.isNotEmpty) {
      if (location != null && location.isNotEmpty) return '$plate · $location';
      return plate;
    }
    if (location != null && location.isNotEmpty) return location;
    return 'Plate unknown';
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onTap});

  final StolenVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final plate = vehicle.licensePlate;
    final status = vehicle.status;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VehicleThumbnail(vehicle: vehicle, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (status != null && status.isNotEmpty) ...[
                            _StatusChip(status: status),
                            const SizedBox(width: 8),
                          ],
                          if (plate != null && plate.isNotEmpty)
                            Flexible(
                              child: Text(
                                plate.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: HubStyle.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stolen · ${_formatDate(vehicle.dateStolen)}',
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: HubStyle.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.onReport});

  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.heroRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.visibility_outlined,
                color: Color(0xFFEF8A23),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See Something?',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Help recover stolen vehicles in your area.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: const Color(0xFF2D6CDF),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onReport,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    'Report a Tip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

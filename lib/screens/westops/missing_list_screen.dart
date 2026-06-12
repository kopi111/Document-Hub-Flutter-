import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';
import '../../widgets/notifications_bell.dart';
import 'add_missing_person_screen.dart';
import 'missing_detail_screen.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Quick filters offered above the missing list. Each bucket is backed by a
/// real `MissingPerson` field so counts never diverge from the data.
enum _Filter { all, active, found, adults, children }

extension on _Filter {
  String get label => switch (this) {
        _Filter.all => 'All',
        _Filter.active => 'Active',
        _Filter.found => 'Found',
        _Filter.adults => 'Adults',
        _Filter.children => 'Children',
      };

  IconData get icon => switch (this) {
        _Filter.all => Icons.dashboard_outlined,
        _Filter.active => Icons.error_outline,
        _Filter.found => Icons.check_circle_outline,
        _Filter.adults => Icons.person_outline,
        _Filter.children => Icons.child_care,
      };

  bool matches(MissingPerson person) {
    final age = _ageOf(person);
    return switch (this) {
      _Filter.all => true,
      _Filter.active => !person.isFound,
      _Filter.found => person.isFound,
      _Filter.adults => age != null && age >= 18,
      _Filter.children => age != null && age < 18,
    };
  }
}

/// A "Browse by Category" grouping, backed by a real field predicate.
class _Category {
  const _Category({
    required this.label,
    required this.icon,
    required this.tint,
    required this.filter,
  });

  final String label;
  final IconData icon;
  final HubTint tint;
  final _Filter filter;
}

const List<_Category> _categories = [
  _Category(
    label: 'Children',
    icon: Icons.child_care,
    tint: HubTint.orange,
    filter: _Filter.children,
  ),
  _Category(
    label: 'Adults',
    icon: Icons.person_outline,
    tint: HubTint.blue,
    filter: _Filter.adults,
  ),
  _Category(
    label: 'Active Cases',
    icon: Icons.error_outline,
    tint: HubTint.red,
    filter: _Filter.active,
  ),
  _Category(
    label: 'Located',
    icon: Icons.check_circle_outline,
    tint: HubTint.green,
    filter: _Filter.found,
  ),
];

/// Age preferring the stored [MissingPerson.age], otherwise derived from
/// [MissingPerson.dateOfBirth]. Returns null when neither is available.
int? _ageOf(MissingPerson person) {
  if (person.age != null) return person.age;
  final birth = person.dateOfBirth;
  if (birth == null) return null;
  final now = DateTime.now();
  var years = now.year - birth.year;
  final hadBirthday =
      now.month > birth.month || (now.month == birth.month && now.day >= birth.day);
  if (!hadBirthday) years -= 1;
  return years;
}

class MissingListScreen extends StatefulWidget {
  const MissingListScreen({super.key, this.repository});

  final MissingPersonsRepository? repository;

  @override
  State<MissingListScreen> createState() => _MissingListScreenState();
}

class _MissingListScreenState extends State<MissingListScreen> {
  late final MissingPersonsRepository _repository =
      widget.repository ?? const InMemoryMissingPersonsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<MissingPerson> _all = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  _Filter _filter = _Filter.all;

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
        _error = 'Failed to load missing persons: $error';
        _loading = false;
      });
    }
  }

  List<MissingPerson> get _visible {
    final query = _query.trim().toLowerCase();
    final results = _all.where((person) {
      if (!_filter.matches(person)) return false;
      if (query.isEmpty) return true;
      if (person.fullName.toLowerCase().contains(query)) return true;
      if (person.parish?.toLowerCase().contains(query) ?? false) return true;
      final location = person.lastSeenLocation;
      return location != null && location.toLowerCase().contains(query);
    }).toList();
    results.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
    return results;
  }

  List<MissingPerson> get _recentlyAdded {
    final ordered = [..._all]
      ..sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
    return ordered.take(6).toList();
  }

  int get _activeCount => _all.where((person) => !person.isFound).length;

  bool get _hasFilters => _query.isNotEmpty || _filter != _Filter.all;

  int _countFor(_Filter filter) =>
      _all.where(filter.matches).length;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _filter = _Filter.all;
    });
  }

  void _selectFilter(_Filter filter) => setState(() => _filter = filter);

  void _toggleCategory(_Filter filter) =>
      setState(() => _filter = _filter == filter ? _Filter.all : filter);

  Future<void> _openDetail(MissingPerson person) async {
    final changed = await Navigator.push<bool>(
      context,
      sharedAxis(MissingDetailScreen(person: person, repository: _repository)),
    );
    if (changed == true) await _loadRecords();
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      sharedAxis(AddMissingPersonScreen(repository: _repository)),
    );
    if (created == true) await _loadRecords();
  }

  void _submitTip() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open a case to log a sighting or tip')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: HubStyle.navBackground,
        foregroundColor: HubStyle.onGradient,
        icon: const Icon(Icons.add),
        label: const Text(
          'Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Missing Persons',
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
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final visible = _visible;
    final recent = _recentlyAdded;
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
              onFilter: _openFilterSheet,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HubStatBanner(
              icon: Icons.person_search,
              count: _activeCount.toString(),
              label: 'Active Missing',
              caption: 'Across all jurisdictions',
              actionLabel: 'View Alerts',
              onAction: () => _selectFilter(_Filter.active),
            ),
          ),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(title: 'Quick Filters'),
          ),
          const SizedBox(height: 10),
          _buildFilterPills(),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: HubSectionHeading(title: 'Recently Added'),
            ),
            const SizedBox(height: 10),
            _buildRecentRow(recent),
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
            child: HubSectionHeading(
              title: _hasFilters ? 'Matching Cases' : 'All Cases',
              actionLabel: _hasFilters ? 'Clear' : null,
              onAction: _hasFilters ? _resetFilters : null,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${visible.length} of ${_all.length} reports',
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
                  'No matching reports',
                  style: TextStyle(color: HubStyle.textSecondary),
                ),
              ),
            )
          else
            ...visible.map(
              (person) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _MissingCard(
                  person: person,
                  onTap: () => _openDetail(person),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HelpBanner(onTap: _submitTip),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final pills = <Widget>[
      for (final filter in _Filter.values)
        HubFilterPill(
          label: filter.label,
          icon: filter.icon,
          selected: _filter == filter,
          onTap: () => _selectFilter(filter),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  Widget _buildRecentRow(List<MissingPerson> recent) {
    final newestId = recent.first.id;
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final person = recent[index];
          return _RecentCard(
            person: person,
            isNewest: person.id == newestId,
            onTap: () => _openDetail(person),
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
              count: '${_countFor(category.filter)} cases',
              tint: category.tint,
              selected: _filter == category.filter,
              onTap: () => _toggleCategory(category.filter),
            ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final chosen = await showModalBottomSheet<_Filter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _FilterSheet(current: _filter),
    );
    if (chosen != null) _selectFilter(chosen);
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

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
                hintText: 'Search missing persons...',
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
            onTap: onFilter,
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
                    'Filter',
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

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.current});

  final _Filter current;

  @override
  Widget build(BuildContext context) {
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
                'Filter cases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HubStyle.textPrimary,
                ),
              ),
            ),
          ),
          for (final filter in _Filter.values)
            ListTile(
              leading: Icon(filter.icon, color: HubStyle.textSecondary),
              title: Text(filter.label),
              trailing: current == filter
                  ? const Icon(Icons.check, color: Color(0xFF2D6CDF))
                  : null,
              onTap: () => Navigator.of(context).pop(filter),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.person,
    required this.isNewest,
    required this.onTap,
  });

  final MissingPerson person;
  final bool isNewest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final age = _ageOf(person);
    return SizedBox(
      width: 150,
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
                  Row(
                    children: [
                      _Avatar(person: person, diameter: 44),
                      const Spacer(),
                      if (person.isFound) ...[
                        _StatusChip(found: true),
                        const SizedBox(width: 4),
                      ],
                      if (isNewest) const _NewBadge(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    person.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Age $age',
                      style: const TextStyle(
                        color: HubStyle.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _MetaLine(
                    icon: Icons.event_outlined,
                    text: 'Reported ${_formatDate(person.reportedDate)}',
                  ),
                  if (person.lastSeenLocation != null &&
                      person.lastSeenLocation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: Icons.place_outlined,
                      text: person.lastSeenLocation!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingCard extends StatelessWidget {
  const _MissingCard({required this.person, required this.onTap});

  final MissingPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final age = _ageOf(person);
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
                _Avatar(person: person, diameter: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              person.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HubStyle.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(found: person.isFound),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (age != null)
                        _MetaLine(icon: Icons.cake_outlined, text: 'Age $age'),
                      if (person.parish != null &&
                          person.parish!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _MetaLine(
                          icon: Icons.location_city_outlined,
                          text: person.parish!,
                        ),
                      ],
                      if (person.lastSeenLocation != null &&
                          person.lastSeenLocation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _MetaLine(
                          icon: Icons.place_outlined,
                          text: person.lastSeenLocation!,
                        ),
                      ],
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: Icons.event_outlined,
                        text: 'Reported ${_formatDate(person.reportedDate)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person, required this.diameter});

  final MissingPerson person;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final tint = person.isFound ? HubTint.green : HubTint.blue;
    return Hero(
      tag: 'missing:${person.id}',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: ClipOval(child: _image(tint)),
      ),
    );
  }

  Widget _image(HubTint tint) {
    final bytes = person.photoBytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialsPlate(tint),
      );
    }
    final url = person.photoUrl;
    if (url == null || url.isEmpty) return _initialsPlate(tint);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => _initialsPlate(tint),
      placeholder: (_, _) => _initialsPlate(tint),
    );
  }

  Widget _initialsPlate(HubTint tint) {
    return ColoredBox(
      color: tint.background,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: tint.foreground,
            fontSize: diameter * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String get _initials {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.found});

  final bool found;

  @override
  Widget build(BuildContext context) {
    final tint = found ? HubTint.green : HubTint.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        found ? 'Found' : 'Missing',
        style: TextStyle(
          color: tint.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: HubStyle.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HubStyle.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: HubTint.orange.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: HubTint.orange.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const tint = HubTint.red;
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
              decoration: BoxDecoration(
                color: tint.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: tint.foreground,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You Can Help',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Seen someone? Submit a tip.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _TipButton(onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _TipButton extends StatelessWidget {
  const _TipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HubStyle.navBackground,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            'Submit a Tip',
            style: TextStyle(
              color: HubStyle.onGradient,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

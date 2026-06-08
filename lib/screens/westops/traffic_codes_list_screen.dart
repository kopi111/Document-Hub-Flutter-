import 'package:flutter/material.dart';

import '../../models/westops/traffic_code.dart';
import '../../services/westops/traffic_codes_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';
import '../../widgets/notifications_bell.dart';
import 'traffic_code_detail_screen.dart';

/// Severity tier derived from a code's demerit points.
enum _Severity { none, minor, serious }

_Severity _severityOf(TrafficCode code) {
  if (code.demeritPoints == 0) return _Severity.none;
  if (code.demeritPoints <= 5) return _Severity.minor;
  return _Severity.serious;
}

extension on _Severity {
  String get label => switch (this) {
        _Severity.none => 'No Points',
        _Severity.minor => 'Minor',
        _Severity.serious => 'Serious',
      };

  HubTint get tint => switch (this) {
        _Severity.none => HubTint.green,
        _Severity.minor => HubTint.orange,
        _Severity.serious => HubTint.red,
      };
}

/// An offence-type grouping derived from keywords in the offence description.
class _Category {
  const _Category({
    required this.label,
    required this.icon,
    required this.tint,
    required this.keywords,
  });

  final String label;
  final IconData icon;
  final HubTint tint;
  final List<String> keywords;

  bool matches(TrafficCode code) {
    final text = code.offenceDescription.toLowerCase();
    return keywords.any(text.contains);
  }
}

const List<_Category> _categories = [
  _Category(
    label: 'Speed & Limits',
    icon: Icons.speed,
    tint: HubTint.blue,
    keywords: ['speed', 'limit', 'exceed'],
  ),
  _Category(
    label: 'Licence & Permits',
    icon: Icons.badge,
    tint: HubTint.purple,
    keywords: ['licence', 'license', 'permit'],
  ),
  _Category(
    label: 'Insurance & Docs',
    icon: Icons.description,
    tint: HubTint.teal,
    keywords: ['insurance', 'registration', 'certificate', 'fitness'],
  ),
  _Category(
    label: 'Careless & Dangerous',
    icon: Icons.warning_amber_rounded,
    tint: HubTint.orange,
    keywords: ['careless', 'dangerous', 'reckless', 'negligent'],
  ),
  _Category(
    label: 'Drink & Drugs',
    icon: Icons.local_bar,
    tint: HubTint.red,
    keywords: ['alcohol', 'drug', 'impair', 'intoxic', 'breath', 'influence'],
  ),
  _Category(
    label: 'Equipment & Load',
    icon: Icons.build,
    tint: HubTint.blue,
    keywords: [
      'tyre', 'tire', 'light', 'brake', 'seat', 'helmet', 'load',
      'plate', 'protruding', 'reflector', 'mirror', 'horn',
    ],
  ),
];

enum _Sort { code, highestFine, mostPoints }

class TrafficCodesListScreen extends StatefulWidget {
  const TrafficCodesListScreen({super.key, this.repository});

  final TrafficCodesRepository? repository;

  @override
  State<TrafficCodesListScreen> createState() => _TrafficCodesListScreenState();
}

class _TrafficCodesListScreenState extends State<TrafficCodesListScreen> {
  late final TrafficCodesRepository _repository =
      widget.repository ?? const InMemoryTrafficCodesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<TrafficCode> _all = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  _Severity? _severity;
  _Category? _category;
  _Sort _sort = _Sort.code;

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
        _error = 'Failed to load traffic codes: $error';
        _loading = false;
      });
    }
  }

  List<TrafficCode> get _visible {
    final lower = _query.toLowerCase();
    final filtered = _all.where((code) {
      if (lower.isNotEmpty) {
        final hit = code.code.toLowerCase().contains(lower) ||
            code.offenceDescription.toLowerCase().contains(lower) ||
            code.legalSection.toLowerCase().contains(lower);
        if (!hit) return false;
      }
      if (_severity != null && _severityOf(code) != _severity) return false;
      if (_category != null && !_category!.matches(code)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _Sort.code:
        filtered.sort((a, b) => a.code.compareTo(b.code));
      case _Sort.highestFine:
        filtered.sort((a, b) => b.fineAmount.compareTo(a.fineAmount));
      case _Sort.mostPoints:
        filtered.sort((a, b) => b.demeritPoints.compareTo(a.demeritPoints));
    }
    return filtered;
  }

  bool get _hasFilters =>
      _query.isNotEmpty || _severity != null || _category != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _severity = null;
      _category = null;
    });
  }

  void _toggleSeverity(_Severity? value) =>
      setState(() => _severity = _severity == value ? null : value);

  void _toggleCategory(_Category value) =>
      setState(() => _category = _category == value ? null : value);

  void _openDetail(TrafficCode entry) {
    Navigator.push(context, sharedAxis(TrafficCodeDetailScreen(entry: entry)));
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
            title: 'Traffic Codes',
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchRow(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            onFilter: _openSortSheet,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HubStatBanner(
            icon: Icons.traffic,
            count: _all.length.toString(),
            label: 'Active Traffic Codes',
            caption: 'Road Traffic Act schedule',
            actionLabel: 'Browse All',
            onAction: _resetFilters,
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Quick Filters'),
        ),
        const SizedBox(height: 10),
        _buildSeverityPills(),
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
            title: _hasFilters ? 'Matching Offences' : 'All Offences',
            actionLabel: _hasFilters ? 'Clear' : null,
            onAction: _hasFilters ? _resetFilters : null,
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${visible.length} of ${_all.length} codes',
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
                'No matching offences',
                style: TextStyle(color: HubStyle.textSecondary),
              ),
            ),
          )
        else
          ...visible.map(
            (code) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _CodeCard(entry: code, onTap: () => _openDetail(code)),
            ),
          ),
      ],
    );
  }

  Widget _buildSeverityPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _severity == null,
        onTap: () => _toggleSeverity(null),
      ),
      for (final severity in _Severity.values)
        HubFilterPill(
          label: severity.label,
          icon: Icons.circle,
          accent: severity.tint.foreground,
          selected: _severity == severity,
          onTap: () => _toggleSeverity(severity),
        ),
    ];
    return HubFilterPillRow(children: pills);
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
              count: '${_all.where(category.matches).length} codes',
              tint: category.tint,
              selected: _category == category,
              onTap: () => _toggleCategory(category),
            ),
        ],
      ),
    );
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
                hintText: 'Search traffic codes...',
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
      (_Sort.code, 'Code (A–Z)', Icons.sort_by_alpha),
      (_Sort.highestFine, 'Highest fine', Icons.payments_outlined),
      (_Sort.mostPoints, 'Most demerit points', Icons.warning_amber_rounded),
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
                'Sort offences',
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

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.entry, required this.onTap});

  final TrafficCode entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severity = _severityOf(entry);
    final tint = severity.tint;
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: tint.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.code,
                    style: TextStyle(
                      color: tint.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.offenceDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _SeverityChip(severity: severity),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              entry.legalSection,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: HubStyle.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${entry.fineAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF2D6CDF),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.demeritPoints == 0
                          ? 'No pts'
                          : '${entry.demeritPoints} pts',
                      style: const TextStyle(
                        color: HubStyle.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final _Severity severity;

  @override
  Widget build(BuildContext context) {
    final tint = severity.tint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.label,
        style: TextStyle(
          color: tint.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';
import '../../widgets/notifications_bell.dart';
import 'add_wanted_person_screen.dart';
import 'wanted_detail_screen.dart';

/// A status-based quick filter for the wanted list.
enum _Status { wanted, mostWanted, captured }

extension on _Status {
  String get label => switch (this) {
        _Status.wanted => 'Wanted',
        _Status.mostWanted => 'Most Wanted',
        _Status.captured => 'Captured',
      };

  IconData get icon => switch (this) {
        _Status.wanted => Icons.gavel,
        _Status.mostWanted => Icons.payments_outlined,
        _Status.captured => Icons.verified_outlined,
      };

  HubTint get tint => switch (this) {
        _Status.wanted => HubTint.red,
        _Status.mostWanted => HubTint.orange,
        _Status.captured => HubTint.green,
      };

  bool matches(WantedPerson person) => switch (this) {
        _Status.wanted => !person.isCaptured,
        _Status.mostWanted => (person.rewardAmount ?? 0) > 0,
        _Status.captured => person.isCaptured,
      };
}

/// An offence-type grouping derived from keywords in the crime description.
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

  bool matches(WantedPerson person) {
    final crime = person.crimeDescription;
    if (crime == null) return false;
    final text = crime.toLowerCase();
    return keywords.any(text.contains);
  }
}

const List<_Category> _categories = [
  _Category(
    label: 'Violent Crime',
    icon: Icons.dangerous_outlined,
    tint: HubTint.red,
    keywords: ['murder', 'assault', 'wounding', 'shoot', 'kill'],
  ),
  _Category(
    label: 'Robbery & Theft',
    icon: Icons.local_atm_outlined,
    tint: HubTint.orange,
    keywords: ['robbery', 'larceny', 'theft', 'burglar', 'steal'],
  ),
  _Category(
    label: 'Fraud & Deception',
    icon: Icons.credit_card_off_outlined,
    tint: HubTint.purple,
    keywords: ['fraud', 'defraud', 'forgery', 'conspiracy', 'embezzle'],
  ),
  _Category(
    label: 'Firearms',
    icon: Icons.security_outlined,
    tint: HubTint.blue,
    keywords: ['firearm', 'gun', 'ammunition', 'weapon'],
  ),
];

enum _Sort { caseId, highestReward, nameAtoZ }

class WantedListScreen extends StatefulWidget {
  const WantedListScreen({super.key, this.repository});

  final WantedPersonsRepository? repository;

  @override
  State<WantedListScreen> createState() => _WantedListScreenState();
}

class _WantedListScreenState extends State<WantedListScreen> {
  late final WantedPersonsRepository _repository =
      widget.repository ?? const InMemoryWantedPersonsRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<WantedPerson> _all = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  _Status? _status;
  _Category? _category;
  _Sort _sort = _Sort.caseId;

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
        _error = 'Failed to load wanted persons: $error';
        _loading = false;
      });
    }
  }

  int get _activeCount => _all.where((person) => !person.isCaptured).length;

  /// The newest records first, as inserted by the repository.
  List<WantedPerson> get _recentlyAdded => _all.take(5).toList();

  List<WantedPerson> get _visible {
    final lower = _query.toLowerCase();
    final filtered = _all.where((person) {
      if (lower.isNotEmpty && !_matchesQuery(person, lower)) return false;
      if (_status != null && !_status!.matches(person)) return false;
      if (_category != null && !_category!.matches(person)) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _Sort.caseId:
        filtered.sort((a, b) => a.id.compareTo(b.id));
      case _Sort.highestReward:
        filtered.sort(
            (a, b) => (b.rewardAmount ?? 0).compareTo(a.rewardAmount ?? 0));
      case _Sort.nameAtoZ:
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    return filtered;
  }

  bool _matchesQuery(WantedPerson person, String lower) {
    if (person.fullName.toLowerCase().contains(lower)) return true;
    final alias = person.alias;
    if (alias != null && alias.toLowerCase().contains(lower)) return true;
    final crime = person.crimeDescription;
    if (crime != null && crime.toLowerCase().contains(lower)) return true;
    return false;
  }

  bool get _hasFilters =>
      _query.isNotEmpty || _status != null || _category != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _status = null;
      _category = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleStatus(_Status? value) =>
      setState(() => _status = _status == value ? null : value);

  void _toggleCategory(_Category value) =>
      setState(() => _category = _category == value ? null : value);

  Future<void> _openDetail(WantedPerson person) async {
    await Navigator.push(
      context,
      sharedAxis(WantedDetailScreen(person: person, repository: _repository)),
    );
    await _loadRecords();
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<bool>(
      context,
      sharedAxis(AddWantedPersonScreen(repository: _repository)),
    );
    if (created == true) await _loadRecords();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: HubStyle.navBackground,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Wanted Persons',
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
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 96),
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
              icon: Icons.person_search,
              count: _activeCount.toString(),
              label: 'Active Wanted',
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
          _buildStatusPills(),
          if (_recentlyAdded.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: HubSectionHeading(title: 'Recently Added'),
            ),
            const SizedBox(height: 10),
            _buildRecentlyAdded(),
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
              title: _hasFilters ? 'Matching Records' : 'All Records',
              actionLabel: _hasFilters ? 'Clear' : null,
              onAction: _hasFilters ? _resetFilters : null,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${visible.length} of ${_all.length} records',
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
                  'No matching records',
                  style: TextStyle(color: HubStyle.textSecondary),
                ),
              ),
            )
          else
            ...visible.map(
              (person) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _WantedCard(
                  person: person,
                  onTap: () => _openDetail(person),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TipBanner(onSubmit: _openAdd),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _status == null,
        onTap: () => _toggleStatus(null),
      ),
      for (final status in _Status.values)
        HubFilterPill(
          label: status.label,
          icon: status.icon,
          accent: status.tint.foreground,
          selected: _status == status,
          onTap: () => _toggleStatus(status),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  Widget _buildRecentlyAdded() {
    final recent = _recentlyAdded;
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _RecentCard(
          person: recent[index],
          isNewest: index == 0,
          onTap: () => _openDetail(recent[index]),
        ),
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
              count: '${_all.where(category.matches).length} records',
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
                hintText: 'Search wanted persons...',
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
      (_Sort.caseId, 'Case number', Icons.tag),
      (_Sort.highestReward, 'Highest reward', Icons.payments_outlined),
      (_Sort.nameAtoZ, 'Name (A–Z)', Icons.sort_by_alpha),
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
                'Sort records',
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

/// Square mugshot used in list and recent cards. Prefers a locally captured
/// photo, then a remote photo, falling back to the subject's initials.
class _PersonPhoto extends StatelessWidget {
  const _PersonPhoto({
    required this.person,
    this.size = 84,
  });

  final WantedPerson person;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: size, height: size, child: _image()),
    );
  }

  Widget _image() {
    final bytes = person.photoBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
    }
    final url = person.photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback(),
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: HubStyle.navBackground,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String get _initials {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}

/// The status/severity chip shown on each list card.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final captured = person.isCaptured;
    final mostWanted = !captured && (person.rewardAmount ?? 0) > 0;
    final tint = captured
        ? HubTint.green
        : mostWanted
            ? HubTint.orange
            : HubTint.red;
    final label = captured
        ? 'Captured'
        : mostWanted
            ? 'Most Wanted'
            : 'Wanted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint.foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WantedCard extends StatelessWidget {
  const _WantedCard({required this.person, required this.onTap});

  final WantedPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                Hero(
                  tag: 'wanted:${person.id}',
                  child: _PersonPhoto(person: person, size: 72),
                ),
                const SizedBox(width: 12),
                Expanded(child: _details()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _details() {
    final crime = person.crimeDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                person.id,
                style: const TextStyle(
                  color: HubStyle.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            _StatusChip(person: person),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          person.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: HubStyle.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (crime != null && crime.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            crime,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: HubStyle.textSecondary,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (person.age != null)
              _FactPill(icon: Icons.cake_outlined, label: 'Age ${person.age}'),
            if (person.rewardAmount != null) ...[
              if (person.age != null) const SizedBox(width: 8),
              _FactPill(
                icon: Icons.payments_outlined,
                label: 'Reward \$${_formatAmount(person.rewardAmount!)}',
                tint: HubTint.orange,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A small tinted fact pill (age, reward) on the list card.
class _FactPill extends StatelessWidget {
  const _FactPill({
    required this.icon,
    required this.label,
    this.tint = HubTint.blue,
  });

  final IconData icon;
  final String label;
  final HubTint tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tint.foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  final WantedPerson person;
  final bool isNewest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _PersonPhoto(person: person, size: 130),
                      if (isNewest)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: HubTint.red.foreground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    person.fullName,
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
                    _keyFact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 11.5,
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

  String get _keyFact {
    if (person.age != null) return 'Age ${person.age} · ${person.id}';
    return person.id;
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.onSubmit});

  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                color: HubTint.orange.foreground,
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Help officers file a new wanted record.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: HubStyle.navBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Submit a Tip'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(double amount) {
  final whole = amount.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return buffer.toString();
}

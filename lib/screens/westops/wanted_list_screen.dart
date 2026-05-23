import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../theme/duty_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/mugshot_placeholder.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import 'wanted_detail_screen.dart';

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

  List<WantedPerson> _all = [];
  List<WantedPerson> _visible = [];
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
        _error = 'Failed to load wanted persons: $error';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _filtered(query);
    });
  }

  List<WantedPerson> _filtered(String query) {
    if (query.isEmpty) return _all;
    final lower = query.toLowerCase();
    return _all.where((person) {
      if (person.fullName.toLowerCase().contains(lower)) return true;
      final alias = person.alias;
      if (alias != null && alias.toLowerCase().contains(lower)) return true;
      final crime = person.crimeDescription;
      if (crime != null && crime.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _openDetail(WantedPerson person) {
    Navigator.push(
      context,
      sharedAxis(WantedDetailScreen(person: person)),
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Wanted Persons'),
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
      const BreadcrumbSegment(label: 'Wanted'),
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
            child: _WantedList(persons: _visible, onOpen: _openDetail),
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
          hintText: 'Search by name, alias or offence',
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
            '${count.toString().padLeft(3, '0')}  WANTED',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _WantedList extends StatelessWidget {
  const _WantedList({required this.persons, required this.onOpen});

  final List<WantedPerson> persons;
  final void Function(WantedPerson) onOpen;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No wanted persons found')),
        ],
      );
    }
    final colors = Theme.of(context).extension<DutyColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: persons.length,
      separatorBuilder: (_, i) => Container(height: 1, color: colors.hairline),
      itemBuilder: (context, index) => _WantedRow(
        person: persons[index],
        onTap: () => onOpen(persons[index]),
      ),
    );
  }
}

class _WantedRow extends StatelessWidget {
  const _WantedRow({required this.person, required this.onTap});

  final WantedPerson person;
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
            _Mugshot(person: person),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CaseChip(caseId: person.id),
                  const SizedBox(height: 8),
                  Text(
                    person.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.15,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (person.alias != null && person.alias!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'a.k.a. "${person.alias}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (person.crimeDescription != null &&
                      person.crimeDescription!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      person.crimeDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'WANTED  ·  ${person.status ?? "ACTIVE"}'.toUpperCase(),
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
}

class _CaseChip extends StatelessWidget {
  const _CaseChip({required this.caseId});
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.secondary, width: 1),
      ),
      child: Text(
        'CASE / $caseId',
        style: DutyTheme.mono(
          size: 10,
          weight: FontWeight.w700,
          color: scheme.secondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Mugshot extends StatelessWidget {
  const _Mugshot({required this.person});
  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final hairline = Theme.of(context).extension<DutyColors>()!.hairline;
    final initials = _initialsFor(person);
    final url = person.photoUrl;
    final placeholder = MugshotPlaceholder(initials: initials);
    final image = (url == null || url.isEmpty)
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, errorUrl, error) => placeholder,
          );
    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(border: Border.all(color: hairline)),
      child: Hero(
        tag: 'wanted:${person.id}',
        child: ClipRect(child: image),
      ),
    );
  }

  String _initialsFor(WantedPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

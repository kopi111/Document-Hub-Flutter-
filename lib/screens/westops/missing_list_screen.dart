import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/duty_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/mugshot_placeholder.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import 'missing_detail_screen.dart';

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
  List<MissingPerson> _visible = [];
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
        _error = 'Failed to load missing persons: $error';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _filtered(query);
    });
  }

  List<MissingPerson> _filtered(String query) {
    if (query.isEmpty) return _all;
    final lower = query.toLowerCase();
    return _all.where((person) {
      if (person.fullName.toLowerCase().contains(lower)) return true;
      final location = person.lastSeenLocation;
      if (location != null && location.toLowerCase().contains(lower)) {
        return true;
      }
      return false;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _openDetail(MissingPerson person) async {
    await Navigator.push(
      context,
      sharedAxis(MissingDetailScreen(person: person)),
    );
    await _loadRecords();
    _onSearchChanged(_searchController.text);
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
        title: const Text('Missing Persons'),
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
      const BreadcrumbSegment(label: 'Missing'),
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
            child: _MissingList(persons: _visible, onOpen: _openDetail),
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
          hintText: 'Search by name or last-seen location',
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
          Container(width: 18, height: 1, color: colors.missingTeal),
          const SizedBox(width: 10),
          Text(
            '${count.toString().padLeft(3, '0')}  MISSING',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _MissingList extends StatelessWidget {
  const _MissingList({required this.persons, required this.onOpen});

  final List<MissingPerson> persons;
  final void Function(MissingPerson) onOpen;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No missing persons found')),
        ],
      );
    }
    final colors = Theme.of(context).extension<DutyColors>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: persons.length,
      separatorBuilder: (_, i) => Container(height: 1, color: colors.hairline),
      itemBuilder: (context, index) => _MissingRow(
        person: persons[index],
        onTap: () => onOpen(persons[index]),
      ),
    );
  }
}

class _MissingRow extends StatelessWidget {
  const _MissingRow({required this.person, required this.onTap});

  final MissingPerson person;
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
            _Portrait(person: person),
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
                  if (person.lastSeenLocation != null &&
                      person.lastSeenLocation!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      person.lastSeenLocation!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'REPORTED  ·  ${_formatDate(person.reportedDate)}',
                    style: DutyTheme.mono(
                      size: 10,
                      color: colors.mutedGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (person.isFound) ...[
                    const SizedBox(height: 8),
                    const _FoundChip(),
                  ],
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

class _FoundChip extends StatelessWidget {
  const _FoundChip();

  @override
  Widget build(BuildContext context) {
    const found = Color(0xFF1B7A3D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: found.withValues(alpha: 0.12),
        border: Border.all(color: found, width: 1),
      ),
      child: Text(
        'FOUND',
        style: DutyTheme.mono(
          size: 10,
          weight: FontWeight.w700,
          color: found,
          letterSpacing: 1.2,
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
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: colors.missingTeal, width: 1),
      ),
      child: Text(
        'CASE / $caseId',
        style: DutyTheme.mono(
          size: 10,
          weight: FontWeight.w700,
          color: colors.missingTeal,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.person});
  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final initials = _initialsFor(person);
    final url = person.photoUrl;
    final placeholder =
        MugshotPlaceholder(initials: initials, tint: colors.missingTeal);
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
      decoration: BoxDecoration(border: Border.all(color: colors.hairline)),
      child: Hero(
        tag: 'missing:${person.id}',
        child: ClipRect(child: image),
      ),
    );
  }

  String _initialsFor(MissingPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/westops/nam_person_widgets.dart';
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
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Missing Persons'),
          bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
        ),
        body: _buildBody(),
      ),
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
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: NamStyle.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: NamStyle.body(color: NamStyle.textPrimary)),
      );
    }
    return Column(
      children: [
        NamSearchField(
          controller: _searchController,
          hint: 'Search by name or last-seen location',
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        NamResultCount(count: _visible.length, label: 'MISSING'),
        Expanded(
          child: RefreshIndicator(
            color: NamStyle.gold,
            backgroundColor: NamStyle.surface,
            onRefresh: _loadRecords,
            child: _MissingList(persons: _visible, onOpen: _openDetail),
          ),
        ),
      ],
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
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'No missing persons found',
              style: NamStyle.body(color: NamStyle.textSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        NamStyle.pageInset,
        4,
        NamStyle.pageInset,
        24,
      ),
      itemCount: persons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _MissingCard(
        person: persons[index],
        onTap: () => onOpen(persons[index]),
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
    return NamPersonCard(
      heroTag: 'missing:${person.id}',
      initials: _initialsFor(person),
      photoUrl: person.photoUrl,
      onTap: onTap,
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NamCaseChip(caseId: person.id),
          const SizedBox(height: 10),
          Text(
            person.fullName,
            style: NamStyle.title(size: 16, weight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (person.lastSeenLocation != null &&
              person.lastSeenLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              person.lastSeenLocation!,
              style: NamStyle.body(size: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'REPORTED · ${_formatDate(person.reportedDate)}',
                style: NamStyle.mono(size: 10, letterSpacing: 1.2),
              ),
              if (person.isFound) ...[
                const SizedBox(width: 10),
                const NamStatusChip(
                  label: 'Found',
                  color: NamStyle.found,
                  icon: Icons.check_circle,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _initialsFor(MissingPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

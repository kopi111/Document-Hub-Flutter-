import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/westops/nam_person_widgets.dart';
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
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Wanted Persons'),
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
      const BreadcrumbSegment(label: 'Wanted'),
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
          hint: 'Search by name, alias or offence',
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        NamResultCount(count: _visible.length, label: 'WANTED'),
        Expanded(
          child: RefreshIndicator(
            color: NamStyle.gold,
            backgroundColor: NamStyle.surface,
            onRefresh: _loadRecords,
            child: _WantedList(persons: _visible, onOpen: _openDetail),
          ),
        ),
      ],
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
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'No wanted persons found',
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
      itemBuilder: (context, index) => _WantedCard(
        person: persons[index],
        onTap: () => onOpen(persons[index]),
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
    return NamPersonCard(
      heroTag: 'wanted:${person.id}',
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
          if (person.alias != null && person.alias!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'a.k.a. "${person.alias}"',
              style: NamStyle.body(size: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (person.crimeDescription != null &&
              person.crimeDescription!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              person.crimeDescription!,
              style: NamStyle.body(size: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'WANTED · ${(person.status ?? 'ACTIVE').toUpperCase()}',
            style: NamStyle.mono(size: 10, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }

  String _initialsFor(WantedPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

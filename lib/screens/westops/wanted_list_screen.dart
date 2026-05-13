import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../widgets/breadcrumb_trail.dart';
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
      MaterialPageRoute(builder: (_) => WantedDetailScreen(person: person)),
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
        title: const Text('Wanted Persons'),
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
      const BreadcrumbSegment(label: 'Wanted Persons'),
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
          hintText: 'Search by name, alias or offence...',
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
          '${_visible.length} wanted persons',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_visible.isEmpty) {
      return const Center(child: Text('No wanted persons found'));
    }
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) => _WantedTile(
        person: _visible[index],
        onOpen: _openDetail,
      ),
    );
  }
}

class _WantedTile extends StatelessWidget {
  const _WantedTile({required this.person, required this.onOpen});

  final WantedPerson person;
  final void Function(WantedPerson) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: const Icon(Icons.person, color: Colors.red),
      ),
      title: Text(
        person.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        person.crimeDescription ?? 'No offence on record',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onOpen(person),
    );
  }
}

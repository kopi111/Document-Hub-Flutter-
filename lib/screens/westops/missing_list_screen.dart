import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/breadcrumb_trail.dart';
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

  void _openDetail(MissingPerson person) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MissingDetailScreen(person: person)),
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Missing Persons'),
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
      const BreadcrumbSegment(label: 'Missing Persons'),
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
          hintText: 'Search by name or last-seen location...',
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
          '${_visible.length} missing persons',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_visible.isEmpty) {
      return const Center(child: Text('No missing persons found'));
    }
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) => _MissingTile(
        person: _visible[index],
        onOpen: _openDetail,
      ),
    );
  }
}

class _MissingTile extends StatelessWidget {
  const _MissingTile({required this.person, required this.onOpen});

  final MissingPerson person;
  final void Function(MissingPerson) onOpen;

  @override
  Widget build(BuildContext context) {
    final reported = _formatDate(person.reportedDate);
    final location = person.lastSeenLocation ?? 'Location unknown';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.amber.shade100,
        child: const Icon(Icons.person_search, color: Colors.orange),
      ),
      title: Text(
        person.fullName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Reported $reported — $location',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onOpen(person),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

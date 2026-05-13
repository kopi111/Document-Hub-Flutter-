import 'package:flutter/material.dart';

import '../../models/westops/traffic_code.dart';
import '../../services/westops/traffic_codes_repository.dart';
import '../../widgets/breadcrumb_trail.dart';
import 'traffic_code_detail_screen.dart';

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
  List<TrafficCode> _visible = [];
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
        _error = 'Failed to load traffic codes: $error';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _filtered(query);
    });
  }

  List<TrafficCode> _filtered(String query) {
    if (query.isEmpty) return _all;
    final lower = query.toLowerCase();
    return _all.where((entry) {
      if (entry.code.toLowerCase().contains(lower)) return true;
      if (entry.offenceDescription.toLowerCase().contains(lower)) return true;
      if (entry.legalSection.toLowerCase().contains(lower)) return true;
      return false;
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _openDetail(TrafficCode entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrafficCodeDetailScreen(entry: entry)),
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
        title: const Text('Traffic Codes'),
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
      const BreadcrumbSegment(label: 'Traffic Codes'),
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
          hintText: 'Search by code, offence or section...',
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
          '${_visible.length} offences',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_visible.isEmpty) {
      return const Center(child: Text('No matching offences'));
    }
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) => _TrafficCodeTile(
        entry: _visible[index],
        onOpen: _openDetail,
      ),
    );
  }
}

class _TrafficCodeTile extends StatelessWidget {
  const _TrafficCodeTile({required this.entry, required this.onOpen});

  final TrafficCode entry;
  final void Function(TrafficCode) onOpen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Text(
          entry.code,
          style: const TextStyle(
            color: Colors.teal,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        entry.offenceDescription,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(entry.legalSection),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => onOpen(entry),
    );
  }
}

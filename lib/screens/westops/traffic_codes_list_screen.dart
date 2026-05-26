import 'package:flutter/material.dart';

import '../../models/westops/traffic_code.dart';
import '../../services/westops/traffic_codes_repository.dart';
import '../../theme/duty_theme.dart';
import '../../theme/jcf_palette.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/shared_axis_route.dart';
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
      sharedAxis(TrafficCodeDetailScreen(entry: entry)),
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
      appBar: AppBar(
        title: const Text('Traffic Codes'),
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
        _SearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        _ResultsHeader(count: _visible.length),
        const _TableHeader(),
        Expanded(child: _CodesList(codes: _visible, onOpen: _openDetail)),
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
          hintText: 'Search by code, offence or section',
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
            '${count.toString().padLeft(3, '0')}  OFFENCES',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.hairline),
          bottom: BorderSide(color: colors.hairline),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              'CODE',
              style: DutyTheme.mono(
                size: 10,
                color: colors.mutedGold,
                letterSpacing: 1.4,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'OFFENCE',
              style: DutyTheme.mono(
                size: 10,
                color: colors.mutedGold,
                letterSpacing: 1.4,
                weight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'FINE  PTS',
            style: DutyTheme.mono(
              size: 10,
              color: colors.mutedGold,
              letterSpacing: 1.4,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodesList extends StatelessWidget {
  const _CodesList({required this.codes, required this.onOpen});

  final List<TrafficCode> codes;
  final void Function(TrafficCode) onOpen;

  @override
  Widget build(BuildContext context) {
    if (codes.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No matching offences')),
        ],
      );
    }
    final colors = Theme.of(context).extension<DutyColors>()!;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: codes.length,
      separatorBuilder: (_, _) => Container(height: 1, color: colors.hairline),
      itemBuilder: (context, index) {
        return _CodeRow(entry: codes[index], onTap: () => onOpen(codes[index]));
      },
    );
  }
}

class _CodeRow extends StatelessWidget {
  const _CodeRow({required this.entry, required this.onTap});

  final TrafficCode entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                entry.code,
                style: DutyTheme.mono(
                  size: 14,
                  weight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.offenceDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.legalSection,
                    style: DutyTheme.mono(
                      size: 11,
                      color: colors.mutedGold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${entry.fineAmount.toStringAsFixed(0)}',
                  style: DutyTheme.mono(
                    size: 14,
                    weight: FontWeight.w700,
                    color: JcfPalette.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.demeritPoints} PTS',
                  style: DutyTheme.mono(
                    size: 10,
                    color: entry.demeritPoints == 0 ? JcfPalette.success : colors.mutedGold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

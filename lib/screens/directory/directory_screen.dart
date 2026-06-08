import 'package:flutter/material.dart';

import '../../models/directory/police_formation.dart';
import '../../services/directory/police_formations_repository.dart';
import '../../services/phone_dialer.dart';
import '../../theme/nam_style.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/westops/nam_person_widgets.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, this.repository});

  final PoliceFormationsRepository? repository;

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  late final PoliceFormationsRepository _repository =
      widget.repository ?? InMemoryPoliceFormationsRepository();

  final TextEditingController _searchController = TextEditingController();

  List<PoliceFormation> _all = [];
  List<PoliceFormation> _visible = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormations() async {
    try {
      final formations = await _repository.listAll();
      if (!mounted) return;
      setState(() {
        _all = _sorted(formations);
        _visible = _filtered(_searchController.text);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load directory: $error';
        _loading = false;
      });
    }
  }

  List<PoliceFormation> _sorted(List<PoliceFormation> formations) {
    const typeOrder = {
      PoliceFormation.typeEmergency: 0,
      PoliceFormation.typeDivisionHq: 1,
      PoliceFormation.typeStation: 2,
      PoliceFormation.typeSpecialisedUnit: 3,
    };
    final copy = List<PoliceFormation>.from(formations);
    copy.sort((a, b) {
      final typeCompare =
          (typeOrder[a.type] ?? 9).compareTo(typeOrder[b.type] ?? 9);
      if (typeCompare != 0) return typeCompare;
      return a.name.compareTo(b.name);
    });
    return copy;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _filtered(query);
    });
  }

  List<PoliceFormation> _filtered(String query) {
    if (query.isEmpty) return _all;
    final lower = query.toLowerCase();
    return _all.where((formation) {
      return formation.name.toLowerCase().contains(lower) ||
          formation.parish.toLowerCase().contains(lower) ||
          formation.type.toLowerCase().contains(lower);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _dial(String number) async {
    try {
      await dialNumber(number);
    } on DialFailure {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not call $number'),
          backgroundColor: NamStyle.surface,
        ),
      );
    }
  }

  Future<void> _addNumber(PoliceFormation formation) async {
    final number = await _promptForNumber(formation.name);
    if (number == null || number.trim().isEmpty) return;
    await _repository.addNumber(formation.id, number);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Number added to ${formation.name}'),
        backgroundColor: NamStyle.surface,
      ),
    );
  }

  Future<void> _deleteNumber(PoliceFormation formation, String number) async {
    final confirmed = await _confirmRemoval(number);
    if (!confirmed) return;
    await _repository.removeNumber(formation.id, number);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Number removed'),
        backgroundColor: NamStyle.surface,
      ),
    );
  }

  Future<String?> _promptForNumber(String formationName) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NamStyle.surface,
        title: Text(
          'Add number',
          style: NamStyle.title(size: 18, weight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          style: NamStyle.body(size: 15, color: NamStyle.textPrimary),
          cursorColor: NamStyle.gold,
          decoration: InputDecoration(
            hintText: 'e.g. 876-555-0123',
            hintStyle: NamStyle.body(size: 14, color: NamStyle.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: NamStyle.body(size: 14, color: NamStyle.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: NamStyle.gold,
              foregroundColor: NamStyle.onGold,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<bool> _confirmRemoval(String number) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NamStyle.surface,
        title: Text(
          'Remove number',
          style: NamStyle.title(size: 18, weight: FontWeight.w700),
        ),
        content: Text(
          'Remove $number from this formation?',
          style: NamStyle.body(size: 14, color: NamStyle.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: NamStyle.body(size: 14, color: NamStyle.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: NamStyle.alert,
              foregroundColor: NamStyle.textPrimary,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const Text('Directory'),
        ),
        body: _buildBody(),
      ),
    );
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
          hint: 'Search by name, parish or type',
          onChanged: _onSearchChanged,
          onClear: _clearSearch,
        ),
        Expanded(
          child: _FormationList(
            formations: _visible,
            onCall: _dial,
            onAddNumber: _addNumber,
            onDeleteNumber: _deleteNumber,
          ),
        ),
      ],
    );
  }
}

class _FormationList extends StatelessWidget {
  const _FormationList({
    required this.formations,
    required this.onCall,
    required this.onAddNumber,
    required this.onDeleteNumber,
  });

  final List<PoliceFormation> formations;
  final Future<void> Function(String number) onCall;
  final Future<void> Function(PoliceFormation formation) onAddNumber;
  final Future<void> Function(PoliceFormation formation, String number)
      onDeleteNumber;

  @override
  Widget build(BuildContext context) {
    if (formations.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              'No formations found',
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
      itemCount: formations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _FormationCard(
        formation: formations[index],
        onCall: onCall,
        onAddNumber: onAddNumber,
        onDeleteNumber: onDeleteNumber,
      ),
    );
  }
}

class _FormationCard extends StatelessWidget {
  const _FormationCard({
    required this.formation,
    required this.onCall,
    required this.onAddNumber,
    required this.onDeleteNumber,
  });

  final PoliceFormation formation;
  final Future<void> Function(String number) onCall;
  final Future<void> Function(PoliceFormation formation) onAddNumber;
  final Future<void> Function(PoliceFormation formation, String number)
      onDeleteNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NamStyle.surface,
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        border: Border.all(color: _borderColorFor(formation.type)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _TypeIndicator(type: formation.type),
                const SizedBox(width: 14),
                Expanded(child: _FormationDetails(formation: formation)),
              ],
            ),
            const SizedBox(height: 12),
            for (final number in formation.phones)
              _NumberRow(
                number: number,
                onCall: () => onCall(number),
                onDelete: () => onDeleteNumber(formation, number),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onAddNumber(formation),
                icon: const Icon(Icons.add, size: 18),
                style: TextButton.styleFrom(foregroundColor: NamStyle.gold),
                label: Text(
                  'Add number',
                  style: NamStyle.body(size: 13, color: NamStyle.gold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _borderColorFor(String type) {
    if (type == PoliceFormation.typeEmergency) {
      return NamStyle.gold.withValues(alpha: 0.6);
    }
    return NamStyle.hairline;
  }
}

class _TypeIndicator extends StatelessWidget {
  const _TypeIndicator({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: _accentFor(type),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _accentFor(String type) {
    switch (type) {
      case PoliceFormation.typeEmergency:
        return NamStyle.gold;
      case PoliceFormation.typeDivisionHq:
        return NamStyle.textPrimary;
      case PoliceFormation.typeSpecialisedUnit:
        return NamStyle.textSecondary;
      default:
        return NamStyle.hairline;
    }
  }
}

class _FormationDetails extends StatelessWidget {
  const _FormationDetails({required this.formation});

  final PoliceFormation formation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formation.name,
          style: NamStyle.title(size: 15, weight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${formation.parish}  ·  ${formation.type.toUpperCase()}',
          style: NamStyle.mono(
            size: 10,
            color: NamStyle.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

/// One phone number: a gold call pill that fills the row and a trailing delete
/// control.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.number,
    required this.onCall,
    required this.onDelete,
  });

  final String number;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onCall,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: NamStyle.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(NamStyle.cardRadius),
                  border: Border.all(color: NamStyle.gold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 15, color: NamStyle.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        number,
                        style: NamStyle.mono(size: 12, color: NamStyle.gold),
                      ),
                    ),
                    Text(
                      'CALL',
                      style: NamStyle.mono(
                        size: 9,
                        color: NamStyle.gold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove number',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: NamStyle.textSecondary,
          ),
        ],
      ),
    );
  }
}

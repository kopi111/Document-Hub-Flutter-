import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/westops/nam_person_widgets.dart';
import 'mark_found_screen.dart';

class MissingDetailScreen extends StatefulWidget {
  const MissingDetailScreen({
    super.key,
    required this.person,
    this.repository,
  });

  final MissingPerson person;
  final MissingPersonsRepository? repository;

  @override
  State<MissingDetailScreen> createState() => _MissingDetailScreenState();
}

class _MissingDetailScreenState extends State<MissingDetailScreen> {
  late final MissingPersonsRepository _repository =
      widget.repository ?? const InMemoryMissingPersonsRepository();
  late MissingPerson _person = widget.person;

  Future<void> _markFound() async {
    final result = await Navigator.push<MarkFoundResult>(
      context,
      MaterialPageRoute(builder: (_) => MarkFoundScreen(person: _person)),
    );
    if (result == null) return;
    final updated = await _repository.markFound(
      id: _person.id,
      foundDate: result.foundDate,
      foundLocation: result.foundLocation,
      foundBy: result.foundBy,
      foundNotes: result.foundNotes,
    );
    if (!mounted) return;
    setState(() => _person = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_person.fullName} marked as found')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(person.fullName),
          bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
        ),
        floatingActionButton: person.isFound
            ? null
            : FloatingActionButton.extended(
                onPressed: _markFound,
                backgroundColor: NamStyle.gold,
                foregroundColor: NamStyle.onGold,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  'Mark as Found',
                  style: NamStyle.title(
                    size: 14,
                    weight: FontWeight.w700,
                    color: NamStyle.onGold,
                  ),
                ),
              ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            NamHeroPortrait(
              heroTag: 'missing:${person.id}',
              initials: _initialsFor(person),
              photoUrl: person.photoUrl,
              overlay: _Identity(person: person),
            ),
            const SizedBox(height: 16),
            NamDetailCard(rows: _rows(person)),
          ],
        ),
      ),
    );
  }

  List<NamDetailRow> _rows(MissingPerson person) {
    final entries = <String, String?>{
      'Gender': person.gender,
      'Date of birth': _formatDate(person.dateOfBirth),
      'Reported': _formatDate(person.reportedDate),
      'Last seen': person.lastSeenLocation,
      'Description': person.description,
      'Contact person': person.contactPerson,
      'Contact phone': person.contactPhoneNumber,
      'Investigating officer': person.investigatingOfficer,
      'Supervisor': person.investigatingOfficerSupervisor,
      'Station': person.stationName,
      'Station number': person.stationNumber,
      'Station phone': person.stationContactNumber,
      'Status': person.status,
      'Reference ID': person.id,
      if (person.isFound) ...{
        'Found on': _formatDate(person.foundDate),
        'Found location': person.foundLocation,
        'Recovered by': person.foundBy,
        'Found notes': person.foundNotes,
      },
    };
    return [
      for (final entry in entries.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          NamDetailRow(label: entry.key, value: entry.value!),
    ];
  }

  List<BreadcrumbSegment> _breadcrumbSegments(BuildContext context) {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'Missing'),
      BreadcrumbSegment(label: _person.fullName),
    ];
  }

  String _initialsFor(MissingPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.person});

  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NamCaseChip(caseId: person.id),
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
        const SizedBox(height: 12),
        Text(
          person.fullName,
          style: NamStyle.title(size: 26, weight: FontWeight.w700, height: 1.05),
        ),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/duty_theme.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/mugshot_placeholder.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(person.fullName),
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      floatingActionButton: person.isFound
          ? null
          : FloatingActionButton.extended(
              onPressed: _markFound,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as Found'),
            ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PortraitHeader(person: person),
          _IdentitySlab(person: person),
          _DetailRow(label: 'Gender', value: person.gender),
          _DetailRow(label: 'Date of birth', value: _formatDate(person.dateOfBirth)),
          _DetailRow(label: 'Reported', value: _formatDate(person.reportedDate)),
          _DetailRow(label: 'Last seen', value: person.lastSeenLocation),
          _DetailRow(label: 'Description', value: person.description),
          _DetailRow(label: 'Contact person', value: person.contactPerson),
          _DetailRow(label: 'Contact phone', value: person.contactPhoneNumber),
          _DetailRow(label: 'Investigating officer', value: person.investigatingOfficer),
          _DetailRow(label: 'Supervisor', value: person.investigatingOfficerSupervisor),
          _DetailRow(label: 'Station', value: person.stationName),
          _DetailRow(label: 'Station number', value: person.stationNumber),
          _DetailRow(label: 'Station phone', value: person.stationContactNumber),
          _DetailRow(label: 'Status', value: person.status),
          _DetailRow(label: 'Reference ID', value: person.id),
          if (person.isFound) ...[
            _DetailRow(label: 'Found on', value: _formatDate(person.foundDate)),
            _DetailRow(label: 'Found location', value: person.foundLocation),
            _DetailRow(label: 'Recovered by', value: person.foundBy),
            _DetailRow(label: 'Found notes', value: person.foundNotes),
          ],
          const SizedBox(height: 88),
        ],
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
      const BreadcrumbSegment(label: 'Missing'),
      BreadcrumbSegment(label: _person.fullName),
    ];
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _PortraitHeader extends StatelessWidget {
  const _PortraitHeader({required this.person});
  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final initials = _initialsFor(person);
    final url = person.photoUrl;
    final body = (url == null || url.isEmpty)
        ? MugshotPlaceholder(initials: initials, tint: colors.missingTeal)
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, url, error) => MugshotPlaceholder(
              initials: initials,
              tint: colors.missingTeal,
            ),
          );
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Hero(
        tag: 'missing:${person.id}',
        child: ClipRect(child: body),
      ),
    );
  }

  String _initialsFor(MissingPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

class _IdentitySlab extends StatelessWidget {
  const _IdentitySlab({required this.person});
  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CASE / ${person.id}',
            style: DutyTheme.mono(
              size: 11,
              color: colors.missingTeal,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurface,
                  height: 1.05,
                ),
          ),
          if (person.isFound) ...[
            const SizedBox(height: 10),
            const _FoundBadge(),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: colors.hairline),
        ],
      ),
    );
  }
}

class _FoundBadge extends StatelessWidget {
  const _FoundBadge();

  @override
  Widget build(BuildContext context) {
    const found = Color(0xFF1B7A3D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: found.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: found),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: found),
          const SizedBox(width: 6),
          Text(
            'FOUND',
            style: DutyTheme.mono(
              size: 11,
              weight: FontWeight.w700,
              color: found,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DutyTheme.mono(
              size: 10,
              color: colors.mutedGold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.hairline),
        ],
      ),
    );
  }
}

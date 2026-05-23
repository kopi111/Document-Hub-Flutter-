import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../theme/duty_theme.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/editorial/mugshot_placeholder.dart';

class WantedDetailScreen extends StatelessWidget {
  const WantedDetailScreen({super.key, required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(person.fullName),
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _PortraitHeader(person: person),
          _IdentitySlab(person: person),
          _DetailRow(label: 'Alias', value: person.alias),
          _DetailRow(label: 'Gender', value: person.gender),
          _DetailRow(label: 'Date of birth', value: _formatDate(person.dateOfBirth)),
          _DetailRow(label: 'Offence', value: person.crimeDescription),
          _DetailRow(label: 'Reward (JMD)', value: _formatReward(person.rewardAmount)),
          _DetailRow(label: 'Contact phone', value: person.contactPhoneNumber),
          _DetailRow(label: 'Investigating officer', value: person.investigatingOfficer),
          _DetailRow(label: 'Supervisor', value: person.investigatingOfficerSupervisor),
          _DetailRow(label: 'Station', value: person.stationName),
          _DetailRow(label: 'Station number', value: person.stationNumber),
          _DetailRow(label: 'Station phone', value: person.stationContactNumber),
          _DetailRow(label: 'Status', value: person.status),
          _DetailRow(label: 'Reference ID', value: person.id),
          const SizedBox(height: 24),
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
      const BreadcrumbSegment(label: 'Wanted'),
      BreadcrumbSegment(label: person.fullName),
    ];
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String? _formatReward(double? reward) {
    if (reward == null) return null;
    return '\$${reward.toStringAsFixed(0)}';
  }
}

class _PortraitHeader extends StatelessWidget {
  const _PortraitHeader({required this.person});
  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(person);
    final url = person.photoUrl;
    final body = (url == null || url.isEmpty)
        ? MugshotPlaceholder(initials: initials)
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, url, error) =>
                MugshotPlaceholder(initials: initials),
          );
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Hero(
        tag: 'wanted:${person.id}',
        child: ClipRect(child: body),
      ),
    );
  }

  String _initialsFor(WantedPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

class _IdentitySlab extends StatelessWidget {
  const _IdentitySlab({required this.person});
  final WantedPerson person;

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
            'CASE / ${person.id}'.toUpperCase(),
            style: DutyTheme.mono(
              size: 11,
              color: colors.mutedGold,
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
          if (person.alias != null && person.alias!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'a.k.a. "${person.alias}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          Container(height: 1, color: colors.hairline),
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

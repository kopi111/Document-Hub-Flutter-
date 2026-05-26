import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../theme/nam_style.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/westops/nam_person_widgets.dart';

class WantedDetailScreen extends StatelessWidget {
  const WantedDetailScreen({super.key, required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(person.fullName),
          bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            NamHeroPortrait(
              heroTag: 'wanted:${person.id}',
              initials: _initialsFor(person),
              photoUrl: person.photoUrl,
              overlay: _Identity(person: person),
            ),
            if (person.rewardAmount != null) ...[
              const SizedBox(height: 16),
              _RewardBanner(amount: person.rewardAmount!),
            ],
            const SizedBox(height: 16),
            NamDetailCard(rows: _rows()),
          ],
        ),
      ),
    );
  }

  List<NamDetailRow> _rows() {
    final entries = <String, String?>{
      'Gender': person.gender,
      'Date of birth': _formatDate(person.dateOfBirth),
      'Offence': person.crimeDescription,
      'Contact phone': person.contactPhoneNumber,
      'Investigating officer': person.investigatingOfficer,
      'Supervisor': person.investigatingOfficerSupervisor,
      'Station': person.stationName,
      'Station number': person.stationNumber,
      'Station phone': person.stationContactNumber,
      'Status': person.status,
      'Reference ID': person.id,
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
      const BreadcrumbSegment(label: 'Wanted'),
      BreadcrumbSegment(label: person.fullName),
    ];
  }

  String _initialsFor(WantedPerson person) {
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

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NamCaseChip(caseId: person.id),
        const SizedBox(height: 12),
        Text(
          person.fullName,
          style: NamStyle.title(size: 26, weight: FontWeight.w700, height: 1.05),
        ),
        if (person.alias != null && person.alias!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'a.k.a. "${person.alias}"',
            style: NamStyle.body(size: 14),
          ),
        ],
      ],
    );
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: NamStyle.pageInset),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: NamStyle.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        border: Border.all(color: NamStyle.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 22, color: NamStyle.gold),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REWARD FOR INFORMATION',
                style: NamStyle.mono(
                  size: 10,
                  color: NamStyle.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'JMD \$${amount.toStringAsFixed(0)}',
                style: NamStyle.title(
                  size: 22,
                  weight: FontWeight.w700,
                  color: NamStyle.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../widgets/breadcrumb_trail.dart';

class WantedDetailScreen extends StatelessWidget {
  const WantedDetailScreen({super.key, required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(person.fullName),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(person: person),
          const SizedBox(height: 16),
          _DetailRow(label: 'Alias', value: person.alias),
          _DetailRow(label: 'Gender', value: person.gender),
          _DetailRow(label: 'Date of birth', value: _formatDate(person.dateOfBirth)),
          _DetailRow(label: 'Offence', value: person.crimeDescription),
          _DetailRow(label: 'Reward (JMD)', value: _formatReward(person.rewardAmount)),
          _DetailRow(label: 'Contact phone', value: person.contactPhoneNumber),
          _DetailRow(label: 'Status', value: person.status),
          _DetailRow(label: 'Reference ID', value: person.id),
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
      const BreadcrumbSegment(label: 'Western Operations'),
      BreadcrumbSegment(
        label: 'Wanted Persons',
        onTap: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      ),
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.person, size: 36, color: Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (person.alias != null && person.alias!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'a.k.a. "${person.alias}"',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _StatusChip(status: person.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final label = status;
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB71C1C),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 2),
          Text(value!, style: Theme.of(context).textTheme.bodyLarge),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../widgets/breadcrumb_trail.dart';

class MissingDetailScreen extends StatelessWidget {
  const MissingDetailScreen({super.key, required this.person});

  final MissingPerson person;

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
          _DetailRow(label: 'Gender', value: person.gender),
          _DetailRow(label: 'Date of birth', value: _formatDate(person.dateOfBirth)),
          _DetailRow(label: 'Reported', value: _formatDate(person.reportedDate)),
          _DetailRow(label: 'Last seen', value: person.lastSeenLocation),
          _DetailRow(label: 'Description', value: person.description),
          _DetailRow(label: 'Contact person', value: person.contactPerson),
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
        label: 'Missing Persons',
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
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.person});

  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.amber.shade100,
              child: const Icon(Icons.person_search, size: 36, color: Colors.orange),
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
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B5A00),
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

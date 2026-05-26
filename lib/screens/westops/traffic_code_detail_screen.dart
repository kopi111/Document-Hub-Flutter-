import 'package:flutter/material.dart';

import '../../models/westops/traffic_code.dart';
import '../../theme/jcf_palette.dart';
import '../../widgets/breadcrumb_trail.dart';

class TrafficCodeDetailScreen extends StatelessWidget {
  const TrafficCodeDetailScreen({super.key, required this.entry});

  final TrafficCode entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.code),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(entry: entry),
          const SizedBox(height: 16),
          _DetailRow(label: 'Code', value: entry.code),
          _DetailRow(label: 'Offence', value: entry.offenceDescription),
          _DetailRow(label: 'Fine (JMD)', value: _formatFine(entry.fineAmount)),
          _DetailRow(label: 'Demerit points', value: entry.demeritPoints.toString()),
          _DetailRow(label: 'Legal section', value: entry.legalSection),
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
        label: 'Traffic Codes',
        onTap: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      ),
      BreadcrumbSegment(label: entry.code),
    ];
  }

  String _formatFine(double amount) {
    final whole = amount.toStringAsFixed(0);
    final withSeparators = _withThousandSeparators(whole);
    return '\$$withSeparators';
  }

  String _withThousandSeparators(String integerText) {
    final buffer = StringBuffer();
    for (var index = 0; index < integerText.length; index++) {
      final positionFromRight = integerText.length - index;
      buffer.write(integerText[index]);
      final isLast = index == integerText.length - 1;
      if (!isLast && positionFromRight % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.entry});

  final TrafficCode entry;

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
              backgroundColor: JcfPalette.surfaceRaised,
              child: Text(
                entry.code,
                style: const TextStyle(
                  color: JcfPalette.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.offenceDescription,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.legalSection,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
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

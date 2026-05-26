import 'package:flutter/material.dart';

import '../../models/westops/stolen_vehicle.dart';
import '../../theme/jcf_palette.dart';
import '../../widgets/breadcrumb_trail.dart';

class StolenVehicleDetailScreen extends StatelessWidget {
  const StolenVehicleDetailScreen({super.key, required this.vehicle});

  final StolenVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle.displayName),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(vehicle: vehicle),
          const SizedBox(height: 16),
          _DetailRow(label: 'Make', value: vehicle.make),
          _DetailRow(label: 'Model', value: vehicle.model),
          _DetailRow(label: 'Year', value: vehicle.year?.toString()),
          _DetailRow(label: 'Colour', value: vehicle.color),
          _DetailRow(label: 'Plate', value: vehicle.licensePlate),
          _DetailRow(label: 'Description', value: vehicle.description),
          _DetailRow(label: 'Date stolen', value: _formatDate(vehicle.dateStolen)),
          _DetailRow(label: 'Last known location', value: vehicle.lastKnownLocation),
          _DetailRow(label: 'Owner', value: vehicle.ownerName),
          _DetailRow(label: 'Owner contact', value: vehicle.ownerContact),
          _DetailRow(label: 'Reward (JMD)', value: _formatReward(vehicle.rewardAmount)),
          _DetailRow(label: 'Status', value: vehicle.status),
          _DetailRow(label: 'Reference ID', value: vehicle.id),
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
        label: 'Stolen Vehicles',
        onTap: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      ),
      BreadcrumbSegment(label: vehicle.displayName),
    ];
  }

  String _formatDate(DateTime date) {
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
  const _HeaderCard({required this.vehicle});

  final StolenVehicle vehicle;

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
              backgroundColor: JcfPalette.surface,
              child: const Icon(Icons.directions_car, size: 36, color: JcfPalette.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (vehicle.licensePlate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Plate: ${vehicle.licensePlate}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (vehicle.status != null && vehicle.status!.isNotEmpty)
                    _StatusChip(status: vehicle.status!),
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

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  (Color bg, Color fg) _statusColors(String status) {
    final lower = status.toLowerCase();
    if (lower == 'stolen') return (JcfPalette.accent, JcfPalette.onAccent);
    if (lower == 'recovered') return (JcfPalette.success, JcfPalette.onDanger);
    return (JcfPalette.textDisabled, JcfPalette.textPrimary);
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

import 'package:flutter/material.dart';

import '../../models/westops/stolen_vehicle.dart';
import '../../services/westops/stolen_vehicles_repository.dart';
import '../../services/phone_dialer.dart';
import '../../theme/jcf_palette.dart';
import '../../theme/nam_style.dart';
import '../../widgets/westops/regulation_delete_dialog.dart';

class StolenVehicleDetailScreen extends StatelessWidget {
  const StolenVehicleDetailScreen({super.key, required this.vehicle, this.repository});

  final StolenVehicle vehicle;
  final StolenVehiclesRepository? repository;

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final regulation = await confirmDeletionWithRegulation(
      context,
      itemLabel: vehicle.displayName,
    );
    if (regulation == null) return;
    final repo = repository ?? createStolenVehiclesRepository();
    await repo.delete(vehicle.id);
    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(content: Text('Record deleted · confirmed by reg #$regulation')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: JcfPalette.accent),
        title: Text(vehicle.displayName),
        actions: [
          IconButton(
            tooltip: 'Delete record',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
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
          _DetailRow(
            label: 'Investigating officer',
            value: vehicle.investigatingOfficer,
          ),
          _CallableDetailRow(
            label: 'Officer contact',
            value: vehicle.investigatingOfficerPhone,
          ),
          _DetailRow(
            label: 'Supervisor',
            value: vehicle.investigatingOfficerSupervisor,
          ),
          _DetailRow(label: 'Station', value: vehicle.stationName),
          _CallableDetailRow(
            label: 'Station phone',
            value: vehicle.stationContactNumber,
          ),
          _DetailRow(label: 'Status', value: vehicle.status),
          _DetailRow(label: 'Reference ID', value: vehicle.id),
        ],
      ),
    );
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

/// A [_DetailRow] whose value is a tappable phone number handed to the dialer.
class _CallableDetailRow extends StatelessWidget {
  const _CallableDetailRow({required this.label, required this.value});

  final String label;
  final String? value;

  Future<void> _dial(BuildContext context) async {
    final number = value!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await dialNumber(number);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not call $number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _dial(context),
      child: Padding(
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
            Row(
              children: [
                Icon(Icons.call, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  value!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const Divider(height: 16),
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

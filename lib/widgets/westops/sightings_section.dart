import 'package:flutter/material.dart';

import '../../models/westops/sighting.dart';
import '../../theme/nam_style.dart';

/// Renders the append-only "last seen" log for a wanted or missing person and
/// an action for any officer to add a fresh sighting.
///
/// The section is presentation-only: [onAdd] owns persisting the new entry so
/// the same widget serves both wanted and missing detail screens.
class SightingsSection extends StatelessWidget {
  const SightingsSection({
    super.key,
    required this.sightings,
    required this.onAdd,
  });

  final List<Sighting> sightings;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        NamStyle.pageInset,
        16,
        NamStyle.pageInset,
        0,
      ),
      decoration: BoxDecoration(
        color: NamStyle.surface,
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        border: Border.all(color: NamStyle.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'LAST SEEN LOG',
                    style: NamStyle.mono(
                      size: 10,
                      weight: FontWeight.w600,
                      color: NamStyle.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                  style: TextButton.styleFrom(foregroundColor: NamStyle.gold),
                  label: Text(
                    'Add sighting',
                    style: NamStyle.body(size: 13, color: NamStyle.gold),
                  ),
                ),
              ],
            ),
          ),
          if (sightings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No sightings logged yet.',
                style: NamStyle.body(size: 13, color: NamStyle.textSecondary),
              ),
            )
          else
            for (var index = 0; index < sightings.length; index++) ...[
              const Divider(height: 1, color: NamStyle.hairline),
              _SightingRow(sighting: sightings[index]),
            ],
        ],
      ),
    );
  }
}

class _SightingRow extends StatelessWidget {
  const _SightingRow({required this.sighting});

  final Sighting sighting;

  @override
  Widget build(BuildContext context) {
    final notes = sighting.notes;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sighting.location,
            style: NamStyle.title(size: 15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(sighting.seenAt)}  ·  ${sighting.addedBy}',
            style: NamStyle.mono(size: 10, letterSpacing: 1),
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(notes, style: NamStyle.body(size: 13)),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/westops/sighting.dart';
import '../../screens/westops/wanted_style.dart';
import '../../services/phone_dialer.dart';

/// Square, rounded mugshot. Prefers a locally captured photo, then a remote
/// photo, and falls back to the subject's initials on a navy panel.
class WantedPhoto extends StatelessWidget {
  const WantedPhoto({
    super.key,
    required this.initials,
    this.photoUrl,
    this.photoBytes,
    this.size = 84,
    this.radius = 12,
  });

  final String initials;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: _buildImage()),
    );
  }

  Widget _buildImage() {
    final bytes = photoBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
    }
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      color: WantedStyle.navy,
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: WantedStyle.title(
          size: size * 0.34,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Small filled red tag for a category (e.g. "MURDER", "MISSING").
class CrimeTag extends StatelessWidget {
  const CrimeTag({super.key, required this.label, this.color = WantedStyle.red});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: WantedStyle.label(size: 9.5, color: Colors.white, letterSpacing: 0.6),
      ),
    );
  }
}

/// Gold outline pill advertising a reward.
class RewardBadge extends StatelessWidget {
  const RewardBadge({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WantedStyle.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: WantedStyle.gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.payments_outlined, size: 13, color: Color(0xFF9A7200)),
          const SizedBox(width: 4),
          Text(
            'Reward',
            style: WantedStyle.label(
              size: 10,
              color: const Color(0xFF9A7200),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The JCF crest, sized for an app-bar leading slot.
class JcfCrest extends StatelessWidget {
  const JcfCrest({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/jcf_logo.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.shield_outlined, size: size, color: WantedStyle.navy),
    );
  }
}

/// Navy "CASE …" chip.
class CaseChip extends StatelessWidget {
  const CaseChip({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: WantedStyle.navy,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('CASE $id',
          style: WantedStyle.label(size: 9.5, color: Colors.white, letterSpacing: 0.6)),
    );
  }
}

/// Soft status pill with a check icon (e.g. "Captured", "Found").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: WantedStyle.label(size: 10, color: color, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

/// Rounded grey search field used atop the wanted/missing lists.
class FbiSearchField extends StatelessWidget {
  const FbiSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 12, WantedStyle.pageInset, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: WantedStyle.body(size: 14, color: WantedStyle.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: WantedStyle.body(size: 14, color: WantedStyle.textSecondary),
          prefixIcon: const Icon(Icons.search, color: WantedStyle.textSecondary),
          isDense: true,
          filled: true,
          fillColor: WantedStyle.chip,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: WantedStyle.blue, width: 1.4),
          ),
        ),
      ),
    );
  }
}

/// Horizontal pill filter bar; the selected pill is gold.
class FbiFilterBar extends StatelessWidget {
  const FbiFilterBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: WantedStyle.pageInset),
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? WantedStyle.gold : WantedStyle.chip,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labels[index],
                style: WantedStyle.title(
                  size: 13,
                  weight: FontWeight.w700,
                  color: isSelected ? WantedStyle.navy : WantedStyle.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Left-aligned record count line.
class ResultCount extends StatelessWidget {
  const ResultCount({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 10, WantedStyle.pageInset, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count ${count == 1 ? 'record' : 'records'}',
          style: WantedStyle.label(size: 11, color: WantedStyle.textSecondary),
        ),
      ),
    );
  }
}

/// Share / Submit a Tip / Call action block used on the detail pages.
class FbiActionBar extends StatelessWidget {
  const FbiActionBar({
    super.key,
    required this.onShare,
    required this.onTip,
    required this.onCall,
    this.callLabel = 'Call the JCF',
  });

  final VoidCallback onShare;
  final VoidCallback onTip;
  final VoidCallback onCall;
  final String callLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FbiActionButton(
                  label: 'Share',
                  icon: Icons.share_outlined,
                  color: WantedStyle.blue,
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FbiActionButton(
                  label: 'Submit a Tip',
                  icon: Icons.tips_and_updates_outlined,
                  color: WantedStyle.gold,
                  textColor: WantedStyle.navy,
                  onTap: onTip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FbiActionButton(
            label: callLabel,
            icon: Icons.call,
            color: WantedStyle.green,
            outlined: true,
            fullWidth: true,
            onTap: onCall,
          ),
        ],
      ),
    );
  }
}

class FbiActionButton extends StatelessWidget {
  const FbiActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
    this.outlined = false,
    this.fullWidth = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Color textColor;
  final bool outlined;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final foreground = outlined ? color : textColor;
    return Material(
      color: outlined ? Colors.white : color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: outlined ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Text(label,
                  style: WantedStyle.title(
                      size: 14, weight: FontWeight.w700, color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One label/value row inside an [FbiFieldsCard].
class FbiField {
  const FbiField({required this.label, required this.value, this.callable = false});

  final String label;
  final String value;
  final bool callable;
}

/// White rap-sheet card listing [FbiField] rows; phone rows are tap-to-dial.
class FbiFieldsCard extends StatelessWidget {
  const FbiFieldsCard({super.key, required this.rows});

  final List<FbiField> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      decoration: BoxDecoration(
        color: WantedStyle.card,
        borderRadius: BorderRadius.circular(WantedStyle.cardRadius),
        border: Border.all(color: WantedStyle.hairline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _FieldRow(field: rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, thickness: 1, color: WantedStyle.hairline),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});

  final FbiField field;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(field.label,
                style: WantedStyle.label(
                    size: 11, color: WantedStyle.textSecondary, letterSpacing: 0.2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              field.value,
              style: WantedStyle.body(
                size: 14,
                color: field.callable ? WantedStyle.blue : WantedStyle.textPrimary,
                weight: field.callable ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (field.callable)
            const Icon(Icons.call, size: 16, color: WantedStyle.green),
        ],
      ),
    );

    if (!field.callable) return content;
    return InkWell(onTap: () => dialNumber(field.value), child: content);
  }
}

/// White card listing the append-only sightings trail with a "Log" action.
class FbiSightingsCard extends StatelessWidget {
  const FbiSightingsCard({super.key, required this.sightings, required this.onAdd});

  final List<Sighting> sightings;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      decoration: BoxDecoration(
        color: WantedStyle.card,
        borderRadius: BorderRadius.circular(WantedStyle.cardRadius),
        border: Border.all(color: WantedStyle.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: WantedStyle.navy),
                const SizedBox(width: 8),
                Text('Sightings',
                    style: WantedStyle.title(
                        size: 15, weight: FontWeight.w800, color: WantedStyle.navy)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18, color: WantedStyle.blue),
                  label: Text('Log',
                      style: WantedStyle.title(
                          size: 13, weight: FontWeight.w700, color: WantedStyle.blue)),
                ),
              ],
            ),
          ),
          if (sightings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: Text('No sightings logged yet.',
                  style: WantedStyle.body(size: 13, color: WantedStyle.textSecondary)),
            )
          else
            for (var i = 0; i < sightings.length; i++) ...[
              const Divider(height: 1, thickness: 1, color: WantedStyle.hairline),
              _SightingRow(sighting: sightings[i]),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(sighting.location,
                    style: WantedStyle.title(
                        size: 14, weight: FontWeight.w700, color: WantedStyle.textPrimary)),
              ),
              Text(_formatDate(sighting.seenAt),
                  style: WantedStyle.label(size: 10, color: WantedStyle.textSecondary)),
            ],
          ),
          const SizedBox(height: 2),
          Text('Logged by ${sighting.addedBy}',
              style: WantedStyle.body(size: 12, color: WantedStyle.textSecondary)),
          if (sighting.notes != null && sighting.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(sighting.notes!, style: WantedStyle.body(size: 13)),
          ],
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
}

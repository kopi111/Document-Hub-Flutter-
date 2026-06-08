import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// A selectable white pill with an optional icon, used for the horizontal
/// "Quick Filters" row on list screens. Selected pills adopt the accent colour.
class HubFilterPill extends StatelessWidget {
  const HubFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent = const Color(0xFF2D6CDF),
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? accent : HubStyle.textSecondary;
    return Material(
      color: HubStyle.cardSurface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : const Color(0xFFE2E8F0),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontally scrolling row of [HubFilterPill]s with consistent padding.
class HubFilterPillRow extends StatelessWidget {
  const HubFilterPillRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => Center(child: children[index]),
      ),
    );
  }
}

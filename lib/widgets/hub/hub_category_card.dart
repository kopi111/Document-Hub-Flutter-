import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// A "Browse by Category" cell: a soft white card with a tinted icon, a title,
/// and a count line. Used in the two-column category grids on list screens.
class HubCategoryCard extends StatelessWidget {
  const HubCategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.count,
    required this.tint,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String count;
  final HubTint tint;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
        border: selected
            ? Border.all(color: tint.foreground, width: 1.5)
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint.foreground, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        count,
                        style: TextStyle(
                          color: tint.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

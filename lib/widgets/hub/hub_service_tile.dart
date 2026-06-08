import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// A single home-grid service: a soft white card with a colour-tinted circular
/// icon and a short two-line label beneath it.
class HubServiceTile extends StatelessWidget {
  const HubServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final HubTint tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.tileRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.tileRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint.foreground, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HubStyle.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
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

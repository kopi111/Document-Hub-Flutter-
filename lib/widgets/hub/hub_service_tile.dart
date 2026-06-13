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
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final HubTint tint;
  final VoidCallback onTap;

  /// Unread/new count shown as a red badge on the icon. Hidden when zero.
  final int badgeCount;

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
                Stack(
                  clipBehavior: Clip.none,
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
                    if (badgeCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0414C),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(color: HubStyle.cardSurface, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                  ],
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

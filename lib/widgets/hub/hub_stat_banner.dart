import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// The gradient summary card that tops each list screen: a circular emblem, a
/// large count with label and caption, and an optional action pill. The
/// three-colour accent stripe runs along the bottom edge.
class HubStatBanner extends StatelessWidget {
  const HubStatBanner({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.caption,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String count;
  final String label;
  final String caption;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HubStyle.heroRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: HubStyle.headerGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count,
                          style: const TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                        Text(
                          label,
                          style: const TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          caption,
                          style: TextStyle(
                            color: HubStyle.onGradientMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 8),
                    _ActionPill(label: actionLabel!, onTap: onAction!),
                  ],
                ],
              ),
            ),
            HubStyle.accentBar(),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: HubStyle.onGradient,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.chevron_right,
                  color: HubStyle.onGradient, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

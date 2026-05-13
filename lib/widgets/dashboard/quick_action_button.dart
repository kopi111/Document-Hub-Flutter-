import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A single round icon-and-label quick action.
///
/// Tap target is held at 56 dp so it always satisfies the 48 dp accessibility
/// floor regardless of how it is laid out within a Row.
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onPressed == null;
    final iconColor =
        disabled ? scheme.onSurface.withValues(alpha: 0.4) : scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: scheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Center(child: Icon(icon, color: iconColor, size: 26)),
            ),
          ),
        ),
        const Gap(6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

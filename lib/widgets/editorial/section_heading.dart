import 'package:flutter/material.dart';

import '../../theme/duty_theme.dart';

/// Editorial section heading: leading hairline rule + all-caps slab title +
/// optional trailing text action with chevron.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 18,
            height: 1,
            color: colors.mutedGold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
            ),
          ),
          if (action != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      action!.toUpperCase(),
                      style: DutyTheme.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: colors.mutedGold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colors.mutedGold,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

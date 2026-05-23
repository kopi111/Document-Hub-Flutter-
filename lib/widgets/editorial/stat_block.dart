import 'package:flutter/material.dart';

import '../../theme/duty_theme.dart';

/// One stat: label above, big slab number with count-up, caption below.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    this.caption,
  });

  final String label;
  final int value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.mutedGold,
              ),
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, current, child) => Text(
            '$current',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(
            caption!,
            style: DutyTheme.mono(
              size: 11,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}

/// Three [StatBlock]s in a row, separated by vertical hairlines.
class StatBlockRow extends StatelessWidget {
  const StatBlockRow({super.key, required this.stats});

  final List<StatBlock> stats;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      children.add(Expanded(child: stats[i]));
      if (i < stats.length - 1) {
        children.add(Container(
          width: 1,
          height: 56,
          color: colors.hairline,
          margin: const EdgeInsets.symmetric(horizontal: 14),
        ));
      }
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/duty_theme.dart';

class BreadcrumbSegment {
  const BreadcrumbSegment({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Editorial breadcrumb — mono small-caps separated by `/`, hairline rule
/// beneath. Lives inside an AppBar `bottom:` slot.
class BreadcrumbTrail extends StatelessWidget implements PreferredSizeWidget {
  const BreadcrumbTrail({super.key, required this.segments});

  final List<BreadcrumbSegment> segments;

  static const double _trailHeight = 32;

  @override
  Size get preferredSize => const Size.fromHeight(_trailHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.hairline, width: 1),
          ),
        ),
        height: _trailHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _buildSegmentWidgets(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegmentWidgets(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final widgets = <Widget>[];
    for (var index = 0; index < segments.length; index++) {
      if (index > 0) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '/',
            style: DutyTheme.mono(
              size: 11,
              color: colors.hairline,
              weight: FontWeight.w600,
            ),
          ),
        ));
      }
      final isCurrent = index == segments.length - 1;
      widgets.add(_SegmentLabel(segment: segments[index], isCurrent: isCurrent));
    }
    return widgets;
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.segment, required this.isCurrent});

  final BreadcrumbSegment segment;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    final canFollow = segment.onTap != null && !isCurrent;

    final style = DutyTheme.mono(
      size: 11,
      color: isCurrent ? scheme.onSurface : colors.mutedGold,
      weight: isCurrent ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 1.0,
    );

    final label = Text(
      segment.label.toUpperCase(),
      style: style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (!canFollow) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: label,
      );
    }

    return InkWell(
      onTap: segment.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: label,
      ),
    );
  }
}

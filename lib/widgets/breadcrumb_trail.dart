import 'package:flutter/material.dart';

class BreadcrumbSegment {
  const BreadcrumbSegment({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

class BreadcrumbTrail extends StatelessWidget implements PreferredSizeWidget {
  const BreadcrumbTrail({super.key, required this.segments});

  final List<BreadcrumbSegment> segments;

  static const double _trailHeight = 36;
  static const double _separatorSize = 14;

  @override
  Size get preferredSize => const Size.fromHeight(_trailHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer.withValues(alpha: 0.45),
      child: SizedBox(
        height: _trailHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _buildSegmentWidgets(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSegmentWidgets(BuildContext context) {
    final widgets = <Widget>[];
    for (var index = 0; index < segments.length; index++) {
      if (index > 0) widgets.add(const _BreadcrumbSeparator(size: _separatorSize));
      final isCurrent = index == segments.length - 1;
      widgets.add(_SegmentLabel(segment: segments[index], isCurrent: isCurrent));
    }
    return widgets;
  }
}

class _BreadcrumbSeparator extends StatelessWidget {
  const _BreadcrumbSeparator({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.chevron_right, size: size, color: colors.onSurfaceVariant),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({required this.segment, required this.isCurrent});

  final BreadcrumbSegment segment;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canFollow = segment.onTap != null && !isCurrent;

    final labelStyle = textTheme.bodySmall?.copyWith(
      color: isCurrent ? colors.onSurface : colors.primary,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
    );

    final label = Text(
      segment.label,
      style: labelStyle,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );

    if (!canFollow) return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: label);

    return InkWell(
      onTap: segment.onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: label,
      ),
    );
  }
}

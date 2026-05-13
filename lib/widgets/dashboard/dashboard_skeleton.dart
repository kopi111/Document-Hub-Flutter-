import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shimmer/shimmer.dart';

/// Greyed shimmer placeholder mirroring the live dashboard's geometry:
/// greeting block, quick action row, stat row, and a category grid.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Block(height: 96, radius: 16),
            const Gap(20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (_) => const _Circle(diameter: 56)),
            ),
            const Gap(24),
            Row(
              children: const [
                Expanded(child: _Block(height: 132, radius: 16)),
                Gap(12),
                Expanded(child: _Block(height: 132, radius: 16)),
              ],
            ),
            const Gap(24),
            const _Block(height: 22, radius: 6, width: 160),
            const Gap(12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) =>
                  const _Block(height: 0, radius: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final double height;
  final double radius;
  final double? width;

  const _Block({
    required this.height,
    required this.radius,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final filled = height == 0;
    return Container(
      height: filled ? null : height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double diameter;
  const _Circle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

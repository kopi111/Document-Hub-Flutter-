import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/duty_theme.dart';
import 'mugshot_placeholder.dart';

/// Wanted-poster styled card for gallery grids.
///
/// Composed of [PosterImage] (3:4 portrait, Hero-tagged, with placeholder
/// fallbacks), [PosterBanner] (corner ribbon naming the list), and
/// [PosterCaption] (mono ID + slab name + optional status).
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.heroTag,
    required this.bannerLabel,
    required this.bannerColor,
    required this.fullName,
    required this.caseId,
    required this.initials,
    this.photoUrl,
    this.status,
    this.onTap,
  });

  final String heroTag;
  final String bannerLabel;
  final Color bannerColor;
  final String fullName;
  final String caseId;
  final String initials;
  final String? photoUrl;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.hairline, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  PosterImage(
                    heroTag: heroTag,
                    photoUrl: photoUrl,
                    initials: initials,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: PosterBanner(
                      label: bannerLabel,
                      color: bannerColor,
                    ),
                  ),
                ],
              ),
              PosterCaption(
                fullName: fullName,
                caseId: caseId,
                status: status,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.heroTag,
    required this.initials,
    this.photoUrl,
  });

  final String heroTag;
  final String initials;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final width = MediaQuery.sizeOf(context).width / 2;
    final cacheWidth = (width * dpr).round();

    final placeholder = MugshotPlaceholder(initials: initials);
    final body = (photoUrl == null || photoUrl!.isEmpty)
        ? placeholder
        : CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
            memCacheWidth: cacheWidth,
            placeholder: (_, url) => _ShimmerCell(),
            errorWidget: (_, url, error) => placeholder,
          );

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Hero(
        tag: heroTag,
        child: ClipRect(child: body),
      ),
    );
  }
}

class _ShimmerCell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainer,
      child: Container(color: scheme.surfaceContainerHighest),
    );
  }
}

class PosterBanner extends StatelessWidget {
  const PosterBanner({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: color,
      child: Text(
        label.toUpperCase(),
        style: DutyTheme.mono(
          size: 10,
          weight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class PosterCaption extends StatelessWidget {
  const PosterCaption({
    super.key,
    required this.fullName,
    required this.caseId,
    this.status,
  });

  final String fullName;
  final String caseId;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CASE / $caseId',
            style: DutyTheme.mono(
              size: 10,
              color: colors.mutedGold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.15,
                ),
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            _StatusPill(status: status!),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colors.hairline),
      ),
      child: Text(
        status.toUpperCase(),
        style: DutyTheme.mono(
          size: 9,
          color: colors.mutedGold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

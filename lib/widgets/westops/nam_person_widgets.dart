import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/nam_style.dart';
import '../editorial/mugshot_placeholder.dart';

/// Rounded charcoal search field with a leading gold magnifier.
class NamSearchField extends StatelessWidget {
  const NamSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NamStyle.pageInset,
        16,
        NamStyle.pageInset,
        8,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: NamStyle.body(size: 14, color: NamStyle.textPrimary),
        cursorColor: NamStyle.gold,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: NamStyle.surface,
          hintText: hint,
          hintStyle: NamStyle.body(size: 13, color: NamStyle.textSecondary),
          prefixIcon: const Icon(Icons.search, size: 20, color: NamStyle.gold),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: NamStyle.textSecondary,
                  tooltip: 'Clear search',
                  onPressed: onClear,
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: _border(NamStyle.hairline),
          enabledBorder: _border(NamStyle.hairline),
          focusedBorder: _border(NamStyle.gold),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        borderSide: BorderSide(color: color),
      );
}

/// Gold-tipped result count, e.g. `— 012 WANTED`.
class NamResultCount extends StatelessWidget {
  const NamResultCount({super.key, required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NamStyle.pageInset,
        8,
        NamStyle.pageInset,
        12,
      ),
      child: Row(
        children: [
          Container(width: 20, height: 2, color: NamStyle.gold),
          const SizedBox(width: 10),
          Text(
            '${count.toString().padLeft(3, '0')}  $label',
            style: NamStyle.mono(size: 11, letterSpacing: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Pill-framed case identifier in mono gold.
class NamCaseChip extends StatelessWidget {
  const NamCaseChip({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: NamStyle.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NamStyle.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        'CASE · $caseId',
        style: NamStyle.mono(size: 10, weight: FontWeight.w700),
      ),
    );
  }
}

/// Filled status pill (FOUND, ACTIVE, …) in any accent color.
class NamStatusChip extends StatelessWidget {
  const NamStatusChip({
    super.key,
    required this.label,
    this.color = NamStyle.gold,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label.toUpperCase(),
            style: NamStyle.mono(size: 10, weight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Rounded poster used in list rows; falls back to a tinted initials plate.
class NamPoster extends StatelessWidget {
  const NamPoster({
    super.key,
    required this.heroTag,
    required this.initials,
    this.photoUrl,
    this.width = 92,
    this.height = 116,
  });

  final String heroTag;
  final String initials;
  final String? photoUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NamStyle.posterRadius),
        child: Hero(
          tag: heroTag,
          child: namPersonImage(photoUrl: photoUrl, initials: initials),
        ),
      ),
    );
  }
}

/// Tappable charcoal card: rounded poster, caller-supplied details, chevron.
class NamPersonCard extends StatelessWidget {
  const NamPersonCard({
    super.key,
    required this.heroTag,
    required this.initials,
    required this.details,
    required this.onTap,
    this.photoUrl,
  });

  final String heroTag;
  final String initials;
  final String? photoUrl;
  final Widget details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(NamStyle.cardRadius);
    return Container(
      decoration: BoxDecoration(
        color: NamStyle.surface,
        borderRadius: radius,
        border: Border.all(color: NamStyle.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NamPoster(
                  heroTag: heroTag,
                  initials: initials,
                  photoUrl: photoUrl,
                ),
                const SizedBox(width: 14),
                Expanded(child: details),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: NamStyle.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cinematic 4:3 portrait header with a scrim fading to the page background
/// and an overlaid identity block.
class NamHeroPortrait extends StatelessWidget {
  const NamHeroPortrait({
    super.key,
    required this.heroTag,
    required this.initials,
    required this.overlay,
    this.photoUrl,
  });

  final String heroTag;
  final String initials;
  final Widget overlay;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Hero(
            tag: heroTag,
            child: namPersonImage(photoUrl: photoUrl, initials: initials),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1],
                colors: [Colors.transparent, NamStyle.background],
              ),
            ),
          ),
        ),
        Positioned(
          left: NamStyle.pageInset,
          right: NamStyle.pageInset,
          bottom: 18,
          child: overlay,
        ),
      ],
    );
  }
}

/// Charcoal card grouping label/value detail rows with hairline separators.
class NamDetailCard extends StatelessWidget {
  const NamDetailCard({super.key, required this.rows});

  final List<NamDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < rows.length; index++) {
      if (index > 0) {
        children.add(const Divider(height: 1, color: NamStyle.hairline));
      }
      children.add(rows[index]);
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(
        NamStyle.pageInset,
        4,
        NamStyle.pageInset,
        0,
      ),
      decoration: BoxDecoration(
        color: NamStyle.surface,
        borderRadius: BorderRadius.circular(NamStyle.cardRadius),
        border: Border.all(color: NamStyle.hairline),
      ),
      child: Column(children: children),
    );
  }
}

/// One label/value pair: mono gold label left, primary value right.
class NamDetailRow extends StatelessWidget {
  const NamDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label.toUpperCase(),
              style: NamStyle.mono(
                size: 10,
                weight: FontWeight.w600,
                color: NamStyle.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: NamStyle.body(size: 14, color: NamStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network mugshot with a tinted initials placeholder fallback.
Widget namPersonImage({required String? photoUrl, required String initials}) {
  final placeholder =
      MugshotPlaceholder(initials: initials, tint: NamStyle.surfaceRaised);
  if (photoUrl == null || photoUrl.isEmpty) return placeholder;
  return CachedNetworkImage(
    imageUrl: photoUrl,
    fit: BoxFit.cover,
    errorWidget: (_, _, _) => placeholder,
  );
}

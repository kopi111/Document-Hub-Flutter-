import 'package:flutter/material.dart';

import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
import '../../theme/duty_theme.dart';
import 'news_date_label.dart';
import 'news_hero_image.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  final NewsArticle article;
  final VoidCallback onTap;

  static const double _thumbnailSize = 92;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _Body(article: article)),
            const SizedBox(width: 14),
            _Thumbnail(article: article, size: _thumbnailSize),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          article.category.toUpperCase(),
          style: DutyTheme.mono(
            size: 10,
            color: colors.mutedGold,
            letterSpacing: 1.4,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          article.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Text(
                article.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DutyTheme.mono(
                  size: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              ' · ',
              style: DutyTheme.mono(
                size: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
            Text(
              relativePublishedLabel(article.publishedAt),
              style: DutyTheme.mono(
                size: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (article.priority.isFlagged) ...[
              Text(
                ' · ',
                style: DutyTheme.mono(
                  size: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                article.priority.label.toUpperCase(),
                style: DutyTheme.mono(
                  size: 11,
                  color: article.priority.foregroundColor(scheme),
                  weight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.article, required this.size});

  final NewsArticle article;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: colors.hairline),
      ),
      child: NewsHeroImage(
        imageUrl: article.imageUrl,
        category: article.category,
      ),
    );
  }
}

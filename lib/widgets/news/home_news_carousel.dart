import 'package:flutter/material.dart';

import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
import '../../theme/duty_theme.dart';
import 'news_date_label.dart';
import 'news_hero_image.dart';
import 'news_priority_badge.dart';

class HomeNewsCarousel extends StatelessWidget {
  const HomeNewsCarousel({
    super.key,
    required this.articles,
    required this.onOpenArticle,
    required this.onViewAll,
  });

  final List<NewsArticle> articles;
  final void Function(NewsArticle article) onOpenArticle;
  final VoidCallback onViewAll;

  static const double _carouselHeight = 230;
  static const double _cardWidth = 260;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _carouselHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: articles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: _cardWidth,
          child: _HomeNewsCard(
            article: articles[index],
            onTap: () => onOpenArticle(articles[index]),
          ),
        ),
      ),
    );
  }
}

class _HomeNewsCard extends StatelessWidget {
  const _HomeNewsCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NewsHeroImage(
                    imageUrl: article.imageUrl,
                    category: article.category,
                  ),
                  if (article.priority.isFlagged)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: NewsPriorityBadge(priority: article.priority),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relativePublishedLabel(article.publishedAt).toUpperCase(),
                    style: DutyTheme.mono(
                      size: 10,
                      color: colors.mutedGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

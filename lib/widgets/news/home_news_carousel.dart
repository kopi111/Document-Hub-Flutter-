import 'package:flutter/material.dart';

import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
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

  static const double _carouselHeight = 210;
  static const double _cardWidth = 280;

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(onViewAll: onViewAll),
          const SizedBox(height: 8),
          SizedBox(
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
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Latest from the Force',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onViewAll,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('View all'),
            iconAlignment: IconAlignment.end,
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
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
                    article.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    relativePublishedLabel(article.publishedAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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

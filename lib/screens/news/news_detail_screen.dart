import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/news/news_article.dart';
import '../../theme/jcf_palette.dart';
import '../../models/news/news_priority.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/news/news_category_label.dart';
import '../../widgets/news/news_date_label.dart';
import '../../widgets/news/news_hero_image.dart';
import '../../widgets/news/news_priority_badge.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  static const double _heroAspectRatio = 16 / 9;
  static const int _breadcrumbTitleMaxLength = 28;
  static const Color _highlightYellow = JcfPalette.accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () => _showShareUnavailable(context),
          ),
        ],
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NewsCategoryLabel(category: article.category),
                    if (article.priority.isFlagged) ...[
                      const SizedBox(width: 10),
                      NewsPriorityBadge(priority: article.priority),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _AuthorRow(article: article),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: _heroAspectRatio,
                child: NewsHeroImage(
                  imageUrl: article.imageUrl,
                  category: article.category,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: _BodyMarkdown(
              body: article.body,
              highlightColor: _highlightYellow,
            ),
          ),
        ],
      ),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments(BuildContext context) {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      BreadcrumbSegment(
        label: 'News',
        onTap: Navigator.canPop(context) ? () => Navigator.pop(context) : null,
      ),
      BreadcrumbSegment(label: _truncatedTitle(article.title)),
    ];
  }

  String _truncatedTitle(String title) {
    if (title.length <= _breadcrumbTitleMaxLength) return title;
    return '${title.substring(0, _breadcrumbTitleMaxLength - 1)}…';
  }

  void _showShareUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing will be enabled in a future release.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          article.author,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        _Dot(),
        Text(
          absolutePublishedLabel(article.publishedAt),
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '·',
      style: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BodyMarkdown extends StatelessWidget {
  const _BodyMarkdown({required this.body, required this.highlightColor});

  final String body;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MarkdownBody(
      data: body,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: textTheme.bodyLarge?.copyWith(height: 1.55, fontSize: 16),
        h1: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        h2: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        h3: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        blockquote: textTheme.bodyLarge?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          height: 1.45,
          fontStyle: FontStyle.normal,
        ),
        blockquoteDecoration: BoxDecoration(
          color: highlightColor,
          borderRadius: BorderRadius.circular(4),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        listBullet: textTheme.bodyLarge?.copyWith(height: 1.55),
      ),
    );
  }
}

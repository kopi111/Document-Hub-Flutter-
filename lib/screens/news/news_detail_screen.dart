import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/news/news_date_label.dart';
import '../../widgets/news/news_hero_image.dart';
import '../../widgets/news/news_priority_badge.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});

  final NewsArticle article;

  static const double _heroAspectRatio = 16 / 9;
  static const int _breadcrumbTitleMaxLength = 28;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          _HeroSection(article: article, aspectRatio: _heroAspectRatio),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TitleAndPriority(article: article),
                const SizedBox(height: 12),
                _AuthorRow(article: article),
                const SizedBox(height: 20),
                _BodyMarkdown(body: article.body),
              ],
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.article, required this.aspectRatio});

  final NewsArticle article;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: NewsHeroImage(
        imageUrl: article.imageUrl,
        category: article.category,
      ),
    );
  }
}

class _TitleAndPriority extends StatelessWidget {
  const _TitleAndPriority({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.priority.isFlagged) ...[
          NewsPriorityBadge(priority: article.priority),
          const SizedBox(height: 10),
        ],
        Text(
          article.title,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
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
          article.category,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.primary,
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
  const _BodyMarkdown({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return MarkdownBody(
      data: body,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: textTheme.bodyLarge?.copyWith(height: 1.5),
        h1: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        h2: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        h3: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        blockquote: textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: scheme.onSurfaceVariant,
        ),
        blockquoteDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border(
            left: BorderSide(color: scheme.primary, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        code: TextStyle(
          backgroundColor: scheme.surfaceContainerHighest,
          fontFamily: 'monospace',
        ),
        listBullet: textTheme.bodyLarge,
      ),
    );
  }
}

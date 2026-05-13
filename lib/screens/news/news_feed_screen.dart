import 'package:flutter/material.dart';

import '../../models/news/news_article.dart';
import '../../services/news/news_repository.dart';
import '../../widgets/breadcrumb_trail.dart';
import '../../widgets/news/news_card.dart';
import 'news_detail_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key, required this.repository});

  final NewsRepository repository;

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  List<NewsArticle> _articles = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final articles = await widget.repository.latestArticles();
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loading = false;
      });
    } catch (failure) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load announcements: $failure';
        _loading = false;
      });
    }
  }

  Future<void> _openArticle(NewsArticle article) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('JCF Announcements'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
        child: _buildBody(),
      ),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments() {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'News'),
    ];
  }

  Widget _buildBody() {
    if (_loading) return const _NewsLoadingState();
    if (_error != null) {
      return _NewsErrorState(message: _error!, onRetry: _loadArticles);
    }
    if (_articles.isEmpty) return const _NewsEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _articles.length,
      itemBuilder: (context, index) => NewsCard(
        article: _articles[index],
        onTap: () => _openArticle(_articles[index]),
      ),
    );
  }
}

class _NewsLoadingState extends StatelessWidget {
  const _NewsLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _NewsEmptyState extends StatelessWidget {
  const _NewsEmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
      children: [
        Icon(
          Icons.campaign_outlined,
          size: 72,
          color: scheme.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          'No announcements yet',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'When the Force publishes new updates they will appear here.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NewsErrorState extends StatelessWidget {
  const _NewsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ),
      ],
    );
  }
}

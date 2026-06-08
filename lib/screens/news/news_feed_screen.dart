import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
import '../../services/news/news_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/news/news_date_label.dart';
import '../../widgets/notifications_bell.dart';
import 'news_detail_screen.dart';

/// Maps an article category to a stable colour-coded icon + tint so the
/// category grid stays visually consistent regardless of which categories the
/// loaded articles happen to use.
HubTint _tintForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'operational':
      return HubTint.red;
    case 'training':
      return HubTint.green;
    case 'ictd':
      return HubTint.teal;
    case 'force-wide':
      return HubTint.blue;
    default:
      return HubTint.purple;
  }
}

IconData _iconForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'operational':
      return Icons.local_police_outlined;
    case 'training':
      return Icons.school_outlined;
    case 'ictd':
      return Icons.devices_outlined;
    case 'force-wide':
      return Icons.public;
    default:
      return Icons.article_outlined;
  }
}

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key, required this.repository});

  final NewsRepository repository;

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<NewsArticle> _articles = const [];
  bool _loading = true;
  String? _error;

  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _error = 'Could not load news: $failure';
        _loading = false;
      });
    }
  }

  List<NewsArticle> get _topStories => _articles.take(5).toList();

  List<String> get _distinctCategories {
    final seen = <String>{};
    final ordered = <String>[];
    for (final article in _articles) {
      if (seen.add(article.category)) ordered.add(article.category);
    }
    ordered.sort();
    return ordered;
  }

  int _countForCategory(String category) =>
      _articles.where((article) => article.category == category).length;

  List<NewsArticle> get _visibleArticles {
    final lower = _query.toLowerCase();
    return _articles.where((article) {
      if (_category != null && article.category != _category) return false;
      if (lower.isEmpty) return true;
      return article.title.toLowerCase().contains(lower) ||
          article.summary.toLowerCase().contains(lower) ||
          article.category.toLowerCase().contains(lower);
    }).toList();
  }

  bool get _hasFilters => _query.isNotEmpty || _category != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
    });
  }

  void _toggleCategory(String category) => setState(
        () => _category = _category == category ? null : category,
      );

  void _openArticle(NewsArticle article) {
    Navigator.of(context).push(sharedAxis(NewsDetailScreen(article: article)));
  }

  void _announceSubscriptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('News subscriptions will be available in a future release.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Force News',
            showBack: true,
            actions: [
              IconTheme(
                data: const IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(newsRepository: widget.repository),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadArticles);
    }

    final visible = _visibleArticles;
    return RefreshIndicator(
      onRefresh: _loadArticles,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchRow(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onFilter: _clearFilters,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _HeroBanner(onViewAll: _clearFilters),
          ),
          const SizedBox(height: 22),
          if (_topStories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HubSectionHeading(
                title: 'Top Stories',
                actionLabel: 'View All',
                onAction: _clearFilters,
              ),
            ),
            const SizedBox(height: 12),
            _TopStoriesRow(
              stories: _topStories,
              onTap: _openArticle,
            ),
            const SizedBox(height: 22),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(title: 'News Categories'),
          ),
          const SizedBox(height: 12),
          _buildCategoryGrid(),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SubscriptionsBanner(onManage: _announceSubscriptions),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: HubSectionHeading(
              title: _hasFilters ? 'Matching Articles' : 'Latest News',
              actionLabel: _hasFilters ? 'Clear' : null,
              onAction: _hasFilters ? _clearFilters : null,
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 30, 16, 30),
              child: Center(
                child: Text(
                  'No matching articles',
                  style: TextStyle(color: HubStyle.textSecondary),
                ),
              ),
            )
          else
            ...visible.map(
              (article) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ArticleCard(
                  article: article,
                  onTap: () => _openArticle(article),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = _distinctCategories;
    if (categories.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
        children: [
          for (final category in categories)
            HubCategoryCard(
              icon: _iconForCategory(category),
              title: category,
              count: '${_countForCategory(category)} articles',
              tint: _tintForCategory(category),
              selected: _category == category,
              onTap: () => _toggleCategory(category),
            ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onFilter,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: HubStyle.cardSurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: HubStyle.cardShadow,
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search news, updates...',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: HubStyle.textSecondary),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: HubStyle.cardSurface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onFilter,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: HubStyle.cardShadow,
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune, size: 18, color: HubStyle.textSecondary),
                  SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: HubStyle.headerGradient,
        borderRadius: BorderRadius.circular(HubStyle.heroRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HubStyle.heroRadius),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign_outlined,
                      color: HubStyle.onGradient,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stay Informed. Stay Prepared.',
                          style: TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Force orders, operational updates and announcements from across the JCF.',
                          style: TextStyle(
                            color: HubStyle.onGradientMuted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _HeroPill(
                          label: 'View All News',
                          onTap: onViewAll,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            HubStyle.accentBar(),
          ],
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF18398A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                size: 15,
                color: Color(0xFF18398A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopStoriesRow extends StatelessWidget {
  const _TopStoriesRow({required this.stories, required this.onTap});

  final List<NewsArticle> stories;
  final ValueChanged<NewsArticle> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 232,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, index) => _TopStoryCard(
          article: stories[index],
          onTap: () => onTap(stories[index]),
        ),
      ),
    );
  }
}

class _TopStoryCard extends StatelessWidget {
  const _TopStoryCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: HubStyle.cardSurface,
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          boxShadow: HubStyle.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(HubStyle.cardRadius),
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(HubStyle.cardRadius),
                  ),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: _ArticleImage(article: article),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryChip(category: article.category),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        relativePublishedLabel(article.publishedAt),
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionsBanner extends StatelessWidget {
  const _SubscriptionsBanner({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    const tint = HubTint.orange;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: tint.foreground,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Never Miss an Update',
                    style: TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Choose the categories you want alerts for.',
                    style: TextStyle(
                      color: HubStyle.textSecondary,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: tint.foreground,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onManage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(HubStyle.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: _ArticleImage(article: article),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CategoryChip(category: article.category),
                          if (article.priority.isFlagged) ...[
                            const SizedBox(width: 8),
                            _PriorityDot(priority: article.priority),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        article.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        absolutePublishedLabel(article.publishedAt),
                        style: const TextStyle(
                          color: HubStyle.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders an article image when one is available, otherwise a tinted gradient
/// placeholder badged with the category icon.
class _ArticleImage extends StatelessWidget {
  const _ArticleImage({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final url = article.imageUrl;
    if (url == null || url.isEmpty) {
      return _ImagePlaceholder(category: article.category);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _ImagePlaceholder(category: article.category),
      errorWidget: (_, _, _) => _ImagePlaceholder(category: article.category),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final tint = _tintForCategory(category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.background, tint.foreground.withValues(alpha: 0.35)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(_iconForCategory(category), color: tint.foreground, size: 30),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final tint = _tintForCategory(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          color: tint.foreground,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});

  final NewsPriority priority;

  @override
  Widget build(BuildContext context) {
    final color =
        priority == NewsPriority.urgent ? HubTint.red.foreground : HubTint.orange.foreground;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 96),
      children: [
        const Icon(Icons.error_outline, size: 64, color: Color(0xFFE0414C)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: HubStyle.textPrimary),
        ),
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

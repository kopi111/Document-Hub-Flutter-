import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../models/document.dart';
import '../models/news/news_article.dart';
import '../models/news/news_priority.dart';
import '../services/github_service.dart';
import '../services/news/in_memory_news_repository.dart';
import '../services/news/news_repository.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard/category_card.dart';
import '../widgets/dashboard/dashboard_section_header.dart';
import '../widgets/dashboard/dashboard_skeleton.dart';
import '../widgets/dashboard/duty_stats_row.dart';
import '../widgets/dashboard/greeting_card.dart';
import '../widgets/dashboard/quick_action_button.dart';
import '../widgets/news/home_news_carousel.dart';
import 'about_screen.dart';
import 'calendar/calendar_screen.dart';
import 'document_list_screen.dart';
import 'map/map_screen.dart';
import 'news/news_detail_screen.dart';
import 'news/news_feed_screen.dart';
import 'notes/notes_screen.dart';
import 'search_results_screen.dart';

const List<int> _documentsThisWeekMock = [12, 18, 9, 24, 17, 21, 14];
const List<int> _reminderCountsMock = [1, 0, 2, 1, 3, 0, 2];
const int _activeRemindersMock = 3;

const double _tabletBreakpoint = 600;
const double _sidebarWidth = 300;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeCarouselLimit = 3;

  final GitHubService _service = GitHubService();
  final NewsRepository _newsRepository = InMemoryNewsRepository();
  List<PolicyDocument> _allDocuments = [];
  Map<String, List<PolicyDocument>> _categories = {};
  List<NewsArticle> _latestNews = const [];
  bool _loading = true;
  String? _error;

  _CategorySelection? _tabletSelection;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadLatestNews();
  }

  Future<void> _loadLatestNews() async {
    try {
      final latest =
          await _newsRepository.latestArticles(limit: _homeCarouselLimit);
      if (!mounted) return;
      setState(() {
        _latestNews = latest;
      });
    } catch (_) {
      // Home tile is optional UI; swallow failures and leave it empty.
      if (!mounted) return;
      setState(() {
        _latestNews = const [];
      });
    }
  }

  void _openNewsFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsFeedScreen(repository: _newsRepository),
      ),
    );
  }

  void _openNewsArticle(NewsArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(article: article),
      ),
    );
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final docs = await _service.fetchDocuments();
      setState(() {
        _allDocuments = docs;
        _categories = _service.groupByCategory(docs);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load documents: $e';
        _loading = false;
      });
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(documents: _allDocuments),
      ),
    );
  }

  void _openCategoryFullScreen(String category, List<PolicyDocument> docs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentListScreen(
          title: category,
          documents: docs,
        ),
      ),
    );
  }

  void _selectTabletCategory(String category, List<PolicyDocument> docs) {
    setState(() {
      _tabletSelection = _CategorySelection(category: category, documents: docs);
    });
  }

  void _handleMenuAction(BuildContext context, _HomeMenuAction action) {
    switch (action) {
      case _HomeMenuAction.about:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Force Orders':
        return Icons.shield;
      case 'JCF Policies':
        return Icons.policy;
      case 'NPCJ':
        return Icons.school;
      case 'TMMD':
        return Icons.directions_car;
      case 'PMMD':
        return Icons.build;
      case 'CIB':
        return Icons.search;
      case 'SOPs':
        return Icons.list_alt;
      case 'PRDB':
        return Icons.analytics;
      case 'PECC':
        return Icons.verified;
      default:
        return Icons.folder;
    }
  }

  Color _categoryColor(String category, ColorScheme scheme) {
    switch (category) {
      case 'Force Orders':
        return scheme.primary;
      case 'JCF Policies':
        return Colors.blueGrey;
      case 'NPCJ':
        return Colors.indigo;
      case 'TMMD':
        return Colors.orange;
      case 'PMMD':
        return Colors.brown;
      case 'CIB':
        return Colors.red;
      case 'SOPs':
        return Colors.teal;
      default:
        return scheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final useTabletLayout = width > _tabletBreakpoint;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('JCF Duty'),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search documents',
              onPressed: _openSearch,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: _loadDocuments,
          ),
          PopupMenuButton<_HomeMenuAction>(
            tooltip: 'More options',
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _HomeMenuAction.about,
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(scheme, useTabletLayout),
    );
  }

  Widget _buildBody(ColorScheme scheme, bool useTabletLayout) {
    if (_loading) return const DashboardSkeleton();
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadDocuments);
    }
    return useTabletLayout
        ? _buildTabletLayout(scheme)
        : _buildPhoneLayout(scheme);
  }

  void _openCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  void _openNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotesScreen()),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  Widget _buildPhoneLayout(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GreetingCard(),
          const Gap(20),
          _QuickActionsRow(
            onCalendar: _openCalendar,
            onNotes: _openNotes,
            onMap: _openMap,
            onSearch: _openSearch,
          ),
          const Gap(24),
          const DutyStatsRow(
            documentsThisWeek: _documentsThisWeekMock,
            activeRemindersTotal: _activeRemindersMock,
            reminderCounts: _reminderCountsMock,
          ),
          const Gap(24),
          if (_latestNews.isNotEmpty) ...[
            DashboardSectionHeader(
              title: 'Latest from the Force',
              actionLabel: 'View all',
              onActionPressed: _openNewsFeed,
            ),
            const Gap(8),
            HomeNewsCarousel(
              articles: _latestNews,
              onOpenArticle: _openNewsArticle,
              onViewAll: _openNewsFeed,
            ),
            const Gap(20),
          ],
          DashboardSectionHeader(
            title: 'Library',
            actionLabel: 'View all',
            onActionPressed: () =>
                _openCategoryFullScreen('All Documents', _allDocuments),
          ),
          const Gap(12),
          _CategoriesGrid(
            categories: _categories,
            iconFor: _categoryIcon,
            colorFor: (key) => _categoryColor(key, scheme),
            onOpenCategory: _openCategoryFullScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _sidebarWidth,
          child: _CategorySidebar(
            documentCount: _allDocuments.length,
            categoryCount: _categories.length,
            categories: _categories,
            selection: _tabletSelection,
            iconFor: _categoryIcon,
            colorFor: (key) => _categoryColor(key, scheme),
            onSelectAll: () =>
                _selectTabletCategory('All Documents', _allDocuments),
            onSelectCategory: _selectTabletCategory,
            latestNews: _latestNews,
            onOpenNewsArticle: _openNewsArticle,
            onOpenNewsFeed: _openNewsFeed,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: _TabletCategoryDetail(selection: _tabletSelection),
        ),
      ],
    );
  }
}

enum _HomeMenuAction { about }

class _CategorySelection {
  final String category;
  final List<PolicyDocument> documents;
  const _CategorySelection({required this.category, required this.documents});
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({
    required this.documentCount,
    required this.categoryCount,
  });

  final int documentCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: scheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(value: '$documentCount', label: 'Documents', icon: Icons.description),
          _Stat(value: '$categoryCount', label: 'Categories', icon: Icons.category),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onCalendar,
    required this.onNotes,
    required this.onMap,
    required this.onSearch,
  });

  final VoidCallback onCalendar;
  final VoidCallback onNotes;
  final VoidCallback onMap;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      QuickActionButton(
        icon: Icons.event,
        label: 'Calendar',
        onPressed: onCalendar,
      ),
      QuickActionButton(
        icon: Icons.notes,
        label: 'Notes',
        onPressed: onNotes,
      ),
      QuickActionButton(
        icon: Icons.map,
        label: 'Map',
        onPressed: onMap,
      ),
      QuickActionButton(
        icon: Icons.search,
        label: 'Search',
        onPressed: onSearch,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < actions.length; i++)
          actions[i]
              .animate()
              .fadeIn(duration: 220.ms, delay: (60 * i).ms)
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1, 1),
                duration: 220.ms,
                delay: (60 * i).ms,
                curve: Curves.easeOutCubic,
              ),
      ],
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({
    required this.categories,
    required this.iconFor,
    required this.colorFor,
    required this.onOpenCategory,
  });

  final Map<String, List<PolicyDocument>> categories;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;
  final void Function(String category, List<PolicyDocument> docs)
      onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final card = CategoryCard(
          category: entry.key,
          documentCount: entry.value.length,
          icon: iconFor(entry.key),
          tint: colorFor(entry.key),
          onTap: () => onOpenCategory(entry.key, entry.value),
        );
        return card.animate().fadeIn(
              duration: 220.ms,
              delay: (50 * index).ms,
            );
      },
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.documentCount,
    required this.categoryCount,
    required this.categories,
    required this.selection,
    required this.iconFor,
    required this.colorFor,
    required this.onSelectAll,
    required this.onSelectCategory,
    required this.latestNews,
    required this.onOpenNewsArticle,
    required this.onOpenNewsFeed,
  });

  final int documentCount;
  final int categoryCount;
  final Map<String, List<PolicyDocument>> categories;
  final _CategorySelection? selection;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;
  final VoidCallback onSelectAll;
  final void Function(String category, List<PolicyDocument> docs)
      onSelectCategory;
  final List<NewsArticle> latestNews;
  final void Function(NewsArticle article) onOpenNewsArticle;
  final VoidCallback onOpenNewsFeed;

  String? get _selectedCategory {
    final current = selection;
    return current is _CategorySelection ? current.category : null;
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedCategory == 'All Documents';
    return ListView(
      children: [
        if (latestNews.isNotEmpty)
          _SidebarNewsSection(
            articles: latestNews,
            onOpenArticle: onOpenNewsArticle,
            onViewAll: onOpenNewsFeed,
          ),
        _StatsBanner(
          documentCount: documentCount,
          categoryCount: categoryCount,
        ),
        ListTile(
          leading: const Icon(Icons.library_books),
          title: const Text('All Documents'),
          subtitle: Text('$documentCount documents'),
          selected: allSelected,
          onTap: onSelectAll,
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'CATEGORIES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        for (final entry in categories.entries)
          ListTile(
            leading: Icon(iconFor(entry.key), color: colorFor(entry.key)),
            title: Text(entry.key),
            trailing: Text(
              '${entry.value.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            selected: _selectedCategory == entry.key,
            onTap: () => onSelectCategory(entry.key, entry.value),
          ),
      ],
    );
  }
}

class _SidebarNewsSection extends StatelessWidget {
  const _SidebarNewsSection({
    required this.articles,
    required this.onOpenArticle,
    required this.onViewAll,
  });

  final List<NewsArticle> articles;
  final void Function(NewsArticle article) onOpenArticle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Icon(Icons.campaign, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Latest News',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View all'),
              ),
            ],
          ),
        ),
        for (final article in articles)
          _SidebarNewsTile(
            article: article,
            onTap: () => onOpenArticle(article),
          ),
        const Divider(height: 1),
      ],
    );
  }
}

class _SidebarNewsTile extends StatelessWidget {
  const _SidebarNewsTile({required this.article, required this.onTap});

  final NewsArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 36,
              margin: const EdgeInsets.only(top: 2, right: 10),
              decoration: BoxDecoration(
                color: _accent(scheme),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    article.category,
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

  Color _accent(ColorScheme scheme) {
    return article.priority.isFlagged
        ? article.priority.foregroundColor(scheme)
        : scheme.primary;
  }
}

class _TabletCategoryDetail extends StatelessWidget {
  const _TabletCategoryDetail({required this.selection});

  final _CategorySelection? selection;

  @override
  Widget build(BuildContext context) {
    final current = selection;
    if (current == null) return const _EmptyDetailPlaceholder();
    return DocumentListScreen(
      key: ValueKey('category:${current.category}'),
      title: current.category,
      documents: current.documents,
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, size: 64, color: scheme.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            'Select a category to view documents',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose any category from the left to begin browsing.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

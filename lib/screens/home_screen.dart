import 'package:flutter/material.dart';

import '../models/document.dart';
import '../models/news/news_article.dart';
import '../services/github_service.dart';
import '../services/news/in_memory_news_repository.dart';
import '../services/news/news_repository.dart';
import '../services/westops/westops_feature_specs.dart';
import '../theme/duty_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/dashboard/dashboard_skeleton.dart';
import '../widgets/editorial/section_heading.dart';
import '../widgets/editorial/shared_axis_route.dart';
import '../widgets/editorial/stat_block.dart';
import '../widgets/news/home_news_carousel.dart';
import 'about_screen.dart';
import 'calendar/calendar_screen.dart';
import 'document_list_screen.dart';
import 'map/map_screen.dart';
import 'news/news_detail_screen.dart';
import 'news/news_feed_screen.dart';
import 'notes/notes_screen.dart';
import 'search_results_screen.dart';

const int _activeRemindersMock = 3;
const int _documentsThisWeekMock = 12;

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
      setState(() => _latestNews = latest);
    } catch (_) {
      if (!mounted) return;
      setState(() => _latestNews = const []);
    }
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

  void _push(Widget page) {
    Navigator.push(context, sharedAxis(page));
  }

  void _openSearch() => _push(SearchResultsScreen(documents: _allDocuments));
  void _openCalendar() => _push(const CalendarScreen());
  void _openNotes() => _push(const NotesScreen());
  void _openMap() => _push(const MapScreen());
  void _openNewsFeed() =>
      _push(NewsFeedScreen(repository: _newsRepository));
  void _openNewsArticle(NewsArticle article) =>
      _push(NewsDetailScreen(article: article));

  void _openCategoryFullScreen(String category, List<PolicyDocument> docs) {
    _push(DocumentListScreen(title: category, documents: docs));
  }

  void _selectTabletCategory(String category, List<PolicyDocument> docs) {
    setState(() {
      _tabletSelection =
          _CategorySelection(category: category, documents: docs);
    });
  }

  void _handleMenuAction(BuildContext context, _HomeMenuAction action) {
    switch (action) {
      case _HomeMenuAction.about:
        _push(const AboutScreen());
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Force Orders':
        return Icons.shield_outlined;
      case 'JCF Policies':
        return Icons.gavel;
      case 'NPCJ':
        return Icons.school_outlined;
      case 'TMMD':
        return Icons.directions_car_outlined;
      case 'PMMD':
        return Icons.build_outlined;
      case 'CIB':
        return Icons.search;
      case 'SOPs':
        return Icons.list_alt;
      case 'PRDB':
        return Icons.analytics_outlined;
      case 'PECC':
        return Icons.verified_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useTabletLayout = width > _tabletBreakpoint;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Library'),
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
      body: _buildBody(useTabletLayout),
    );
  }

  Widget _buildBody(bool useTabletLayout) {
    if (_loading) return const DashboardSkeleton();
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _loadDocuments);
    }
    return useTabletLayout
        ? _buildTabletLayout()
        : _buildPhoneLayout();
  }

  Widget _buildPhoneLayout() => _DutyDashboard(
        categories: _categories,
        totalDocumentCount: _allDocuments.length,
        latestNews: _latestNews,
        iconFor: _categoryIcon,
        onCalendar: _openCalendar,
        onNotes: _openNotes,
        onMap: _openMap,
        onSearch: _openSearch,
        onOpenNewsArticle: _openNewsArticle,
        onOpenNewsFeed: _openNewsFeed,
        onOpenAllDocuments: () =>
            _openCategoryFullScreen('All Documents', _allDocuments),
        onOpenCategory: _openCategoryFullScreen,
        onOpenWestOpsFeature: _openWestOpsFeature,
      );

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: _sidebarWidth,
          child: _CategorySidebar(
            categories: _categories,
            totalDocumentCount: _allDocuments.length,
            selection: _tabletSelection,
            iconFor: _categoryIcon,
            onSelectAll: () =>
                _selectTabletCategory('All Documents', _allDocuments),
            onSelectCategory: _selectTabletCategory,
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).extension<DutyColors>()!.hairline,
        ),
        Expanded(
          child: _TabletDetailPane(
            selection: _tabletSelection,
            dashboard: _DutyDashboard(
              categories: _categories,
              totalDocumentCount: _allDocuments.length,
              latestNews: _latestNews,
              iconFor: _categoryIcon,
              onCalendar: _openCalendar,
              onNotes: _openNotes,
              onMap: _openMap,
              onSearch: _openSearch,
              onOpenNewsArticle: _openNewsArticle,
              onOpenNewsFeed: _openNewsFeed,
              onOpenAllDocuments: () =>
                  _selectTabletCategory('All Documents', _allDocuments),
              onOpenCategory: _selectTabletCategory,
              onOpenWestOpsFeature: _openWestOpsFeature,
            ),
          ),
        ),
      ],
    );
  }

  void _openWestOpsFeature(WestOpsFeatureSpec spec) =>
      _push(Builder(builder: spec.builder));
}

class _DutyDashboard extends StatelessWidget {
  const _DutyDashboard({
    required this.categories,
    required this.totalDocumentCount,
    required this.latestNews,
    required this.iconFor,
    required this.onCalendar,
    required this.onNotes,
    required this.onMap,
    required this.onSearch,
    required this.onOpenNewsArticle,
    required this.onOpenNewsFeed,
    required this.onOpenAllDocuments,
    required this.onOpenCategory,
    required this.onOpenWestOpsFeature,
  });

  final Map<String, List<PolicyDocument>> categories;
  final int totalDocumentCount;
  final List<NewsArticle> latestNews;
  final IconData Function(String) iconFor;
  final VoidCallback onCalendar;
  final VoidCallback onNotes;
  final VoidCallback onMap;
  final VoidCallback onSearch;
  final void Function(NewsArticle article) onOpenNewsArticle;
  final VoidCallback onOpenNewsFeed;
  final VoidCallback onOpenAllDocuments;
  final void Function(String category, List<PolicyDocument> docs)
      onOpenCategory;
  final void Function(WestOpsFeatureSpec spec) onOpenWestOpsFeature;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _EditorialGreeting(),
          _Hairline(margin: EdgeInsets.zero),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _QuickActionsRow(
              onCalendar: onCalendar,
              onNotes: onNotes,
              onMap: onMap,
              onSearch: onSearch,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(title: 'On duty'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: StatBlockRow(
              stats: [
                const StatBlock(
                  label: 'This week',
                  value: _documentsThisWeekMock,
                  caption: 'documents',
                ),
                const StatBlock(
                  label: 'Reminders',
                  value: _activeRemindersMock,
                  caption: 'next 7 days',
                ),
                StatBlock(
                  label: 'Library',
                  value: totalDocumentCount,
                  caption: 'documents',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(title: 'Western operations'),
          ),
          _WestOpsPreview(onSelect: onOpenWestOpsFeature),
          if (latestNews.isNotEmpty) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SectionHeading(
                title: 'Latest from the force',
                action: 'View all',
                onAction: onOpenNewsFeed,
              ),
            ),
            HomeNewsCarousel(
              articles: latestNews,
              onOpenArticle: onOpenNewsArticle,
              onViewAll: onOpenNewsFeed,
            ),
          ],
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(
              title: 'Library',
              action: 'View all',
              onAction: onOpenAllDocuments,
            ),
          ),
          _LibraryList(
            categories: categories,
            iconFor: iconFor,
            onOpenCategory: onOpenCategory,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EditorialGreeting extends StatelessWidget {
  const _EditorialGreeting();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingFor(now).toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.mutedGold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Officer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(now),
                  style: DutyTheme.mono(
                    size: 12,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: colors.mutedGold, width: 1),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: colors.mutedGold,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime now) {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekday = weekdays[now.weekday - 1];
    final month = months[now.month - 1];
    return '$weekday  ·  ${now.day.toString().padLeft(2, '0')} $month ${now.year}';
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({this.margin = EdgeInsets.zero});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Container(
      height: 1,
      margin: margin,
      color: colors.hairline,
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
    final colors = Theme.of(context).extension<DutyColors>()!;
    final entries = <(_QuickActionData, VoidCallback)>[
      (const _QuickActionData(icon: Icons.event_outlined, label: 'Calendar'),
          onCalendar),
      (const _QuickActionData(icon: Icons.notes_outlined, label: 'Notes'),
          onNotes),
      (const _QuickActionData(icon: Icons.map_outlined, label: 'Map'), onMap),
      (const _QuickActionData(icon: Icons.search, label: 'Search'), onSearch),
    ];
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(
            child: _QuickAction(
              data: entries[i].$1,
              onTap: entries[i].$2,
            ),
          ),
          if (i < entries.length - 1)
            Container(
              width: 1,
              height: 38,
              color: colors.hairline,
            ),
        ],
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.data, required this.onTap});

  final _QuickActionData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 22, color: scheme.onSurface),
            const SizedBox(height: 6),
            Text(
              data.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WestOpsPreview extends StatelessWidget {
  const _WestOpsPreview({required this.onSelect});

  final void Function(WestOpsFeatureSpec) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: westOpsFeatureSpecs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final spec = westOpsFeatureSpecs[index];
          return _WestOpsTile(spec: spec, onTap: () => onSelect(spec));
        },
      ),
    );
  }
}

class _WestOpsTile extends StatelessWidget {
  const _WestOpsTile({required this.spec, required this.onTap});

  final WestOpsFeatureSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            border: Border.all(color: colors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(spec.icon, size: 18, color: spec.color),
                  const Spacer(),
                  Icon(
                    Icons.fiber_manual_record,
                    size: 8,
                    color: spec.color,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                spec.title.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                spec.subtitle,
                style: DutyTheme.mono(
                  size: 10,
                  color: colors.mutedGold,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.categories,
    required this.iconFor,
    required this.onOpenCategory,
  });

  final Map<String, List<PolicyDocument>> categories;
  final IconData Function(String) iconFor;
  final void Function(String category, List<PolicyDocument> docs)
      onOpenCategory;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final entries = categories.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i == 0) _Hairline(margin: EdgeInsets.zero),
          _LibraryRow(
            category: entries[i].key,
            count: entries[i].value.length,
            icon: iconFor(entries[i].key),
            onTap: () => onOpenCategory(entries[i].key, entries[i].value),
          ),
          Container(height: 1, color: colors.hairline),
        ],
      ],
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.category,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String category;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).extension<DutyColors>()!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colors.mutedGold),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
              ),
            ),
            Text(
              count.toString().padLeft(3, '0'),
              style: DutyTheme.mono(
                size: 13,
                color: colors.mutedGold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletDetailPane extends StatelessWidget {
  const _TabletDetailPane({
    required this.selection,
    required this.dashboard,
  });

  final _CategorySelection? selection;
  final Widget dashboard;

  @override
  Widget build(BuildContext context) {
    final current = selection;
    if (current == null) return dashboard;
    return DocumentListScreen(
      key: ValueKey('category:${current.category}'),
      title: current.category,
      documents: current.documents,
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
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.alertRed),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
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

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.categories,
    required this.totalDocumentCount,
    required this.selection,
    required this.iconFor,
    required this.onSelectAll,
    required this.onSelectCategory,
  });

  final Map<String, List<PolicyDocument>> categories;
  final int totalDocumentCount;
  final _CategorySelection? selection;
  final IconData Function(String) iconFor;
  final VoidCallback onSelectAll;
  final void Function(String category, List<PolicyDocument> docs)
      onSelectCategory;

  String? get _selectedCategory => selection?.category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final allSelected = _selectedCategory == 'All Documents';

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeading(title: 'Library'),
        ),
        _SidebarRow(
          label: 'All documents',
          count: totalDocumentCount,
          icon: Icons.library_books_outlined,
          selected: allSelected,
          onTap: onSelectAll,
        ),
        Container(height: 1, color: colors.hairline),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHeading(title: 'Categories'),
        ),
        for (final entry in categories.entries)
          _SidebarRow(
            label: entry.key,
            count: entry.value.length,
            icon: iconFor(entry.key),
            selected: _selectedCategory == entry.key,
            onTap: () => onSelectCategory(entry.key, entry.value),
          ),
        Container(height: 1, color: colors.hairline),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'JCF DUTY · LIBRARY',
            style: DutyTheme.mono(
              size: 10,
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.mutedGold),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ),
              Text(
                count.toString().padLeft(3, '0'),
                style: DutyTheme.mono(
                  size: 12,
                  color: colors.mutedGold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

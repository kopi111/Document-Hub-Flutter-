import 'package:flutter/material.dart';

import '../../models/document.dart';
import '../../services/github_service.dart';
import '../../theme/hub_style.dart';
import '../../widgets/editorial/shared_axis_route.dart';
import '../../widgets/hub/hub_category_card.dart';
import '../../widgets/hub/hub_filter_pill.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/notifications_bell.dart';
import '../document_list_screen.dart';
import '../pdf_viewer_screen.dart';
import '../search_results_screen.dart';

/// Visual identity for a document category: the tinted file icon used on the
/// "Recent Documents" cards and the "Browse by Category" grid.
class _CategoryStyle {
  const _CategoryStyle(this.icon, this.tint);

  final IconData icon;
  final HubTint tint;
}

const Map<String, _CategoryStyle> _categoryStyles = {
  'Force Orders': _CategoryStyle(Icons.shield_outlined, HubTint.blue),
  'JCF Policies': _CategoryStyle(Icons.gavel, HubTint.purple),
  'NPCJ': _CategoryStyle(Icons.school_outlined, HubTint.teal),
  'TMMD': _CategoryStyle(Icons.directions_car_outlined, HubTint.orange),
  'PMMD': _CategoryStyle(Icons.build_outlined, HubTint.blue),
  'CIB': _CategoryStyle(Icons.search, HubTint.purple),
  'PECC': _CategoryStyle(Icons.verified_outlined, HubTint.green),
  'PRDB': _CategoryStyle(Icons.analytics_outlined, HubTint.teal),
  'SOPs': _CategoryStyle(Icons.list_alt, HubTint.orange),
  'SIMU': _CategoryStyle(Icons.travel_explore, HubTint.blue),
  'CCN': _CategoryStyle(Icons.campaign_outlined, HubTint.green),
  'PMAS': _CategoryStyle(Icons.assignment_outlined, HubTint.purple),
  'FLPD': _CategoryStyle(Icons.local_police_outlined, HubTint.red),
  'FIPT': _CategoryStyle(Icons.fingerprint, HubTint.teal),
  'DWTT': _CategoryStyle(Icons.water_drop_outlined, HubTint.blue),
  'FIBUA': _CategoryStyle(Icons.location_city_outlined, HubTint.orange),
  'PPMU': _CategoryStyle(Icons.groups_outlined, HubTint.green),
  'ICTD': _CategoryStyle(Icons.computer_outlined, HubTint.purple),
  'ICT': _CategoryStyle(Icons.memory, HubTint.teal),
};

const _CategoryStyle _fallbackStyle =
    _CategoryStyle(Icons.folder_outlined, HubTint.blue);

_CategoryStyle _styleFor(String category) =>
    _categoryStyles[category] ?? _fallbackStyle;

/// Document feature landing in the Hub design language: a search row, category
/// filter pills, the most recent documents, a browse-by-category grid, and a
/// gradient knowledge-centre banner.
class DocumentsHomeScreen extends StatefulWidget {
  const DocumentsHomeScreen({super.key});

  @override
  State<DocumentsHomeScreen> createState() => _DocumentsHomeScreenState();
}

class _DocumentsHomeScreenState extends State<DocumentsHomeScreen> {
  static const int _recentLimit = 8;

  final GitHubService _service = GitHubService();

  List<PolicyDocument> _documents = const [];
  Map<String, List<PolicyDocument>> _categories = const {};
  bool _loading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final documents = await _service.fetchDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents;
        _categories = _service.groupByCategory(documents);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load documents: $error';
        _loading = false;
      });
    }
  }

  List<PolicyDocument> get _filteredDocuments {
    final category = _selectedCategory;
    if (category == null) return _documents;
    return _categories[category] ?? const [];
  }

  List<PolicyDocument> get _recentDocuments {
    final source = _filteredDocuments;
    return source.length <= _recentLimit
        ? source
        : source.sublist(0, _recentLimit);
  }

  void _selectCategory(String? category) =>
      setState(() => _selectedCategory = category);

  void _openSearch() {
    Navigator.push(
      context,
      sharedAxis(SearchResultsScreen(documents: _documents)),
    );
  }

  void _openAllDocuments() =>
      _openCategory('All Documents', _documents);

  void _openCategory(String title, List<PolicyDocument> documents) {
    Navigator.push(
      context,
      sharedAxis(DocumentListScreen(title: title, documents: documents)),
    );
  }

  void _openDocument(PolicyDocument document) {
    Navigator.push(context, sharedAxis(PdfViewerScreen(document: document)));
  }

  void _openRecentList() {
    final category = _selectedCategory;
    if (category == null) {
      _openAllDocuments();
      return;
    }
    _openCategory(category, _filteredDocuments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Document Library',
            showBack: true,
            actions: const [
              IconTheme(
                data: IconThemeData(color: HubStyle.onGradient),
                child: NotificationsBell(),
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
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchRow(onTap: _openSearch),
        ),
        const SizedBox(height: 14),
        _buildCategoryPills(),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(
            title: 'Recent Documents',
            actionLabel: 'View All',
            onAction: _openRecentList,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecentRow(),
        const SizedBox(height: 22),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HubSectionHeading(title: 'Browse by Category'),
        ),
        const SizedBox(height: 12),
        _buildCategoryGrid(),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _KnowledgeCenterBanner(
            documentCount: _documents.length,
            onBrowse: _openAllDocuments,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPills() {
    final pills = <Widget>[
      HubFilterPill(
        label: 'All',
        icon: Icons.dashboard_outlined,
        selected: _selectedCategory == null,
        onTap: () => _selectCategory(null),
      ),
      for (final category in _categories.keys)
        HubFilterPill(
          label: category,
          icon: _styleFor(category).icon,
          accent: _styleFor(category).tint.foreground,
          selected: _selectedCategory == category,
          onTap: () => _selectCategory(category),
        ),
    ];
    return HubFilterPillRow(children: pills);
  }

  Widget _buildRecentRow() {
    final recent = _recentDocuments;
    if (recent.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          'No documents in this category',
          style: TextStyle(color: HubStyle.textSecondary),
        ),
      );
    }
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recent.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final document = recent[index];
          return _RecentCard(
            document: document,
            onTap: () => _openDocument(document),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final entries = _categories.entries.toList();
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
          for (final entry in entries)
            HubCategoryCard(
              icon: _styleFor(entry.key).icon,
              title: entry.key,
              count: '${entry.value.length} docs',
              tint: _styleFor(entry.key).tint,
              selected: _selectedCategory == entry.key,
              onTap: () => _openCategory(entry.key, entry.value),
            ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HubStyle.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: HubStyle.cardShadow,
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: HubStyle.textSecondary),
              SizedBox(width: 10),
              Text(
                'Search documents...',
                style: TextStyle(
                  color: HubStyle.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.document, required this.onTap});

  final PolicyDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(document.category);
    final isPdf = document.name.endsWith('.pdf');
    return SizedBox(
      width: 184,
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
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.tint.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.description,
                      color: style.tint.foreground,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      document.displayName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: HubStyle.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    document.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.tint.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KnowledgeCenterBanner extends StatelessWidget {
  const _KnowledgeCenterBanner({
    required this.documentCount,
    required this.onBrowse,
  });

  final int documentCount;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(HubStyle.heroRadius),
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: HubStyle.headerGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Knowledge Center',
                          style: TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$documentCount documents available',
                          style: const TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Force orders, policies and standing procedures',
                          style: TextStyle(
                            color: HubStyle.onGradientMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _BrowsePill(onTap: onBrowse),
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

class _BrowsePill extends StatelessWidget {
  const _BrowsePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Browse Collection',
                  style: TextStyle(
                    color: HubStyle.onGradient,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 3),
              Icon(Icons.chevron_right, color: HubStyle.onGradient, size: 16),
            ],
          ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: HubStyle.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: HubStyle.textPrimary),
            ),
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

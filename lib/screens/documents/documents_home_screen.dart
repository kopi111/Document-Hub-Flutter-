import 'package:flutter/material.dart';

import '../../models/document.dart';
import '../../services/github_service.dart';
import '../../theme/jcf_palette.dart';
import '../document_list_screen.dart';
import '../search_results_screen.dart';

/// Document feature landing, modelled on the JCF Document Hub proposal:
/// a library summary, a "view all" shortcut, and a category grid.
class DocumentsHomeScreen extends StatefulWidget {
  const DocumentsHomeScreen({super.key});

  @override
  State<DocumentsHomeScreen> createState() => _DocumentsHomeScreenState();
}

class _DocumentsHomeScreenState extends State<DocumentsHomeScreen> {
  final GitHubService _service = GitHubService();

  List<PolicyDocument> _documents = const [];
  Map<String, List<PolicyDocument>> _categories = const {};
  bool _loading = true;
  String? _error;

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

  void _openAllDocuments() => _openCategory('All Documents', _documents);

  void _openCategory(String title, List<PolicyDocument> documents) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentListScreen(title: title, documents: documents),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(documents: _documents),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Hub'),
        actions: [
          if (!_loading && _error == null)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search documents',
              onPressed: _openSearch,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh library',
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final categories = _categories.entries.toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _SummaryRow(
            documentCount: _documents.length,
            categoryCount: _categories.length,
          ),
          const SizedBox(height: 18),
          _ViewAllButton(
            count: _documents.length,
            onPressed: _openAllDocuments,
          ),
          const SizedBox(height: 24),
          Text('Categories', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _CategoryGrid(
            categories: categories,
            onOpenCategory: _openCategory,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.documentCount, required this.categoryCount});

  final int documentCount;
  final int categoryCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.description_outlined,
            value: documentCount,
            label: 'Documents',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            icon: Icons.category_outlined,
            value: categoryCount,
            label: 'Categories',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: scheme.primary, size: 26),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  const _ViewAllButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.folder_copy_outlined),
        label: Text('View All Documents ($count)'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.onOpenCategory});

  final List<MapEntry<String, List<PolicyDocument>>> categories;
  final void Function(String, List<PolicyDocument>) onOpenCategory;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final entry = categories[index];
        return _CategoryCard(
          name: entry.key,
          count: entry.value.length,
          onTap: () => onOpenCategory(entry.key, entry.value),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.count,
    required this.onTap,
  });

  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: JcfPalette.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(_iconFor(name), color: JcfPalette.iconDefault, size: 28),
              const Spacer(),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count documents',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String category) {
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
            const Icon(Icons.error_outline, size: 48),
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

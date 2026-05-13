import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/document_cache_state.dart';
import '../services/document_cache_repository.dart';
import '../services/document_list_preferences.dart';
import '../widgets/breadcrumb_trail.dart';
import '../widgets/document_staleness_badge.dart';
import 'pdf_viewer_screen.dart';

class DocumentListScreen extends StatefulWidget {
  final String title;
  final List<PolicyDocument> documents;

  const DocumentListScreen({
    super.key,
    required this.title,
    required this.documents,
  });

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DocumentCacheRepository _cache = InMemoryDemoDocumentCache();
  final DocumentListPreferences _preferences = DocumentListPreferences();

  List<PolicyDocument> _visible = [];
  DocumentViewMode _viewMode = DocumentListPreferences.defaultViewMode;
  DocumentSortOrder _sortOrder = DocumentListPreferences.defaultSortOrder;

  @override
  void initState() {
    super.initState();
    _visible = _sorted(widget.documents, _sortOrder);
    _restorePreferences();
  }

  Future<void> _restorePreferences() async {
    final storedView = await _preferences.readViewMode();
    final storedSort = await _preferences.readSortOrder();
    if (!mounted) return;
    setState(() {
      _viewMode = storedView;
      _sortOrder = storedSort;
      _visible = _sorted(_visibleSource(), storedSort);
    });
  }

  List<PolicyDocument> _visibleSource() {
    final query = _searchController.text;
    if (query.isEmpty) return widget.documents;
    final lower = query.toLowerCase();
    return widget.documents
        .where((doc) => doc.displayName.toLowerCase().contains(lower))
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _visible = _sorted(_visibleSource(), _sortOrder);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _toggleViewMode() {
    final next = _viewMode == DocumentViewMode.list
        ? DocumentViewMode.grid
        : DocumentViewMode.list;
    setState(() => _viewMode = next);
    _preferences.writeViewMode(next);
  }

  void _selectSortOrder(DocumentSortOrder order) {
    setState(() {
      _sortOrder = order;
      _visible = _sorted(_visibleSource(), order);
    });
    _preferences.writeSortOrder(order);
  }

  void _openDocument(PolicyDocument doc) {
    _cache.recordOpened(doc);
    setState(() {
      _visible = _sorted(_visibleSource(), _sortOrder);
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(document: doc),
      ),
    );
  }

  List<PolicyDocument> _sorted(
    List<PolicyDocument> source,
    DocumentSortOrder order,
  ) {
    final copy = List<PolicyDocument>.from(source);
    switch (order) {
      case DocumentSortOrder.nameAsc:
        copy.sort((a, b) => a.displayName.compareTo(b.displayName));
        return copy;
      case DocumentSortOrder.nameDesc:
        copy.sort((a, b) => b.displayName.compareTo(a.displayName));
        return copy;
      case DocumentSortOrder.dateNewest:
        copy.sort(_compareNewestFirst);
        return copy;
      case DocumentSortOrder.dateOldest:
        copy.sort(_compareOldestFirst);
        return copy;
    }
  }

  int _compareNewestFirst(PolicyDocument a, PolicyDocument b) {
    final aDate = _cache.stateFor(a).cachedAt;
    final bDate = _cache.stateFor(b).cachedAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  }

  int _compareOldestFirst(PolicyDocument a, PolicyDocument b) {
    final aDate = _cache.stateFor(a).cachedAt;
    final bDate = _cache.stateFor(b).cachedAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return aDate.compareTo(bDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: Icon(_viewToggleIcon()),
            tooltip: _viewToggleTooltip(),
            onPressed: _toggleViewMode,
          ),
          PopupMenuButton<DocumentSortOrder>(
            tooltip: 'Sort documents',
            icon: const Icon(Icons.sort),
            onSelected: _selectSortOrder,
            itemBuilder: _buildSortMenuItems,
          ),
        ],
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments(context)),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildResultsHeader(),
          const SizedBox(height: 4),
          Expanded(child: _buildResultsBody()),
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
      BreadcrumbSegment(label: widget.title),
    ];
  }

  IconData _viewToggleIcon() {
    return _viewMode == DocumentViewMode.list
        ? Icons.grid_view
        : Icons.view_list;
  }

  String _viewToggleTooltip() {
    return _viewMode == DocumentViewMode.list
        ? 'Switch to grid view'
        : 'Switch to list view';
  }

  List<PopupMenuEntry<DocumentSortOrder>> _buildSortMenuItems(
    BuildContext context,
  ) {
    return [
      _sortMenuItem(DocumentSortOrder.nameAsc, 'Name (A to Z)'),
      _sortMenuItem(DocumentSortOrder.nameDesc, 'Name (Z to A)'),
      _sortMenuItem(DocumentSortOrder.dateNewest, 'Date (newest first)'),
      _sortMenuItem(DocumentSortOrder.dateOldest, 'Date (oldest first)'),
    ];
  }

  PopupMenuItem<DocumentSortOrder> _sortMenuItem(
    DocumentSortOrder order,
    String label,
  ) {
    final selected = _sortOrder == order;
    return PopupMenuItem<DocumentSortOrder>(
      value: order,
      child: Row(
        children: [
          Icon(
            selected ? Icons.check : Icons.check_box_outline_blank,
            size: 18,
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search in ${widget.title}...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear search',
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${_visible.length} documents',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_visible.isEmpty) {
      return const Center(child: Text('No documents found'));
    }
    return _viewMode == DocumentViewMode.list
        ? _buildListView()
        : _buildGridView();
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _visible.length,
      itemBuilder: (context, index) => _DocumentTile(
        document: _visible[index],
        cacheState: _cache.stateFor(_visible[index]),
        onOpen: _openDocument,
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _visible.length,
      itemBuilder: (context, index) => _DocumentGridCard(
        document: _visible[index],
        cacheState: _cache.stateFor(_visible[index]),
        onOpen: _openDocument,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.cacheState,
    required this.onOpen,
  });

  final PolicyDocument document;
  final DocumentCacheState cacheState;
  final void Function(PolicyDocument) onOpen;

  @override
  Widget build(BuildContext context) {
    final isPdf = document.name.endsWith('.pdf');
    final colors = Theme.of(context).colorScheme;
    final disabled = !cacheState.isOpenable;
    final subtitleText = disabled ? 'Not available offline' : document.category;

    return ListTile(
      enabled: !disabled,
      leading: CircleAvatar(
        backgroundColor: isPdf ? Colors.red.shade100 : Colors.blue.shade100,
        child: Icon(
          isPdf ? Icons.picture_as_pdf : Icons.description,
          color: isPdf ? Colors.red : Colors.blue,
        ),
      ),
      title: Text(
        document.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              subtitleText,
              style: TextStyle(
                color: disabled ? colors.onSurfaceVariant : null,
              ),
            ),
          ),
          DocumentStalenessBadge(state: cacheState),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: disabled ? null : () => onOpen(document),
    );
  }
}

class _DocumentGridCard extends StatelessWidget {
  const _DocumentGridCard({
    required this.document,
    required this.cacheState,
    required this.onOpen,
  });

  final PolicyDocument document;
  final DocumentCacheState cacheState;
  final void Function(PolicyDocument) onOpen;

  @override
  Widget build(BuildContext context) {
    final isPdf = document.name.endsWith('.pdf');
    final colors = Theme.of(context).colorScheme;
    final disabled = !cacheState.isOpenable;
    final captionText = disabled ? 'Not available offline' : document.category;

    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : () => onOpen(document),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor:
                        isPdf ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(
                      isPdf ? Icons.picture_as_pdf : Icons.description,
                      color: isPdf ? Colors.red : Colors.blue,
                    ),
                  ),
                  DocumentStalenessBadge(state: cacheState),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  document.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                captionText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

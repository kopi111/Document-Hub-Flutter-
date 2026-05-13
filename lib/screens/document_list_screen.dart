import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/document_cache_state.dart';
import '../services/document_cache_repository.dart';
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
  List<PolicyDocument> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.documents;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.documents;
      } else {
        final lower = query.toLowerCase();
        _filtered = widget.documents
            .where((d) => d.displayName.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  void _openDocument(PolicyDocument doc) {
    _cache.recordOpened(doc);
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(document: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search in ${widget.title}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} documents',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No documents found'))
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => _DocumentTile(
                      document: _filtered[index],
                      cacheState: _cache.stateFor(_filtered[index]),
                      onOpen: _openDocument,
                    ),
                  ),
          ),
        ],
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

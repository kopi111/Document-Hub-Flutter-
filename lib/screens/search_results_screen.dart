import 'package:flutter/material.dart';
import '../models/document.dart';
import 'pdf_viewer_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final List<PolicyDocument> documents;

  const SearchResultsScreen({super.key, required this.documents});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PolicyDocument> _results = [];

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = [];
      } else {
        final lower = query.toLowerCase();
        _results = widget.documents
            .where((d) => d.displayName.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  void _openDocument(PolicyDocument doc) {
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
        title: TextField(
          controller: _searchController,
          onChanged: _search,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search all documents...',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                _search('');
              },
            ),
        ],
      ),
      body: _searchController.text.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Type to search documents'),
                ],
              ),
            )
          : _results.isEmpty
              ? const Center(child: Text('No documents found'))
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final doc = _results[index];
                    final isPdf = doc.name.endsWith('.pdf');
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPdf
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          isPdf ? Icons.picture_as_pdf : Icons.description,
                          color: isPdf ? Colors.red : Colors.blue,
                        ),
                      ),
                      title: Text(
                        doc.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(doc.category),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openDocument(doc),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

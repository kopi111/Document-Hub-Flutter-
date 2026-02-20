import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/document.dart';

class GitHubService {
  static const String _owner = 'kopi111';
  static const String _repo = 'JCF-Documents';
  static const String _apiBase = 'https://api.github.com';

  List<PolicyDocument> _cachedDocuments = [];

  Future<List<PolicyDocument>> fetchDocuments() async {
    if (_cachedDocuments.isNotEmpty) return _cachedDocuments;

    final documents = <PolicyDocument>[];

    try {
      // Use Trees API - handles large directories without truncation
      final treeUrl = Uri.parse(
          '$_apiBase/repos/$_owner/$_repo/git/trees/main?recursive=1');
      final treeResponse = await http.get(treeUrl, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (treeResponse.statusCode == 200) {
        final data = json.decode(treeResponse.body);
        final List<dynamic> tree = data['tree'];
        for (final item in tree) {
          final path = item['path'] as String;
          if (path.startsWith('policies/') &&
              (path.endsWith('.pdf') || path.endsWith('.docx'))) {
            final name = path.split('/').last;
            // Properly encode the filename for the raw URL
            final encodedPath = path
                .split('/')
                .map((segment) => Uri.encodeComponent(segment))
                .join('/');
            final downloadUrl =
                'https://raw.githubusercontent.com/$_owner/$_repo/main/$encodedPath';
            documents.add(PolicyDocument(
              name: name,
              displayName:
                  name.replaceAll('.pdf', '').replaceAll('.docx', ''),
              category: PolicyDocument.categorize(name),
              downloadUrl: downloadUrl,
            ));
          }
        }
      } else {
        // Fallback: contents API
        final url = Uri.parse(
            '$_apiBase/repos/$_owner/$_repo/contents/policies');
        final response = await http.get(url, headers: {
          'Accept': 'application/vnd.github.v3+json',
        });

        if (response.statusCode == 200) {
          final List<dynamic> items = json.decode(response.body);
          for (final item in items) {
            final name = item['name'] as String;
            if (name.endsWith('.pdf') || name.endsWith('.docx')) {
              documents.add(PolicyDocument.fromGitHub(item));
            }
          }
        }
      }
    } catch (e) {
      rethrow;
    }

    documents.sort((a, b) => a.displayName.compareTo(b.displayName));
    _cachedDocuments = documents;
    return documents;
  }

  Map<String, List<PolicyDocument>> groupByCategory(
      List<PolicyDocument> documents) {
    final map = <String, List<PolicyDocument>>{};
    for (final doc in documents) {
      map.putIfAbsent(doc.category, () => []).add(doc);
    }
    final sorted = Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length)),
    );
    return sorted;
  }

  List<PolicyDocument> search(List<PolicyDocument> documents, String query) {
    if (query.isEmpty) return documents;
    final lower = query.toLowerCase();
    return documents
        .where((doc) => doc.displayName.toLowerCase().contains(lower))
        .toList();
  }
}

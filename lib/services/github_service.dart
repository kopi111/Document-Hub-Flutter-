import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/document.dart';

class GitHubService {
  static const String _owner = 'kopi111';
  static const String _repo = 'JCF-Documents';
  static const String _apiBase = 'https://api.github.com';
  static const String _diskKey = 'github_documents_cache_v1';
  static const String _diskTimestampKey = 'github_documents_cached_at_v1';
  static const Duration _cacheTtl = Duration(hours: 1);

  static List<PolicyDocument> _sessionCache = const [];
  static DateTime? _cachedAt;
  static Future<List<PolicyDocument>>? _inflight;

  Future<List<PolicyDocument>> fetchDocuments() async {
    if (_sessionCache.isNotEmpty && _isFresh(_cachedAt)) return _sessionCache;

    final disk = await _readDiskCache();
    if (disk != null) {
      _sessionCache = disk.documents;
      _cachedAt = disk.cachedAt;
      if (_isFresh(disk.cachedAt)) {
        unawaited(_revalidate());
        return _sessionCache;
      }
    }

    return _refresh();
  }

  Future<List<PolicyDocument>> _refresh() {
    final inflight = _inflight;
    if (inflight != null) return inflight;
    final fetch = _fetchFromGitHub().then((documents) {
      _sessionCache = documents;
      _cachedAt = DateTime.now();
      unawaited(_writeDiskCache(documents, _cachedAt!));
      _inflight = null;
      return documents;
    }, onError: (error, stack) {
      _inflight = null;
      throw error;
    });
    _inflight = fetch;
    return fetch;
  }

  Future<void> _revalidate() async {
    try {
      await _refresh();
    } catch (_) {
      // Background revalidation; failure leaves the existing cache intact.
    }
  }

  bool _isFresh(DateTime? cachedAt) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < _cacheTtl;
  }

  Future<List<PolicyDocument>> _fetchFromGitHub() async {
    final treeUrl = Uri.parse(
      '$_apiBase/repos/$_owner/$_repo/git/trees/main?recursive=1',
    );
    final treeResponse = await http.get(treeUrl, headers: {
      'Accept': 'application/vnd.github.v3+json',
    });
    if (treeResponse.statusCode == 200) {
      return _parseTreeResponse(treeResponse.body);
    }
    return _fetchViaContentsApi();
  }

  List<PolicyDocument> _parseTreeResponse(String body) {
    final documents = <PolicyDocument>[];
    final data = json.decode(body) as Map<String, dynamic>;
    final tree = data['tree'] as List<dynamic>? ?? const [];
    for (final item in tree) {
      final path = item['path'] as String;
      if (!path.startsWith('policies/')) continue;
      if (!path.endsWith('.pdf') && !path.endsWith('.docx')) continue;
      final name = path.split('/').last;
      final encodedPath = path
          .split('/')
          .map(Uri.encodeComponent)
          .join('/');
      documents.add(PolicyDocument(
        name: name,
        displayName: name.replaceAll('.pdf', '').replaceAll('.docx', ''),
        category: PolicyDocument.categorize(name),
        downloadUrl:
            'https://raw.githubusercontent.com/$_owner/$_repo/main/$encodedPath',
      ));
    }
    documents.sort((a, b) => a.displayName.compareTo(b.displayName));
    return documents;
  }

  Future<List<PolicyDocument>> _fetchViaContentsApi() async {
    final url =
        Uri.parse('$_apiBase/repos/$_owner/$_repo/contents/policies');
    final response = await http.get(url, headers: {
      'Accept': 'application/vnd.github.v3+json',
    });
    if (response.statusCode != 200) return const [];
    final items = json.decode(response.body) as List<dynamic>;
    final documents = <PolicyDocument>[];
    for (final item in items) {
      final name = item['name'] as String;
      if (name.endsWith('.pdf') || name.endsWith('.docx')) {
        documents
            .add(PolicyDocument.fromGitHub(item as Map<String, dynamic>));
      }
    }
    documents.sort((a, b) => a.displayName.compareTo(b.displayName));
    return documents;
  }

  Future<_DiskCache?> _readDiskCache() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_diskKey);
    final timestamp = preferences.getInt(_diskTimestampKey);
    if (raw == null || timestamp == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    final documents = decoded
        .map((entry) =>
            _decodePersisted(entry as Map<String, dynamic>))
        .toList(growable: false);
    return _DiskCache(
      documents: documents,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }

  Future<void> _writeDiskCache(
    List<PolicyDocument> documents,
    DateTime cachedAt,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(documents.map(_encodePersisted).toList());
    await preferences.setString(_diskKey, encoded);
    await preferences.setInt(_diskTimestampKey, cachedAt.millisecondsSinceEpoch);
  }

  Map<String, dynamic> _encodePersisted(PolicyDocument document) => {
        'name': document.name,
        'displayName': document.displayName,
        'category': document.category,
        'downloadUrl': document.downloadUrl,
      };

  PolicyDocument _decodePersisted(Map<String, dynamic> json) => PolicyDocument(
        name: json['name'] as String,
        displayName: json['displayName'] as String,
        category: json['category'] as String,
        downloadUrl: json['downloadUrl'] as String,
      );

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

class _DiskCache {
  final List<PolicyDocument> documents;
  final DateTime cachedAt;

  const _DiskCache({required this.documents, required this.cachedAt});
}

enum DocumentSortField { name, lastModified }

enum SortDirection { ascending, descending }

enum AccessEventType {
  view,
  download,
  search,
  login,
  logout,
  failedAuth,
  accessDenied,
}

extension AccessEventTypeWire on AccessEventType {
  String get wireValue {
    switch (this) {
      case AccessEventType.view:
        return 'VIEW';
      case AccessEventType.download:
        return 'DOWNLOAD';
      case AccessEventType.search:
        return 'SEARCH';
      case AccessEventType.login:
        return 'LOGIN';
      case AccessEventType.logout:
        return 'LOGOUT';
      case AccessEventType.failedAuth:
        return 'FAILED_AUTH';
      case AccessEventType.accessDenied:
        return 'ACCESS_DENIED';
    }
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.hasMore,
  });

  static PaginatedResponse<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decodeItem,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    return PaginatedResponse<T>(
      items: rawItems
          .map((item) => decodeItem(item as Map<String, dynamic>))
          .toList(growable: false),
      page: (json['page'] as int?) ?? 1,
      pageSize: (json['page_size'] as int?) ?? rawItems.length,
      totalItems: (json['total_items'] as int?) ?? rawItems.length,
      hasMore: (json['has_more'] as bool?) ?? false,
    );
  }
}

class CategorySummary {
  final String id;
  final String name;
  final int documentCount;

  const CategorySummary({
    required this.id,
    required this.name,
    required this.documentCount,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      documentCount: (json['document_count'] as int?) ?? 0,
    );
  }
}

class DocumentSummary {
  final String id;
  final String title;
  final String categoryId;
  final int sizeInBytes;
  final DateTime lastModified;

  const DocumentSummary({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.sizeInBytes,
    required this.lastModified,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) {
    return DocumentSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['category_id'] as String,
      sizeInBytes: (json['size_bytes'] as int?) ?? 0,
      lastModified: DateTime.parse(json['last_modified'] as String),
    );
  }
}

class DocumentMetadata {
  final String id;
  final String title;
  final String categoryId;
  final int sizeInBytes;
  final DateTime lastModified;
  final String sha256;
  final int version;

  const DocumentMetadata({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.sizeInBytes,
    required this.lastModified,
    required this.sha256,
    required this.version,
  });

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['category_id'] as String,
      sizeInBytes: (json['size_bytes'] as int?) ?? 0,
      lastModified: DateTime.parse(json['last_modified'] as String),
      sha256: json['sha256'] as String,
      version: (json['version'] as int?) ?? 1,
    );
  }
}

class DocumentSearchHit {
  final String documentId;
  final String title;
  final String categoryName;
  final String excerpt;

  const DocumentSearchHit({
    required this.documentId,
    required this.title,
    required this.categoryName,
    required this.excerpt,
  });

  factory DocumentSearchHit.fromJson(Map<String, dynamic> json) {
    return DocumentSearchHit(
      documentId: json['document_id'] as String,
      title: json['title'] as String,
      categoryName: json['category_name'] as String,
      excerpt: (json['excerpt'] as String?) ?? '',
    );
  }
}

class SyncManifestEntry {
  final String documentId;
  final String sha256;
  final int version;

  const SyncManifestEntry({
    required this.documentId,
    required this.sha256,
    required this.version,
  });

  factory SyncManifestEntry.fromJson(Map<String, dynamic> json) {
    return SyncManifestEntry(
      documentId: json['document_id'] as String,
      sha256: json['sha256'] as String,
      version: (json['version'] as int?) ?? 1,
    );
  }
}

class SyncManifest {
  final DateTime generatedAt;
  final List<SyncManifestEntry> entries;

  const SyncManifest({required this.generatedAt, required this.entries});

  factory SyncManifest.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? <dynamic>[];
    return SyncManifest(
      generatedAt: DateTime.parse(json['generated_at'] as String),
      entries: rawEntries
          .map((entry) =>
              SyncManifestEntry.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class ByteRange {
  final int start;
  final int? endInclusive;

  const ByteRange({required this.start, this.endInclusive});

  String toHeaderValue() {
    if (endInclusive == null) return 'bytes=$start-';
    return 'bytes=$start-$endInclusive';
  }
}

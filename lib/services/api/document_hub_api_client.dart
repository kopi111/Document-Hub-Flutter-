import 'dart:typed_data';

import 'api_models.dart';

abstract class DocumentHubApiClient {
  Future<PaginatedResponse<CategorySummary>> listCategories({
    int page = 1,
    int pageSize = 50,
  });

  Future<PaginatedResponse<DocumentSummary>> listDocumentsInCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 50,
    DocumentSortField sortField = DocumentSortField.name,
    SortDirection direction = SortDirection.ascending,
  });

  Future<List<DocumentSearchHit>> searchDocuments(String query);

  Future<DocumentMetadata> documentMetadata(String documentId);

  Future<Uint8List> documentContent(String documentId, {ByteRange? range});

  Future<Uint8List> documentThumbnail(String documentId);

  Future<SyncManifest> syncManifest();

  Future<void> recordAccess(String documentId, AccessEventType eventType);
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'api_models.dart';
import 'document_hub_api_client.dart';
import 'token_provider.dart';

typedef ApiDeprecatedCallback = void Function(String message);

class HttpDocumentHubApiClient implements DocumentHubApiClient {
  final ApiConfig _config;
  final TokenProvider _tokenProvider;
  final http.Client _httpClient;
  final ApiDeprecatedCallback? _onApiDeprecated;
  final Future<void> Function(Duration) _delay;

  HttpDocumentHubApiClient({
    ApiConfig config = const ApiConfig(),
    TokenProvider tokenProvider = const NullTokenProvider(),
    http.Client? httpClient,
    ApiDeprecatedCallback? onApiDeprecated,
    Future<void> Function(Duration)? delay,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _httpClient = httpClient ?? http.Client(),
        _onApiDeprecated = onApiDeprecated,
        _delay = delay ?? Future.delayed;

  @override
  Future<PaginatedResponse<CategorySummary>> listCategories({
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = _resolve('/categories', {'page': '$page', 'page_size': '$pageSize'});
    final body = await _getJson(uri);
    return PaginatedResponse.fromJson(body, CategorySummary.fromJson);
  }

  @override
  Future<PaginatedResponse<DocumentSummary>> listDocumentsInCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 50,
    DocumentSortField sortField = DocumentSortField.name,
    SortDirection direction = SortDirection.ascending,
  }) async {
    final uri = _resolve('/categories/$categoryId/documents', {
      'page': '$page',
      'page_size': '$pageSize',
      'sort': _wireSortField(sortField),
      'order': _wireDirection(direction),
    });
    final body = await _getJson(uri);
    return PaginatedResponse.fromJson(body, DocumentSummary.fromJson);
  }

  @override
  Future<List<DocumentSearchHit>> searchDocuments(String query) async {
    final uri = _resolve('/documents/search', {'q': query});
    final body = await _getJson(uri);
    final rawHits = body['hits'] as List<dynamic>? ?? <dynamic>[];
    return rawHits
        .map((hit) => DocumentSearchHit.fromJson(hit as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<DocumentMetadata> documentMetadata(String documentId) async {
    final uri = _resolve('/documents/$documentId/metadata');
    final body = await _getJson(uri);
    return DocumentMetadata.fromJson(body);
  }

  @override
  Future<Uint8List> documentContent(
    String documentId, {
    ByteRange? range,
  }) async {
    final uri = _resolve('/documents/$documentId/content');
    final extraHeaders = range == null ? null : {'Range': range.toHeaderValue()};
    final response = await _send(uri, extraHeaders: extraHeaders);
    return response.bodyBytes;
  }

  @override
  Future<Uint8List> documentThumbnail(String documentId) async {
    final uri = _resolve('/documents/$documentId/thumbnail');
    final response = await _send(uri);
    return response.bodyBytes;
  }

  @override
  Future<SyncManifest> syncManifest() async {
    final uri = _resolve('/sync/manifest');
    final body = await _getJson(uri);
    return SyncManifest.fromJson(body);
  }

  @override
  Future<void> recordAccess(String documentId, AccessEventType eventType) async {
    final uri = _resolve('/audit/access');
    final payload = jsonEncode({
      'document_id': documentId,
      'event_type': eventType.wireValue,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    final headers = await _buildHeaders(extra: {'Content-Type': 'application/json'});
    final response = await _execute(
      () => _httpClient.post(uri, headers: headers, body: payload),
      retries: _config.rateLimitRetries,
    );
    _throwForStatus(response);
  }

  Uri _resolve(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _send(uri);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<http.Response> _send(Uri uri, {Map<String, String>? extraHeaders}) async {
    final headers = await _buildHeaders(extra: extraHeaders);
    final response = await _execute(
      () => _httpClient.get(uri, headers: headers),
      retries: _config.rateLimitRetries,
    );
    _throwForStatus(response);
    return response;
  }

  Future<http.Response> _execute(
    Future<http.Response> Function() request, {
    required int retries,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(_config.timeout);
    } on SocketException catch (error) {
      throw NetworkException('Network unreachable: ${error.message}');
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } on http.ClientException catch (error) {
      throw NetworkException(error.message);
    }
    _checkDeprecation(response);
    if (response.statusCode == 429 && retries > 0) {
      final retryAfter = _parseRetryAfter(response.headers['retry-after']);
      await _delay(retryAfter);
      return _execute(request, retries: retries - 1);
    }
    return response;
  }

  Future<Map<String, String>> _buildHeaders({Map<String, String>? extra}) async {
    final token = await _tokenProvider.currentAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  void _checkDeprecation(http.Response response) {
    final flag = response.headers['x-api-deprecated'];
    if (flag == null) return;
    if (flag.toLowerCase() != 'true') return;
    final sunset = response.headers['sunset'];
    final message = sunset == null
        ? 'API version deprecated; please update the app.'
        : 'API version deprecated; sunset $sunset.';
    _onApiDeprecated?.call(message);
  }

  Duration _parseRetryAfter(String? header) {
    if (header == null) return _config.fallbackRetryDelayWhenHeaderMissing;
    final seconds = int.tryParse(header);
    if (seconds != null) return Duration(seconds: seconds);
    return _config.fallbackRetryDelayWhenHeaderMissing;
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final envelope = _parseErrorEnvelope(response);
    final code = envelope.errorCode;
    final id = envelope.requestId;
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(envelope.message, errorCode: code, requestId: id);
      case 401:
        throw UnauthorizedException(envelope.message, errorCode: code, requestId: id);
      case 403:
        throw ForbiddenException(envelope.message, errorCode: code, requestId: id);
      case 404:
        throw NotFoundException(envelope.message, errorCode: code, requestId: id);
      case 429:
        throw RateLimitedException(
          envelope.message,
          _parseRetryAfter(response.headers['retry-after']),
          errorCode: code,
          requestId: id,
        );
      default:
        if (response.statusCode >= 500) {
          throw ServerException(envelope.message, errorCode: code, requestId: id);
        }
        throw ApiException(envelope.message, errorCode: code, requestId: id);
    }
  }

  _ErrorEnvelope _parseErrorEnvelope(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return _ErrorEnvelope(
          message: (body['message'] as String?) ??
              'HTTP ${response.statusCode}',
          errorCode: body['error'] as String?,
          requestId: body['request_id'] as String?,
        );
      }
    } catch (_) {
      // fall through to default envelope
    }
    return _ErrorEnvelope(message: 'HTTP ${response.statusCode}');
  }

  String _wireSortField(DocumentSortField field) {
    switch (field) {
      case DocumentSortField.name:
        return 'name';
      case DocumentSortField.lastModified:
        return 'date';
    }
  }

  String _wireDirection(SortDirection direction) {
    switch (direction) {
      case SortDirection.ascending:
        return 'asc';
      case SortDirection.descending:
        return 'desc';
    }
  }
}

class _ErrorEnvelope {
  final String message;
  final String? errorCode;
  final String? requestId;

  const _ErrorEnvelope({required this.message, this.errorCode, this.requestId});
}

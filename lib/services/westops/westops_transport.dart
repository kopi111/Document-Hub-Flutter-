import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import '../api/api_exception.dart';
import '../api/token_provider.dart';

/// Thin JSON-over-HTTP helper shared by the WestOps repositories.
///
/// It resolves paths against [ApiConfig.baseUrl], attaches the bearer token
/// from [TokenProvider] when one is available, and translates non-2xx
/// responses into the typed [ApiException] family so callers handle failures
/// the same way regardless of which endpoint they hit.
class WestopsTransport {
  final http.Client _httpClient;
  final ApiConfig _config;
  final TokenProvider _tokenProvider;

  WestopsTransport({
    required ApiConfig config,
    required TokenProvider tokenProvider,
    required http.Client httpClient,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _httpClient = httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, [
    Map<String, String>? params,
  ]) async {
    final uri = _resolve(path, params);
    final response = await _httpClient.get(uri, headers: await _headers());
    _throwIfError(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _resolve(path);
    final response = await _httpClient.post(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(body),
    );
    _throwIfError(response);
    if (response.bodyBytes.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _resolve(path);
    final response = await _httpClient.put(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(body),
    );
    _throwIfError(response);
    if (response.bodyBytes.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> deleteResource(String path) async {
    final uri = _resolve(path);
    final response =
        await _httpClient.delete(uri, headers: await _headers());
    _throwIfError(response);
  }

  Uri _resolve(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
  }

  Future<Map<String, String>> _headers({bool withContentType = false}) async {
    final token = await _tokenProvider.currentAccessToken();
    return {
      'Accept': 'application/json',
      if (withContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message;
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      message = (body['message'] as String?) ?? 'HTTP ${response.statusCode}';
    } catch (_) {
      message = 'HTTP ${response.statusCode}';
    }
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      default:
        if (response.statusCode >= 500) throw ServerException(message);
        throw ApiException(message);
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api/api_config.dart';
import 'auth_service.dart';
import 'session.dart';

class HttpAuthService implements AuthService {
  final ApiConfig _config;
  final Session _session;
  final http.Client _httpClient;

  HttpAuthService({
    ApiConfig config = const ApiConfig(),
    required Session session,
    http.Client? httpClient,
  })  : _config = config,
        _session = session,
        _httpClient = httpClient ?? http.Client();

  @override
  Future<AuthSession> signIn(String username, String password) async {
    final uri = _resolve('/auth/login');
    final payload = jsonEncode({'username': username, 'password': password});
    final http.Response response;
    try {
      response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: payload,
          )
          .timeout(_config.timeout);
    } on SocketException catch (e) {
      throw AuthException('Network unreachable: ${e.message}');
    } on TimeoutException {
      throw AuthException('Sign-in request timed out.');
    } on http.ClientException catch (e) {
      throw AuthException(e.message);
    }
    _throwForStatus(response);
    final session = _parseSession(_decodeBody(response));
    _session.store(session);
    return session;
  }

  @override
  Future<void> signOut() async => _session.clear();

  @override
  AuthSession? get current => _session.current;

  Uri _resolve(String path) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(path: '${base.path}$path');
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const AuthException('Unexpected response from sign-in server.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('Unexpected response from sign-in server.');
    }
    return decoded;
  }

  void _throwForStatus(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException('Invalid username or password.');
    }
    throw AuthException('Sign-in failed (HTTP ${response.statusCode}).');
  }

  AuthSession _parseSession(Map<String, dynamic> json) {
    final token =
        json['token'] as String? ?? json['access_token'] as String?;
    if (token == null) throw const AuthException('Server response missing token.');
    return AuthSession(
      token: token,
      displayName: (json['display_name'] as String?) ??
          (json['username'] as String?) ??
          '',
      username: (json['username'] as String?) ?? '',
      rank: json['rank'] as String?,
      station: json['station'] as String?,
      email: json['email'] as String?,
    );
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/token_provider.dart';
import 'auth_service.dart';

/// Holds the signed-in officer for the app session and **persists it** to local
/// storage, so a relaunch (or browser refresh) restores the login instead of
/// forcing a fresh sign-in. Acts as the [TokenProvider] for API clients.
class Session implements TokenProvider {
  /// App-wide session populated by the front-page sign-in and reused everywhere
  /// (e.g. chat) so the officer authenticates once per launch.
  static final Session shared = Session();

  static const _storageKey = 'auth_session_v1';

  AuthSession? _current;

  AuthSession? get current => _current;

  bool get isAuthenticated => _current != null;

  /// Loads any persisted session into memory. Call once at startup before
  /// deciding whether to show the login screen.
  Future<AuthSession?> restore() async {
    if (_current != null) return _current;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = AuthSession.fromJson(json);
      if (session.token.isEmpty) return null;
      _current = session;
      return session;
    } catch (_) {
      await preferences.remove(_storageKey);
      return null;
    }
  }

  void store(AuthSession session) {
    _current = session;
    _persist(session);
  }

  void clear() {
    _current = null;
    _clearPersisted();
  }

  Future<void> _persist(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(session.toJson()));
  }

  Future<void> _clearPersisted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @override
  Future<String?> currentAccessToken() async => _current?.token;
}

class AuthSession {
  final String token;
  final String displayName;
  final String username;
  final String? rank;
  final String? station;

  const AuthSession({
    required this.token,
    required this.displayName,
    required this.username,
    this.rank,
    this.station,
  });
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

abstract class AuthService {
  Future<AuthSession> signIn(String username, String password);
  Future<void> signOut();
  AuthSession? get current;
}

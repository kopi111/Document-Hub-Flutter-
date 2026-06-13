class AuthSession {
  final String token;
  final String displayName;
  final String username;
  final String? rank;
  final String? station;
  final String? email;

  const AuthSession({
    required this.token,
    required this.displayName,
    required this.username,
    this.rank,
    this.station,
    this.email,
  });

  Map<String, dynamic> toJson() => {
        'token': token,
        'display_name': displayName,
        'username': username,
        if (rank != null) 'rank': rank,
        if (station != null) 'station': station,
        if (email != null) 'email': email,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        username: json['username'] as String? ?? '',
        rank: json['rank'] as String?,
        station: json['station'] as String?,
        email: json['email'] as String?,
      );
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

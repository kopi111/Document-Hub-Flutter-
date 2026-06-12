import '../api/token_provider.dart';
import 'auth_service.dart';

class Session implements TokenProvider {
  AuthSession? _current;

  AuthSession? get current => _current;

  void store(AuthSession session) {
    _current = session;
  }

  void clear() {
    _current = null;
  }

  @override
  Future<String?> currentAccessToken() async => _current?.token;
}

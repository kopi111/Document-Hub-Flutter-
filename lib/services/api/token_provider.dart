abstract class TokenProvider {
  Future<String?> currentAccessToken();
}

class NullTokenProvider implements TokenProvider {
  const NullTokenProvider();

  @override
  Future<String?> currentAccessToken() async => null;
}

class StaticTokenProvider implements TokenProvider {
  final String token;

  const StaticTokenProvider(this.token);

  @override
  Future<String?> currentAccessToken() async => token;
}

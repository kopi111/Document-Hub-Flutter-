class ApiConfig {
  /// Production gateway base URL. Used once the API is deployed behind the JCF
  /// domain; kept as a named fallback while local testing points elsewhere.
  static const String productionBaseUrl = 'https://api.jcf.gov.jm/v1';

  /// Local development API. Default while wiring chat against the backend
  /// running on the workstation.
  static const String localBaseUrl = 'http://localhost:5070/v1';

  static const String defaultBaseUrl = localBaseUrl;
  static const int maxRateLimitRetries = 1;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration fallbackRetryDelay = Duration(seconds: 5);

  final String baseUrl;
  final Duration timeout;
  final int rateLimitRetries;
  final Duration fallbackRetryDelayWhenHeaderMissing;

  const ApiConfig({
    this.baseUrl = defaultBaseUrl,
    this.timeout = requestTimeout,
    this.rateLimitRetries = maxRateLimitRetries,
    this.fallbackRetryDelayWhenHeaderMissing = fallbackRetryDelay,
  });
}

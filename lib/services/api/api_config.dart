class ApiConfig {
  static const String placeholderBaseUrl = 'https://api.jcf.gov.jm/v1';
  static const int maxRateLimitRetries = 1;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration fallbackRetryDelay = Duration(seconds: 5);

  final String baseUrl;
  final Duration timeout;
  final int rateLimitRetries;
  final Duration fallbackRetryDelayWhenHeaderMissing;

  const ApiConfig({
    this.baseUrl = placeholderBaseUrl,
    this.timeout = requestTimeout,
    this.rateLimitRetries = maxRateLimitRetries,
    this.fallbackRetryDelayWhenHeaderMissing = fallbackRetryDelay,
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:document_hub/services/api/api_config.dart';
import 'package:document_hub/services/api/api_exception.dart';
import 'package:document_hub/services/api/http_document_hub_api_client.dart';
import 'package:document_hub/services/api/token_provider.dart';

void main() {
  group('HttpDocumentHubApiClient', () {
    test('retries once on HTTP 429 honouring Retry-After', () async {
      final delays = <Duration>[];
      var attempt = 0;

      final mockClient = MockClient((request) async {
        attempt += 1;
        if (attempt == 1) {
          return http.Response(
            jsonEncode({'error': 'rate_limited', 'message': 'Too many'}),
            429,
            headers: {'retry-after': '2', 'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'items': [], 'page': 1, 'page_size': 50, 'total_items': 0}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = HttpDocumentHubApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test/v1'),
        tokenProvider: const StaticTokenProvider('test-token'),
        httpClient: mockClient,
        delay: (duration) async {
          delays.add(duration);
        },
      );

      final result = await client.listCategories();

      expect(attempt, 2);
      expect(delays, [const Duration(seconds: 2)]);
      expect(result.items, isEmpty);
    });

    test('throws RateLimitedException after retries are exhausted', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'rate_limited', 'message': 'Too many'}),
          429,
          headers: {'retry-after': '1', 'content-type': 'application/json'},
        );
      });

      final client = HttpDocumentHubApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test/v1'),
        tokenProvider: const StaticTokenProvider('test-token'),
        httpClient: mockClient,
        delay: (_) async {},
      );

      expect(
        client.listCategories(),
        throwsA(isA<RateLimitedException>()),
      );
    });

    test('attaches Authorization header from token provider', () async {
      String? observedAuthorization;

      final mockClient = MockClient((request) async {
        observedAuthorization = request.headers['authorization'];
        return http.Response(
          jsonEncode({'items': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = HttpDocumentHubApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test/v1'),
        tokenProvider: const StaticTokenProvider('my-token'),
        httpClient: mockClient,
        delay: (_) async {},
      );

      await client.listCategories();

      expect(observedAuthorization, 'Bearer my-token');
    });

    test('parses error envelope into typed UnauthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'invalid_token',
            'message': 'Token expired',
            'request_id': 'req-123',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = HttpDocumentHubApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test/v1'),
        tokenProvider: const StaticTokenProvider('expired-token'),
        httpClient: mockClient,
        delay: (_) async {},
      );

      try {
        await client.documentMetadata('doc-1');
        fail('Expected UnauthorizedException');
      } on UnauthorizedException catch (error) {
        expect(error.message, 'Token expired');
        expect(error.errorCode, 'invalid_token');
        expect(error.requestId, 'req-123');
      }
    });

    test('fires onApiDeprecated callback when X-Api-Deprecated header is set', () async {
      final notifications = <String>[];

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'items': []}),
          200,
          headers: {
            'content-type': 'application/json',
            'x-api-deprecated': 'true',
            'sunset': 'Wed, 1 Aug 2026 00:00:00 GMT',
          },
        );
      });

      final client = HttpDocumentHubApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test/v1'),
        tokenProvider: const StaticTokenProvider('test-token'),
        httpClient: mockClient,
        onApiDeprecated: notifications.add,
        delay: (_) async {},
      );

      await client.listCategories();

      expect(notifications, hasLength(1));
      expect(notifications.single, contains('Wed, 1 Aug 2026'));
    });
  });
}

// QA suite for the JCF Document Hub auth/session layer.
// Owner: senior QA. Touches no app source; exercises the real public APIs.

import 'dart:convert';

import 'package:document_hub/services/api/api_config.dart';
import 'package:document_hub/services/api/token_provider.dart';
import 'package:document_hub/services/auth/auth_service.dart';
import 'package:document_hub/services/auth/http_auth_service.dart';
import 'package:document_hub/services/auth/session.dart';
import 'package:document_hub/screens/chat/chat_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Builds an HttpAuthService whose [Session] and HTTP transport are controlled
/// by the test, so sign-in can be observed end to end without a live API.
HttpAuthService _serviceWith(MockClient client, Session session) =>
    HttpAuthService(session: session, httpClient: client);

void main() {
  group('AuthSession JSON mapping (via HttpAuthService.signIn)', () {
    // NOTE: AuthSession has no `fromJson` factory in the app source; the JSON
    // mapping lives in HttpAuthService._parseSession (private). We exercise the
    // real, public mapping surface: signIn() parsing a 200 body.
    test('maps token/display_name/username/rank/station correctly', () async {
      late http.Request captured;
      final client = MockClient((http.Request request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'token': 'tok-abc-123',
            'display_name': 'Sgt. Dwayne Aitken',
            'username': 'dwayne.aitken',
            'rank': 'Sergeant',
            'station': 'Kingston Central',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final session = Session();
      final result =
          await _serviceWith(client, session).signIn('dwayne.aitken', 'pw');

      expect(result.token, 'tok-abc-123');
      expect(result.displayName, 'Sgt. Dwayne Aitken');
      expect(result.username, 'dwayne.aitken');
      expect(result.rank, 'Sergeant');
      expect(result.station, 'Kingston Central');
      // Sanity: the request was actually a POST.
      expect(captured.method, 'POST');
    });

    test('rank/station are null when absent in the body', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'token': 'tok-2',
              'display_name': 'Officer X',
              'username': 'officer.x',
            }),
            200,
          ));
      final result =
          await _serviceWith(client, Session()).signIn('officer.x', 'pw');
      expect(result.rank, isNull);
      expect(result.station, isNull);
    });

    test('falls back to access_token when token key is absent', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({
              'access_token': 'alt-tok',
              'username': 'u',
            }),
            200,
          ));
      final result = await _serviceWith(client, Session()).signIn('u', 'pw');
      expect(result.token, 'alt-tok');
    });
  });

  group('Session store/clear and TokenProvider conformance', () {
    test('is a TokenProvider', () {
      expect(Session(), isA<TokenProvider>());
    });

    test('store updates current and currentAccessToken()', () async {
      final session = Session();
      expect(session.current, isNull);
      expect(await session.currentAccessToken(), isNull);

      session.store(const AuthSession(
        token: 'bearer-xyz',
        displayName: 'D',
        username: 'd',
      ));

      expect(session.current, isNotNull);
      expect(session.current!.token, 'bearer-xyz');
      expect(await session.currentAccessToken(), 'bearer-xyz');
    });

    test('clear resets current and currentAccessToken()', () async {
      final session = Session();
      session.store(const AuthSession(
        token: 't',
        displayName: 'D',
        username: 'd',
      ));
      session.clear();
      expect(session.current, isNull);
      expect(await session.currentAccessToken(), isNull);
    });
  });

  group('HttpAuthService transport behavior', () {
    test('POSTs to /auth/login with username+password in body, '
        'returns AuthSession on 200, and stores the token', () async {
      late http.Request captured;
      final client = MockClient((http.Request request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'token': 'stored-tok',
            'display_name': 'N',
            'username': 'n',
          }),
          200,
        );
      });
      final session = Session();
      final service = _serviceWith(client, session);

      final result = await service.signIn('n', 'secret');

      // Path assertion: base path (/v1) + /auth/login.
      expect(captured.url.path, '/v1/auth/login');
      expect(captured.method, 'POST');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['username'], 'n');
      expect(body['password'], 'secret');

      // Return value carries the session.
      expect(result.token, 'stored-tok');
      // Side effect: token stored on the shared Session, exposed to TokenProvider.
      expect(session.current!.token, 'stored-tok');
      expect(await session.currentAccessToken(), 'stored-tok');
      expect(service.current!.token, 'stored-tok');
    });

    test('throws AuthException on 401 and does not store a session', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'message': 'bad creds'}),
            401,
          ));
      final session = Session();
      final service = _serviceWith(client, session);

      await expectLater(
        () => service.signIn('n', 'wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(session.current, isNull);
      expect(await session.currentAccessToken(), isNull);
    });

    test('throws AuthException on a network error', () async {
      final client = MockClient((_) async {
        throw http.ClientException('Connection refused');
      });
      final session = Session();
      await expectLater(
        () => _serviceWith(client, session).signIn('n', 'pw'),
        throwsA(isA<AuthException>()),
      );
      expect(session.current, isNull);
    });

    test('throws AuthException when 200 body has no token', () async {
      final client = MockClient((_) async => http.Response(
            jsonEncode({'username': 'n'}),
            200,
          ));
      await expectLater(
        () => _serviceWith(client, Session()).signIn('n', 'pw'),
        throwsA(isA<AuthException>()),
      );
    });

    test('uses the configured base URL path', () async {
      late http.Request captured;
      final client = MockClient((http.Request request) async {
        captured = request;
        return http.Response(
          jsonEncode({'token': 't', 'username': 'n'}),
          200,
        );
      });
      final service = HttpAuthService(
        config: const ApiConfig(baseUrl: 'https://api.jcf.gov.jm/v1'),
        session: Session(),
        httpClient: client,
      );
      await service.signIn('n', 'pw');
      expect(captured.url.host, 'api.jcf.gov.jm');
      expect(captured.url.path, '/v1/auth/login');
    });
  });

  group('ChatGate widget gating', () {
    testWidgets('shows LdapLoginScreen sign-in fields when no session present',
        (WidgetTester tester) async {
      // ChatGate.session is a static singleton seeded null at app start; with no
      // prior sign-in it must render the login screen.
      expect(ChatGate.session.current, isNull,
          reason: 'Precondition: no session stored before gate is pumped.');

      await tester.pumpWidget(const MaterialApp(home: ChatGate()));
      await tester.pump();

      // Sign-in surface markers from LdapLoginScreen.
      expect(find.text('JCF Sign In'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });
}

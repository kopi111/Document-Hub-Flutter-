import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:document_hub/models/chat/chat_attachment.dart';
import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/message_type.dart';
import 'package:document_hub/services/api/api_config.dart';
import 'package:document_hub/services/api/token_provider.dart';
import 'package:document_hub/services/chat/chat_repository.dart';

/// Captures the most recent request a MockClient saw, so tests can assert the
/// HTTP method, path, headers, and decoded JSON body the repository emitted.
class _RequestSpy {
  late http.Request request;

  Map<String, dynamic> get jsonBody =>
      jsonDecode(request.body) as Map<String, dynamic>;
}

/// Builds a MockClient that records the request into [spy] and replies with the
/// given JSON [responseBody] and [status].
MockClient _mockClient(
  _RequestSpy spy, {
  required Object responseBody,
  int status = 200,
}) {
  return MockClient((http.Request request) async {
    spy.request = request;
    return http.Response(
      jsonEncode(responseBody),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

HttpChatRepository _httpRepo(
  http.Client client, {
  TokenProvider tokenProvider = const NullTokenProvider(),
}) {
  return HttpChatRepository(
    config: const ApiConfig(baseUrl: 'http://localhost:5070/v1'),
    tokenProvider: tokenProvider,
    httpClient: client,
  );
}

ChatContact _contact(String id, {String name = 'Test Officer'}) => ChatContact(
      id: id,
      name: name,
      rank: 'Constable',
      station: 'Test Station',
    );

void main() {
  group('InMemoryChatRepository.conversations', () {
    test('returns conversations sorted descending by last-message time',
        () async {
      final repo = InMemoryChatRepository();
      final list = await repo.conversations();

      expect(list, isNotEmpty);
      for (var i = 0; i < list.length - 1; i++) {
        final current = list[i].lastMessage?.sentAt ?? DateTime(2000);
        final next = list[i + 1].lastMessage?.sentAt ?? DateTime(2000);
        expect(
          current.isAfter(next) || current.isAtSameMomentAs(next),
          isTrue,
          reason: 'index $i (${current.toIso8601String()}) should be '
              '>= index ${i + 1} (${next.toIso8601String()})',
        );
      }
    });

    test('returned list is unmodifiable', () async {
      final repo = InMemoryChatRepository();
      final list = await repo.conversations();
      expect(() => list.removeAt(0), throwsUnsupportedError);
    });
  });

  group('InMemoryChatRepository.startConversation', () {
    test('dedupes an existing one-to-one thread', () async {
      final repo = InMemoryChatRepository();
      // off-101 (Tamara Brown / conv-001) is a seeded 1:1 contact.
      final before = await repo.conversations();
      final existing =
          before.firstWhere((c) => !c.isGroup && c.contact.id == 'off-101');

      final opened = await repo.startConversation(existing.contact);

      expect(opened.id, existing.id);
      final after = await repo.conversations();
      expect(after.length, before.length,
          reason: 'opening an existing 1:1 must not add a new thread');
    });

    test('creates and stores a new thread for a fresh contact', () async {
      final repo = InMemoryChatRepository();
      final before = await repo.conversations();
      final fresh = _contact('off-999', name: 'Brand New');

      final created = await repo.startConversation(fresh);

      expect(created.id, 'conv-off-999');
      expect(created.contact.id, 'off-999');
      final after = await repo.conversations();
      expect(after.length, before.length + 1);
      expect(after.any((c) => c.id == 'conv-off-999'), isTrue);
    });
  });

  group('InMemoryChatRepository.messagesFor', () {
    test('returns the thread messages oldest first', () async {
      final repo = InMemoryChatRepository();
      final messages = await repo.messagesFor('conv-001');

      expect(messages.map((m) => m.id).toList(),
          ['msg-001-1', 'msg-001-2', 'msg-001-3']);
    });

    test('throws StateError for an unknown conversation', () async {
      final repo = InMemoryChatRepository();
      expect(() => repo.messagesFor('conv-nope'), throwsStateError);
    });
  });

  group('InMemoryChatRepository.editMessage', () {
    test('changes the text and sets editedAt', () async {
      final repo = InMemoryChatRepository();
      final updated =
          await repo.editMessage('conv-001', 'msg-001-2', 'New roster text');

      expect(updated.text, 'New roster text');
      expect(updated.editedAt, isNotNull);

      final reread = await repo.messagesFor('conv-001');
      final persisted = reread.firstWhere((m) => m.id == 'msg-001-2');
      expect(persisted.text, 'New roster text');
      expect(persisted.editedAt, isNotNull);
    });

    test('trims surrounding whitespace from the new text', () async {
      final repo = InMemoryChatRepository();
      final updated =
          await repo.editMessage('conv-001', 'msg-001-2', '   padded   ');
      expect(updated.text, 'padded');
    });
  });

  group('InMemoryChatRepository.deleteMessage', () {
    test('marks the message deleted and clears its text', () async {
      final repo = InMemoryChatRepository();
      await repo.deleteMessage('conv-001', 'msg-001-1');

      final reread = await repo.messagesFor('conv-001');
      final tombstoned = reread.firstWhere((m) => m.id == 'msg-001-1');
      expect(tombstoned.isDeleted, isTrue);
      expect(tombstoned.text, '');
      expect(tombstoned.reactions, isEmpty);
    });
  });

  group('InMemoryChatRepository.togglePin', () {
    test('toggles the pinned flag on and back off', () async {
      final repo = InMemoryChatRepository();

      final pinned = await repo.togglePin('conv-001', 'msg-001-1');
      expect(pinned.isPinned, isTrue);

      final unpinned = await repo.togglePin('conv-001', 'msg-001-1');
      expect(unpinned.isPinned, isFalse);
    });
  });

  group('InMemoryChatRepository.toggleReaction', () {
    test('adds a reaction, then removes it on a second toggle', () async {
      final repo = InMemoryChatRepository();

      final added = await repo.toggleReaction('conv-001', 'msg-001-1', '👍');
      final reaction = added.reactions.firstWhere((r) => r.emoji == '👍');
      expect(reaction.count, 1);
      expect(reaction.byMe, isTrue);

      final removed = await repo.toggleReaction('conv-001', 'msg-001-1', '👍');
      expect(removed.reactions.any((r) => r.emoji == '👍'), isFalse,
          reason: 'second toggle by the same user removes the reaction');
    });
  });

  group('InMemoryChatRepository.searchMessages', () {
    test('matches case-insensitively on message text', () async {
      final repo = InMemoryChatRepository();
      // msg-001-1 contains "patrol roster"
      final hits = await repo.searchMessages('conv-001', 'PATROL');
      expect(hits.map((m) => m.id), contains('msg-001-1'));
    });

    test('returns empty for a blank query', () async {
      final repo = InMemoryChatRepository();
      final hits = await repo.searchMessages('conv-001', '   ');
      expect(hits, isEmpty);
    });

    test('excludes deleted messages from results', () async {
      final repo = InMemoryChatRepository();
      await repo.deleteMessage('conv-001', 'msg-001-1');
      final hits = await repo.searchMessages('conv-001', 'patrol');
      expect(hits.any((m) => m.id == 'msg-001-1'), isFalse);
    });
  });

  group('InMemoryChatRepository.sendMessage', () {
    test('appends an outbound message to the thread', () async {
      final repo = InMemoryChatRepository();
      final before = (await repo.messagesFor('conv-001')).length;

      final sent = await repo.sendMessage('conv-001', 'Acknowledged');

      expect(sent.fromMe, isTrue);
      expect(sent.text, 'Acknowledged');
      final after = await repo.messagesFor('conv-001');
      expect(after.length, before + 1);
      expect(after.last.id, sent.id);
    });
  });

  // -------------------------------------------------------------------------
  // HttpChatRepository
  // -------------------------------------------------------------------------

  group('HttpChatRepository.sendMessage', () {
    test('POSTs to the messages path with a JSON {text} body', () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {
          'id': 'msg-srv-1',
          'conversation_id': 'conv-001',
          'text': 'Hello there',
          'sent_at': '2026-06-11T10:00:00Z',
          'from_me': true,
          'status': 'delivered',
        },
      );
      final repo = _httpRepo(client);

      final message = await repo.sendMessage('conv-001', 'Hello there');

      expect(spy.request.method, 'POST');
      expect(spy.request.url.path, '/v1/chat/conversations/conv-001/messages');
      expect(spy.jsonBody, {'text': 'Hello there'});

      // snake_case response parsed into the model
      expect(message.id, 'msg-srv-1');
      expect(message.conversationId, 'conv-001');
      expect(message.text, 'Hello there');
      expect(message.fromMe, isTrue);
      expect(message.status, MessageStatus.delivered);
    });
  });

  group('HttpChatRepository.editMessage', () {
    test('PATCHes the message path with a trimmed {text} body', () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {
          'id': 'msg-7',
          'conversation_id': 'conv-001',
          'text': 'edited body',
          'sent_at': '2026-06-11T10:00:00Z',
          'from_me': true,
          'status': 'sent',
          'edited_at': '2026-06-11T10:05:00Z',
        },
      );
      final repo = _httpRepo(client);

      final updated =
          await repo.editMessage('conv-001', 'msg-7', '  edited body  ');

      expect(spy.request.method, 'PATCH');
      expect(spy.request.url.path,
          '/v1/chat/conversations/conv-001/messages/msg-7');
      expect(spy.jsonBody, {'text': 'edited body'});

      expect(updated.id, 'msg-7');
      expect(updated.text, 'edited body');
      expect(updated.editedAt, isNotNull);
    });
  });

  group('HttpChatRepository.toggleReaction', () {
    test('POSTs to the reactions path with a {emoji} body and parses tallies',
        () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {
          'id': 'msg-7',
          'conversation_id': 'conv-001',
          'text': 'reactable',
          'sent_at': '2026-06-11T10:00:00Z',
          'from_me': false,
          'status': 'delivered',
          'reactions': [
            {'emoji': '👍', 'count': 3, 'by_me': true},
          ],
        },
      );
      final repo = _httpRepo(client);

      final updated = await repo.toggleReaction('conv-001', 'msg-7', '👍');

      expect(spy.request.method, 'POST');
      expect(spy.request.url.path,
          '/v1/chat/conversations/conv-001/messages/msg-7/reactions');
      expect(spy.jsonBody, {'emoji': '👍'});

      expect(updated.reactions, hasLength(1));
      expect(updated.reactions.first.emoji, '👍');
      expect(updated.reactions.first.count, 3);
      expect(updated.reactions.first.byMe, isTrue);
    });
  });

  group('HttpChatRepository.messagesFor', () {
    test('GETs the messages path and parses snake_case items', () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {
          'items': [
            {
              'id': 'm1',
              'conversation_id': 'conv-001',
              'text': 'first',
              'sent_at': '2026-06-11T09:00:00Z',
              'from_me': false,
              'status': 'delivered',
              'sender_name': 'Sgt Brown',
            },
            {
              'id': 'm2',
              'conversation_id': 'conv-001',
              'text': 'second',
              'sent_at': '2026-06-11T09:01:00Z',
              'from_me': true,
              'status': 'read',
            },
          ],
        },
      );
      final repo = _httpRepo(client);

      final messages = await repo.messagesFor('conv-001');

      expect(spy.request.method, 'GET');
      expect(spy.request.url.path,
          '/v1/chat/conversations/conv-001/messages');

      expect(messages, hasLength(2));
      expect(messages[0].id, 'm1');
      expect(messages[0].senderName, 'Sgt Brown');
      expect(messages[0].fromMe, isFalse);
      expect(messages[1].id, 'm2');
      expect(messages[1].status, MessageStatus.read);
    });
  });

  group('HttpChatRepository auth header', () {
    test('attaches Authorization: Bearer <token> when a token is supplied',
        () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {'items': <dynamic>[]},
      );
      final repo = _httpRepo(
        client,
        tokenProvider: const StaticTokenProvider('secret-jwt-123'),
      );

      await repo.messagesFor('conv-001');

      expect(spy.request.headers['Authorization'], 'Bearer secret-jwt-123');
    });

    test('omits Authorization when no token is supplied', () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {'items': <dynamic>[]},
      );
      final repo = _httpRepo(client); // NullTokenProvider

      await repo.messagesFor('conv-001');

      expect(spy.request.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('HttpChatRepository.sendAttachment', () {
    test('POSTs the messages path with the wire type, trimmed text, and '
        'attachment, then parses the image response', () async {
      final spy = _RequestSpy();
      final client = _mockClient(
        spy,
        responseBody: {
          'id': 'msg-att-1',
          'conversation_id': 'conv-001',
          'text': 'see photo',
          'sent_at': '2026-06-11T10:00:00Z',
          'from_me': true,
          'status': 'sent',
          'type': 'image',
          'attachment': {
            'url': 'https://cdn.jcf.gov.jm/a.jpg',
            'name': 'a.jpg',
            'size_bytes': 2048,
            'mime_type': 'image/jpeg',
          },
        },
      );
      final repo = _httpRepo(client);

      final message = await repo.sendAttachment(
        'conv-001',
        const ChatAttachment(
          url: 'https://cdn.jcf.gov.jm/a.jpg',
          name: 'a.jpg',
          sizeBytes: 2048,
          mimeType: 'image/jpeg',
        ),
        type: MessageType.image,
        text: '  see photo  ',
      );

      expect(spy.request.method, 'POST');
      expect(spy.request.url.path,
          '/v1/chat/conversations/conv-001/messages');
      final body = spy.jsonBody;
      expect(body['type'], 'image');
      expect(body['text'], 'see photo'); // trimmed
      expect(body['attachment'], isA<Map<String, dynamic>>());
      expect((body['attachment'] as Map)['url'],
          'https://cdn.jcf.gov.jm/a.jpg');

      expect(message.type, MessageType.image);
      expect(message.attachment?.mimeType, 'image/jpeg');
      expect(message.attachment?.sizeBytes, 2048);
    });
  });
}

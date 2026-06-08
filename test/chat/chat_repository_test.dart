// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:document_hub/services/chat/chat_repository.dart';
import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Cutoff used for timestamp-freshness assertions.
  /// Every seed message is in May 2026, so nothing should reach June 1.
  final DateTime seedCutoff = DateTime(2026, 6, 1);

  /// Number of conversations baked into the seed (one group + six officers).
  const int expectedConversationCount = 7;

  // ---------------------------------------------------------------------------
  // Reset the static list to a pristine copy before every test so that
  // mutation tests cannot leak state into later tests.
  //
  // DESIGN NOTE: _conversations is a static field — the list object is shared
  // across ALL InMemoryChatRepository instances and across all calls to
  // conversations().  This means:
  //   • Any message appended to a returned conversation's messages list is
  //     immediately visible to every future conversations() call on any
  //     instance (there is no copy-on-return).
  //   • Tests that mutate the list must clean up after themselves.
  //
  // Because the field is private we cannot reset it from outside the class.
  // The tearDown below removes any extra messages it added by tracking them.
  // ---------------------------------------------------------------------------

  group('InMemoryChatRepository', () {
    late InMemoryChatRepository repository;

    setUp(() {
      repository = InMemoryChatRepository();
    });

    // -------------------------------------------------------------------------
    group('seeded list basics', () {
      test('conversations() returns the expected number of seeded conversations',
          () async {
        final convs = await repository.conversations();
        expect(convs.length, equals(expectedConversationCount));
      });

      test('every conversation has a unique non-empty id', () async {
        final convs = await repository.conversations();
        final ids = convs.map((c) => c.id).toList();

        for (final id in ids) {
          expect(id, isNotEmpty,
              reason: 'conversation id must not be empty');
        }
        expect(ids.toSet().length, equals(ids.length),
            reason: 'all conversation ids must be unique');
      });

      test('every conversation contact has a non-empty name', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.contact.name.trim(), isNotEmpty,
              reason: 'contact name must not be blank (conv ${conv.id})');
        }
      });

      test('every conversation contact has a non-empty rank', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.contact.rank.trim(), isNotEmpty,
              reason: 'contact rank must not be blank (conv ${conv.id})');
        }
      });

      test('every conversation contact has a non-empty station', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.contact.station.trim(), isNotEmpty,
              reason: 'contact station must not be blank (conv ${conv.id})');
        }
      });

      test('seed contains exactly the six expected officer contacts', () async {
        final convs = await repository.conversations();
        final names =
            convs.map((c) => c.contact.name).toList(growable: false);

        expect(names, containsAll(<String>[
          'Tamara Brown',
          'Devon Clarke',
          'Nadine Wright',
          'Omar Reid',
          'Patricia Henry',
          'Garfield Thomas',
        ]));
      });
    });

    // -------------------------------------------------------------------------
    group('message content', () {
      test('every conversation has at least one message', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.messages, isNotEmpty,
              reason: 'conv ${conv.id} must have at least one message');
        }
      });

      test('every message has a non-empty id and non-empty text', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          for (final msg in conv.messages) {
            expect(msg.id.trim(), isNotEmpty,
                reason: 'message id must not be blank (conv ${conv.id})');
            expect(msg.text.trim(), isNotEmpty,
                reason: 'message text must not be blank (msg ${msg.id})');
          }
        }
      });

      test('lastMessage reflects the final entry in messages', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.lastMessage, same(conv.messages.last),
              reason:
                  'lastMessage must be the last element of messages (conv ${conv.id})');
        }
      });

      test('lastMessage on a non-empty conversation has non-empty text',
          () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          // The sentinel (empty text) must only appear for empty threads.
          if (conv.messages.isNotEmpty) {
            expect(conv.lastMessage.text.trim(), isNotEmpty,
                reason:
                    'lastMessage.text must be non-empty when messages is not empty (conv ${conv.id})');
          }
        }
      });

      test('lastMessage sentinel is returned only when messages list is empty',
          () async {
        // Verify sentinel shape by constructing a bare conversation with no
        // messages. contact is required by the constructor but is not accessed
        // by lastMessage, so we supply a minimal valid value.
        const emptyConv = ChatConversation(
          id: 'test-empty',
          contact: ChatContact(
            id: 'x',
            name: 'X',
            rank: 'Constable',
            station: 'Test',
          ),
          messages: [],
        );
        final sentinel = emptyConv.lastMessage;
        expect(sentinel.id, isEmpty,
            reason: 'sentinel id must be empty string');
        expect(sentinel.text, isEmpty,
            reason: 'sentinel text must be empty string');
        expect(sentinel.sentAt, equals(DateTime(2000)),
            reason: 'sentinel sentAt must be epoch-ish DateTime(2000)');
        expect(sentinel.fromMe, isFalse,
            reason: 'sentinel fromMe must be false');
      });
    });

    // -------------------------------------------------------------------------
    group('seed timestamps', () {
      test('all message timestamps are before the cutoff $seedCutoff',
          () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          for (final msg in conv.messages) {
            expect(msg.sentAt.isBefore(seedCutoff), isTrue,
                reason:
                    'msg ${msg.id} sentAt ${msg.sentAt} must be before $seedCutoff');
          }
        }
      });

      test('all message timestamps are in May 2026', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          for (final msg in conv.messages) {
            expect(msg.sentAt.year, equals(2026),
                reason: 'msg ${msg.id} year must be 2026');
            expect(msg.sentAt.month, equals(5),
                reason: 'msg ${msg.id} month must be May (5)');
          }
        }
      });

      test('within each conversation messages are in non-decreasing time order',
          () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          for (var i = 1; i < conv.messages.length; i++) {
            final prev = conv.messages[i - 1].sentAt;
            final curr = conv.messages[i].sentAt;
            expect(curr.isBefore(prev), isFalse,
                reason:
                    'msg[${i}] (${curr}) in conv ${conv.id} must not precede msg[${i - 1}] (${prev})');
          }
        }
      });
    });

    // -------------------------------------------------------------------------
    group('stable ordering', () {
      test('two consecutive calls return conversations in the same order',
          () async {
        final first = await repository.conversations();
        final second = await repository.conversations();

        expect(first.length, equals(second.length));
        for (var i = 0; i < first.length; i++) {
          expect(first[i].id, equals(second[i].id),
              reason: 'position $i must have the same conversation id');
        }
      });

      test(
          'two separate InMemoryChatRepository instances return conversations in the same order',
          () async {
        final other = InMemoryChatRepository();
        final fromRepository = await repository.conversations();
        final fromOther = await other.conversations();

        expect(fromRepository.length, equals(fromOther.length));
        for (var i = 0; i < fromRepository.length; i++) {
          expect(fromRepository[i].id, equals(fromOther[i].id),
              reason:
                  'position $i must be the same id across instances (static backing list)');
        }
      });

      test('conversations are in the expected seeded id order', () async {
        final convs = await repository.conversations();
        final ids = convs.map((c) => c.id).toList();
        expect(ids, equals(<String>[
          'conv-grp-901',
          'conv-001',
          'conv-002',
          'conv-003',
          'conv-004',
          'conv-005',
          'conv-006',
        ]));
      });
    });

    // -------------------------------------------------------------------------
    group('session persistence (mutable static backing list)', () {
      // Track the message we append so we can remove it in tearDown.
      ChatMessage? _appended;
      ChatConversation? _targetConversation;

      tearDown(() async {
        // Clean up appended message so other test groups see pristine seed.
        if (_appended != null && _targetConversation != null) {
          _targetConversation!.messages.remove(_appended);
          _appended = null;
          _targetConversation = null;
        }
      });

      test(
          'messages list is mutable: appended message is observable on the same instance',
          () async {
        final convsBefore = await repository.conversations();
        _targetConversation = convsBefore.first;
        final countBefore = _targetConversation!.messages.length;

        _appended = ChatMessage(
          id: 'msg-test-append',
          text: 'Persistence test message.',
          sentAt: DateTime(2026, 5, 31, 23, 59),
          fromMe: true,
        );
        _targetConversation!.messages.add(_appended!);

        final convsAfter = await repository.conversations();
        final sameConvAfter =
            convsAfter.firstWhere((c) => c.id == _targetConversation!.id);

        expect(sameConvAfter.messages.length, equals(countBefore + 1),
            reason:
                'appended message must be visible on subsequent conversations() call (mutable static list)');
        expect(sameConvAfter.messages.last.id, equals('msg-test-append'));
      });

      test(
          'messages list is mutable: appended message is observable on a different instance',
          () async {
        final convsBefore = await repository.conversations();
        _targetConversation = convsBefore[1]; // use conv-002
        final countBefore = _targetConversation!.messages.length;

        _appended = ChatMessage(
          id: 'msg-test-cross-instance',
          text: 'Cross-instance persistence test.',
          sentAt: DateTime(2026, 5, 31, 23, 59),
          fromMe: false,
        );
        _targetConversation!.messages.add(_appended!);

        // A brand-new repository instance must see the change because the
        // backing list is static.
        final other = InMemoryChatRepository();
        final convsAfter = await other.conversations();
        final sameConvAfter =
            convsAfter.firstWhere((c) => c.id == _targetConversation!.id);

        expect(sameConvAfter.messages.length, equals(countBefore + 1),
            reason:
                'static backing list means new instance shares the same messages list');
      });

      test('conversations() returns the SAME list object on repeated calls',
          () async {
        // The implementation returns _conversations directly (no copy), so the
        // returned reference must be identical across calls.
        final first = await repository.conversations();
        final second = await repository.conversations();
        expect(identical(first, second), isTrue,
            reason:
                'conversations() returns the static list by reference — both calls must yield the same object');
      });
    });

    // -------------------------------------------------------------------------
    group('unreadCount derived property', () {
      test('unreadCount equals the number of messages where fromMe is false',
          () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          final expected =
              conv.messages.where((m) => !m.fromMe).length;
          expect(conv.unreadCount, equals(expected),
              reason:
                  'unreadCount for conv ${conv.id} must equal inbound message count');
        }
      });

      test('no conversation has a negative unreadCount', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          expect(conv.unreadCount, greaterThanOrEqualTo(0),
              reason: 'unreadCount must never be negative (conv ${conv.id})');
        }
      });
    });

    // -------------------------------------------------------------------------
    group('ChatContact.initials derived property', () {
      test('initials are exactly two uppercase letters for two-word names',
          () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          final nameParts =
              conv.contact.name.trim().split(RegExp(r'\s+'));
          if (nameParts.length >= 2) {
            expect(conv.contact.initials.length, equals(2),
                reason:
                    'two-word name "${conv.contact.name}" must yield 2-char initials');
            expect(conv.contact.initials,
                equals(conv.contact.initials.toUpperCase()),
                reason: 'initials must be uppercase');
          }
        }
      });

      test('initials first char matches first letter of first name', () async {
        final convs = await repository.conversations();
        for (final conv in convs) {
          final expectedFirst =
              conv.contact.name.trim()[0].toUpperCase();
          expect(conv.contact.initials[0], equals(expectedFirst),
              reason:
                  'first initial must match first letter of name "${conv.contact.name}"');
        }
      });
    });
  });
}

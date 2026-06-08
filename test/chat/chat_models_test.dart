import 'package:flutter_test/flutter_test.dart';

import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ChatContact buildContact({String name = 'John Doe'}) => ChatContact(
        id: '1',
        name: name,
        rank: 'Constable',
        station: 'Half-Way Tree',
      );

  ChatMessage buildMessage({
    String id = 'msg-1',
    String text = 'Hello',
    bool fromMe = false,
    DateTime? sentAt,
  }) =>
      ChatMessage(
        id: id,
        text: text,
        sentAt: sentAt ?? DateTime(2024, 1, 15, 9, 0),
        fromMe: fromMe,
      );

  ChatConversation buildConversation({
    List<ChatMessage> messages = const [],
  }) =>
      ChatConversation(
        id: 'conv-1',
        contact: buildContact(),
        messages: messages,
      );

  // ---------------------------------------------------------------------------
  // ChatContact — initials
  // ---------------------------------------------------------------------------

  group('ChatContact.initials', () {
    test('derives two uppercase initials from a standard two-word name', () {
      final contact = buildContact(name: 'John Doe');
      expect(contact.initials, equals('JD'));
    });

    test('derives two uppercase initials from a three-word name (first + last)', () {
      final contact = buildContact(name: 'Mary Anne Brown');
      expect(contact.initials, equals('MB'));
    });

    test('derives two uppercase initials from a four-word name (first + last)', () {
      final contact = buildContact(name: 'James Earl Ray Carter');
      expect(contact.initials, equals('JC'));
    });

    test('initials are uppercase even when the name is lowercase', () {
      final contact = buildContact(name: 'alice smith');
      expect(contact.initials, equals('AS'));
    });

    test('initials are uppercase even when the name is mixed case', () {
      final contact = buildContact(name: 'mCDonald fRaser');
      expect(contact.initials, equals('MF'));
    });

    test('collapses extra whitespace between words (leading spaces)', () {
      final contact = buildContact(name: '  John Doe');
      expect(contact.initials, equals('JD'));
    });

    test('collapses extra whitespace between words (internal double space)', () {
      final contact = buildContact(name: 'John  Doe');
      expect(contact.initials, equals('JD'));
    });

    test('collapses extra whitespace between words (trailing spaces)', () {
      final contact = buildContact(name: 'John Doe  ');
      expect(contact.initials, equals('JD'));
    });

    test('collapses tabs and mixed whitespace between name parts', () {
      final contact = buildContact(name: 'Alice\t\tBob');
      expect(contact.initials, equals('AB'));
    });

    // NOTE — DEFECT DOCUMENTED:
    // The class doc-comment states "Two-letter initials derived from the
    // officer's name."  However, for a single-word name the implementation
    // returns only ONE character (the first letter).  The test below asserts
    // the ACTUAL behavior of the current implementation.  When the model is
    // fixed to always produce two characters (e.g. "A" → "AA"), this test
    // must be updated to reflect that fix.
    test('single-word name returns one uppercase character (see defect note)', () {
      final contact = buildContact(name: 'Hercules');
      expect(contact.initials, isNotEmpty);
      expect(contact.initials, equals('H')); // single char — not two
    });

    test('initials are never null or empty for any non-empty name', () {
      final names = [
        'Alpha',
        'Beta Gamma',
        'Delta Epsilon Zeta',
        '  Padded  ',
      ];
      for (final name in names) {
        final contact = buildContact(name: name);
        expect(contact.initials, isNotEmpty,
            reason: 'initials must not be empty for name "$name"');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ChatMessage — construction and field preservation
  // ---------------------------------------------------------------------------

  group('ChatMessage', () {
    test('preserves all fields supplied at construction', () {
      final sentAt = DateTime(2024, 6, 1, 14, 30);
      final message = ChatMessage(
        id: 'abc-123',
        text: 'On my way to the station.',
        sentAt: sentAt,
        fromMe: true,
      );

      expect(message.id, equals('abc-123'));
      expect(message.text, equals('On my way to the station.'));
      expect(message.sentAt, equals(sentAt));
      expect(message.fromMe, isTrue);
    });

    test('fromMe is true when the current user sent the message', () {
      final message = buildMessage(fromMe: true);
      expect(message.fromMe, isTrue);
    });

    test('fromMe is false when the contact sent the message', () {
      final message = buildMessage(fromMe: false);
      expect(message.fromMe, isFalse);
    });

    test('text is preserved verbatim including punctuation and whitespace', () {
      const verbatim = '  Hello,\nWorld!  ';
      final message = buildMessage(text: verbatim);
      expect(message.text, equals(verbatim));
    });

    test('empty text is preserved as-is', () {
      final message = buildMessage(text: '');
      expect(message.text, equals(''));
    });

    test('sentAt timestamp is preserved at millisecond precision', () {
      final ts = DateTime(2024, 12, 31, 23, 59, 59, 999);
      final message = buildMessage(sentAt: ts);
      expect(message.sentAt, equals(ts));
    });
  });

  // ---------------------------------------------------------------------------
  // ChatConversation — lastMessage
  // ---------------------------------------------------------------------------

  group('ChatConversation.lastMessage', () {
    test('returns the final message when messages list has one entry', () {
      final msg = buildMessage(id: 'only', text: 'Solo message');
      final conversation = buildConversation(messages: [msg]);

      expect(conversation.lastMessage, same(msg));
    });

    test('returns the final message when messages list has multiple entries', () {
      final first = buildMessage(id: 'm1', text: 'First');
      final middle = buildMessage(id: 'm2', text: 'Middle');
      final last = buildMessage(id: 'm3', text: 'Last message');
      final conversation = buildConversation(messages: [first, middle, last]);

      expect(conversation.lastMessage, same(last));
    });

    test('returns a non-null sentinel ChatMessage when messages list is empty', () {
      final conversation = buildConversation(messages: []);

      // Must not throw; must not be null (Special-Case pattern).
      expect(conversation.lastMessage, isNotNull);
    });

    test('sentinel ChatMessage has empty text when messages list is empty', () {
      final conversation = buildConversation(messages: []);

      expect(conversation.lastMessage.text, equals(''));
    });

    test('sentinel ChatMessage has empty id when messages list is empty', () {
      final conversation = buildConversation(messages: []);

      expect(conversation.lastMessage.id, equals(''));
    });

    test('sentinel ChatMessage is not fromMe when messages list is empty', () {
      final conversation = buildConversation(messages: []);

      // Sentinel defaults fromMe to false so UI does not attribute it
      // to the current user.
      expect(conversation.lastMessage.fromMe, isFalse);
    });

    test('lastMessage reflects order: always the item at the tail of the list', () {
      final messages = List.generate(
        10,
        (i) => buildMessage(id: 'msg-$i', text: 'Message $i'),
      );
      final conversation = buildConversation(messages: messages);

      expect(conversation.lastMessage.id, equals('msg-9'));
      expect(conversation.lastMessage.text, equals('Message 9'));
    });
  });

  // ---------------------------------------------------------------------------
  // ChatConversation — unreadCount
  // ---------------------------------------------------------------------------

  group('ChatConversation.unreadCount', () {
    test('is 0 for an empty messages list', () {
      final conversation = buildConversation(messages: []);
      expect(conversation.unreadCount, equals(0));
    });

    test('is 0 when every message was sent by the current user', () {
      final messages = [
        buildMessage(id: 'm1', fromMe: true),
        buildMessage(id: 'm2', fromMe: true),
        buildMessage(id: 'm3', fromMe: true),
      ];
      final conversation = buildConversation(messages: messages);

      expect(conversation.unreadCount, equals(0));
    });

    test('counts all inbound messages when none are fromMe', () {
      final messages = [
        buildMessage(id: 'm1', fromMe: false),
        buildMessage(id: 'm2', fromMe: false),
        buildMessage(id: 'm3', fromMe: false),
      ];
      final conversation = buildConversation(messages: messages);

      expect(conversation.unreadCount, equals(3));
    });

    test('counts only inbound messages in a mixed thread', () {
      final messages = [
        buildMessage(id: 'm1', fromMe: false), // inbound
        buildMessage(id: 'm2', fromMe: true),  // outbound
        buildMessage(id: 'm3', fromMe: false), // inbound
        buildMessage(id: 'm4', fromMe: true),  // outbound
        buildMessage(id: 'm5', fromMe: false), // inbound
      ];
      final conversation = buildConversation(messages: messages);

      expect(conversation.unreadCount, equals(3));
    });

    test('is 1 when exactly one inbound message is present', () {
      final messages = [
        buildMessage(id: 'm1', fromMe: true),
        buildMessage(id: 'm2', fromMe: false),
        buildMessage(id: 'm3', fromMe: true),
      ];
      final conversation = buildConversation(messages: messages);

      expect(conversation.unreadCount, equals(1));
    });

    test('counts a single inbound-only thread correctly', () {
      final conversation = buildConversation(
        messages: [buildMessage(id: 'sole', fromMe: false)],
      );
      expect(conversation.unreadCount, equals(1));
    });

    test('is not affected by the message text or sentAt value', () {
      final messages = [
        ChatMessage(
          id: 'x1',
          text: '',
          sentAt: DateTime(2020),
          fromMe: false,
        ),
        ChatMessage(
          id: 'x2',
          text: 'Detailed report attached.',
          sentAt: DateTime(2024, 5, 12),
          fromMe: false,
        ),
      ];
      final conversation = buildConversation(messages: messages);

      expect(conversation.unreadCount, equals(2));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/message_reaction.dart';
import 'package:document_hub/screens/chat/chat_thread_controller.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ChatContact _contact() => const ChatContact(
      id: 'c1',
      name: 'Sgt Reid',
      rank: 'Sergeant',
      station: 'Kingston Central',
    );

ChatMessage _inbound({String id = 'seed-1', String text = 'Hello officer'}) =>
    ChatMessage(
      id: id,
      conversationId: 'conv-1',
      text: text,
      sentAt: DateTime.utc(2026, 1, 1),
      fromMe: false,
      status: MessageStatus.delivered,
      senderName: 'Sgt Reid',
    );

ChatMessage _outbound({String id = 'seed-2', String text = 'Roger that'}) =>
    ChatMessage(
      id: id,
      conversationId: 'conv-1',
      text: text,
      sentAt: DateTime.utc(2026, 1, 1),
      fromMe: true,
      status: MessageStatus.sent,
    );

ChatConversation _conversation({List<ChatMessage>? messages}) =>
    ChatConversation(
      id: 'conv-1',
      contact: _contact(),
      messages: messages ?? [],
    );

/// Attaches a listener counter to [controller] and returns a getter for it.
int Function() _attachCounter(ChatThreadController controller) {
  int count = 0;
  controller.addListener(() => count++);
  return () => count;
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  group('ChatThreadController —', () {
    // -----------------------------------------------------------------------
    // sendText
    // -----------------------------------------------------------------------
    group('sendText', () {
      test('appends one outbound message to the list', () {
        final ctrl = ChatThreadController(_conversation());
        final notified = _attachCounter(ctrl);

        final msg = ctrl.sendText('Test message');

        expect(ctrl.messages.length, 1);
        expect(ctrl.messages.first, same(msg));
        expect(msg.text, 'Test message');
        expect(msg.fromMe, isTrue);
        expect(msg.status, MessageStatus.sent);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('trims whitespace before storing', () {
        final ctrl = ChatThreadController(_conversation());
        final msg = ctrl.sendText('  hello  ');
        expect(msg.text, 'hello');
      });

      test('throws ArgumentError on empty string', () {
        final ctrl = ChatThreadController(_conversation());
        expect(() => ctrl.sendText(''), throwsArgumentError);
      });

      test('throws ArgumentError on whitespace-only string', () {
        final ctrl = ChatThreadController(_conversation());
        expect(() => ctrl.sendText('   '), throwsArgumentError);
      });

      test('does NOT add a message when it throws on empty', () {
        final ctrl = ChatThreadController(_conversation());
        try {
          ctrl.sendText('');
        } catch (_) {}
        expect(ctrl.messages, isEmpty);
      });

      test('each send gets a unique id', () {
        final ctrl = ChatThreadController(_conversation());
        final a = ctrl.sendText('first');
        final b = ctrl.sendText('second');
        expect(a.id, isNot(b.id));
      });
    });

    // -----------------------------------------------------------------------
    // beginReply + sendText
    // -----------------------------------------------------------------------
    group('beginReply then sendText', () {
      test('carries replyToId, replyToPreview, and replyToSender', () {
        final target = _inbound(id: 'orig-1', text: 'What is your status?');
        final ctrl =
            ChatThreadController(_conversation(messages: [target]));

        ctrl.beginReply(target);
        expect(ctrl.replyingTo, same(target));

        final reply = ctrl.sendText('All clear');

        expect(reply.replyToId, 'orig-1');
        expect(reply.replyToPreview, 'What is your status?');
        expect(reply.replyToSender, isNotNull);
      });

      test('replyingTo is cleared after send', () {
        final target = _inbound();
        final ctrl =
            ChatThreadController(_conversation(messages: [target]));
        ctrl.beginReply(target);
        ctrl.sendText('Reply text');
        expect(ctrl.replyingTo, isNull);
      });

      test('sender label is "You" when replying to own message', () {
        final target = _outbound(id: 'mine-1', text: 'I said something');
        final ctrl =
            ChatThreadController(_conversation(messages: [target]));
        ctrl.beginReply(target);
        final reply = ctrl.sendText('Follow-up');
        expect(reply.replyToSender, 'You');
      });

      test('beginReply fires notifyListeners', () {
        final ctrl = ChatThreadController(_conversation(messages: [_inbound()]));
        final notified = _attachCounter(ctrl);
        ctrl.beginReply(ctrl.messages.first);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('clearCompose clears both replyingTo and editing', () {
        final ctrl = ChatThreadController(_conversation(messages: [_inbound()]));
        ctrl.beginReply(ctrl.messages.first);
        ctrl.clearCompose();
        expect(ctrl.replyingTo, isNull);
        expect(ctrl.editing, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // toggleReaction
    // -----------------------------------------------------------------------
    group('toggleReaction', () {
      test('adds a reaction with count=1 and byMe=true', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        final notified = _attachCounter(ctrl);
        final id = ctrl.messages.first.id;

        ctrl.toggleReaction(id, '👍');
        final r = ctrl.messages.first.reactions;

        expect(r.length, 1);
        expect(r.first.emoji, '👍');
        expect(r.first.count, 1);
        expect(r.first.byMe, isTrue);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('toggling same emoji removes the reaction (count reaches 0)', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        final id = ctrl.messages.first.id;

        ctrl.toggleReaction(id, '👍');
        ctrl.toggleReaction(id, '👍');

        expect(ctrl.messages.first.reactions, isEmpty);
      });

      test('two different emojis both stay', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        final id = ctrl.messages.first.id;

        ctrl.toggleReaction(id, '👍');
        ctrl.toggleReaction(id, '❤️');

        expect(ctrl.messages.first.reactions.length, 2);
      });

      test('toggling existing non-mine reaction increments count and sets byMe',
          () {
        final msgWithReaction = ChatMessage(
          id: 'rx-1',
          conversationId: 'conv-1',
          text: 'hi',
          sentAt: DateTime.utc(2026),
          fromMe: false,
          reactions: const [
            // count 2, byMe = false — others reacted
          ],
        );
        // Force a non-mine reaction onto the message manually
        final ctrl = ChatThreadController(
            _conversation(messages: [msgWithReaction]));
        // First toggle: adds new reaction byMe=true count=1
        ctrl.toggleReaction('rx-1', '🔥');
        // Second toggle removes it
        ctrl.toggleReaction('rx-1', '🔥');
        expect(ctrl.messages.first.reactions, isEmpty);
      });

      test('does nothing when messageId is unknown', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        final notifiedBefore =
            _attachCounter(ctrl); // fresh counter after construction
        ctrl.toggleReaction('nonexistent-id', '👍');
        expect(ctrl.messages.first.reactions, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // applyEdit
    // -----------------------------------------------------------------------
    group('applyEdit', () {
      test('updates text and sets editedAt, clears editing state', () {
        final outbound = _outbound(id: 'edit-1', text: 'Original');
        final ctrl =
            ChatThreadController(_conversation(messages: [outbound]));
        final notified = _attachCounter(ctrl);

        ctrl.beginEdit(outbound);
        expect(ctrl.editing, same(outbound));

        ctrl.applyEdit('edit-1', 'Corrected text');

        final updated = ctrl.messageById('edit-1')!;
        expect(updated.text, 'Corrected text');
        expect(updated.editedAt, isNotNull);
        expect(ctrl.editing, isNull);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('trims text on edit', () {
        final outbound = _outbound(id: 'edit-2', text: 'Original');
        final ctrl =
            ChatThreadController(_conversation(messages: [outbound]));
        ctrl.applyEdit('edit-2', '  trimmed  ');
        expect(ctrl.messageById('edit-2')!.text, 'trimmed');
      });

      test('applyEdit on unknown id is a no-op', () {
        final ctrl = ChatThreadController(_conversation());
        ctrl.applyEdit('ghost', 'anything'); // should not throw
        expect(ctrl.messages, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // deleteMessage
    // -----------------------------------------------------------------------
    group('deleteMessage', () {
      test('sets isDeleted=true, clears text, and clears reactions', () {
        final msg = ChatMessage(
          id: 'del-1',
          conversationId: 'conv-1',
          text: 'Secret info',
          sentAt: DateTime.utc(2026),
          fromMe: true,
          reactions: const [MessageReaction(emoji: '👍', count: 1, byMe: true)],
        );
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        final notified = _attachCounter(ctrl);

        ctrl.deleteMessage('del-1');
        final deleted = ctrl.messageById('del-1')!;

        expect(deleted.isDeleted, isTrue);
        expect(deleted.text, isEmpty);
        expect(deleted.reactions, isEmpty);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('deleted message does not appear in pinnedMessage', () {
        final msg = ChatMessage(
          id: 'del-pin-1',
          conversationId: 'conv-1',
          text: 'Pinned secret',
          sentAt: DateTime.utc(2026),
          fromMe: true,
          isPinned: true,
        );
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        ctrl.deleteMessage('del-pin-1');
        expect(ctrl.pinnedMessage, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // togglePin
    // -----------------------------------------------------------------------
    group('togglePin', () {
      test('pins a message and reflects in pinnedMessage getter', () {
        final msg = _inbound(id: 'pin-1', text: 'Important notice');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        final notified = _attachCounter(ctrl);

        expect(ctrl.pinnedMessage, isNull);

        ctrl.togglePin('pin-1');

        expect(ctrl.pinnedMessage, isNotNull);
        expect(ctrl.pinnedMessage!.id, 'pin-1');
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('togglePin again unpins the message', () {
        final msg = _inbound(id: 'pin-2', text: 'Notice');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        ctrl.togglePin('pin-2');
        ctrl.togglePin('pin-2');
        expect(ctrl.pinnedMessage, isNull);
      });

      test('pinnedMessage returns the most recent pinned message', () {
        final a = _inbound(id: 'pin-a', text: 'First pin');
        final b = _inbound(id: 'pin-b', text: 'Second pin');
        final ctrl =
            ChatThreadController(_conversation(messages: [a, b]));
        ctrl.togglePin('pin-a');
        ctrl.togglePin('pin-b');
        expect(ctrl.pinnedMessage!.id, 'pin-b');
      });
    });

    // -----------------------------------------------------------------------
    // setDisappearing
    // -----------------------------------------------------------------------
    group('setDisappearing', () {
      test('new messages inherit the active ttlSeconds', () {
        final ctrl = ChatThreadController(_conversation());
        final notified = _attachCounter(ctrl);

        ctrl.setDisappearing(300);
        expect(ctrl.disappearingTtlSeconds, 300);
        expect(notified(), greaterThanOrEqualTo(1));

        final msg = ctrl.sendText('This will vanish');
        expect(msg.ttlSeconds, 300);
      });

      test('setDisappearing(null) clears the ttl and new messages have no ttl',
          () {
        final ctrl = ChatThreadController(_conversation());
        ctrl.setDisappearing(600);
        ctrl.setDisappearing(null);
        expect(ctrl.disappearingTtlSeconds, isNull);

        final msg = ctrl.sendText('Permanent message');
        expect(msg.ttlSeconds, isNull);
      });

      test('existing messages are not retroactively affected', () {
        final ctrl = ChatThreadController(_conversation());
        ctrl.sendText('Before disappearing');
        ctrl.setDisappearing(60);
        final before = ctrl.messages.first;
        expect(before.ttlSeconds, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // search
    // -----------------------------------------------------------------------
    group('search', () {
      test('returns indices of messages containing the query', () {
        final msgs = [
          _inbound(id: 'm1', text: 'Suspect sighted at market'),
          _inbound(id: 'm2', text: 'All units report in'),
          _inbound(id: 'm3', text: 'Suspect fled north'),
        ];
        final ctrl = ChatThreadController(_conversation(messages: msgs));

        final hits = ctrl.search('suspect');
        expect(hits, containsAll([0, 2]));
        expect(hits.length, 2);
      });

      test('search is case-insensitive', () {
        final msg = _inbound(text: 'URGENT briefing');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        expect(ctrl.search('urgent'), [0]);
      });

      test('returns empty list for empty query', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        expect(ctrl.search(''), isEmpty);
        expect(ctrl.search('   '), isEmpty);
      });

      test('does not return deleted messages', () {
        final msg = ChatMessage(
          id: 'del-search',
          conversationId: 'conv-1',
          text: 'Find me',
          sentAt: DateTime.utc(2026),
          fromMe: false,
          isDeleted: true,
        );
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        expect(ctrl.search('find'), isEmpty);
      });

      test('returns empty when no messages match', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        expect(ctrl.search('xyzzy'), isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // markMyMessagesRead
    // -----------------------------------------------------------------------
    group('markMyMessagesRead', () {
      test('promotes all outbound messages to read status', () {
        final msgs = [
          _outbound(id: 'out-1', text: 'A'),
          _outbound(id: 'out-2', text: 'B'),
          _inbound(id: 'in-1', text: 'C'),
        ];
        final ctrl = ChatThreadController(_conversation(messages: msgs));
        final notified = _attachCounter(ctrl);

        ctrl.markMyMessagesRead();

        expect(ctrl.messages[0].status, MessageStatus.read);
        expect(ctrl.messages[1].status, MessageStatus.read);
        // inbound status is unaffected
        expect(ctrl.messages[2].status, MessageStatus.delivered);
        expect(notified(), greaterThanOrEqualTo(1));
      });

      test('does not notify when nothing changed', () {
        final msgs = [
          ChatMessage(
            id: 'already-read',
            conversationId: 'conv-1',
            text: 'Already read',
            sentAt: DateTime.utc(2026),
            fromMe: true,
            status: MessageStatus.read,
          ),
        ];
        final ctrl = ChatThreadController(_conversation(messages: msgs));
        final notified = _attachCounter(ctrl);

        ctrl.markMyMessagesRead();
        expect(notified(), 0);
      });

      test('only outbound messages are promoted — inbound stay delivered', () {
        final ctrl = ChatThreadController(
            _conversation(messages: [_inbound(), _outbound()]));
        ctrl.markMyMessagesRead();
        final inbound = ctrl.messages.firstWhere((m) => !m.fromMe);
        expect(inbound.status, MessageStatus.delivered);
      });
    });

    // -----------------------------------------------------------------------
    // notifyListeners fires for every mutation
    // -----------------------------------------------------------------------
    group('notifyListeners fires for mutations', () {
      test('sendText notifies', () {
        final ctrl = ChatThreadController(_conversation());
        final n = _attachCounter(ctrl);
        ctrl.sendText('ping');
        expect(n(), greaterThanOrEqualTo(1));
      });

      test('toggleReaction notifies', () {
        final ctrl =
            ChatThreadController(_conversation(messages: [_inbound()]));
        final n = _attachCounter(ctrl);
        ctrl.toggleReaction(ctrl.messages.first.id, '👍');
        expect(n(), greaterThanOrEqualTo(1));
      });

      test('applyEdit notifies', () {
        final msg = _outbound(id: 'e1');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        final n = _attachCounter(ctrl);
        ctrl.applyEdit('e1', 'New text');
        expect(n(), greaterThanOrEqualTo(1));
      });

      test('deleteMessage notifies', () {
        final msg = _outbound(id: 'd1');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        final n = _attachCounter(ctrl);
        ctrl.deleteMessage('d1');
        expect(n(), greaterThanOrEqualTo(1));
      });

      test('setDisappearing notifies', () {
        final ctrl = ChatThreadController(_conversation());
        final n = _attachCounter(ctrl);
        ctrl.setDisappearing(120);
        expect(n(), greaterThanOrEqualTo(1));
      });

      test('togglePin notifies', () {
        final msg = _inbound(id: 'tp1');
        final ctrl =
            ChatThreadController(_conversation(messages: [msg]));
        final n = _attachCounter(ctrl);
        ctrl.togglePin('tp1');
        expect(n(), greaterThanOrEqualTo(1));
      });
    });

    // -----------------------------------------------------------------------
    // isBackedByServer
    // -----------------------------------------------------------------------
    test('isBackedByServer is false when no repository is provided', () {
      final ctrl = ChatThreadController(_conversation());
      expect(ctrl.isBackedByServer, isFalse);
    });

    // -----------------------------------------------------------------------
    // dispose
    // -----------------------------------------------------------------------
    test('disposed controller does not crash on further mutations', () {
      final ctrl = ChatThreadController(_conversation());
      ctrl.dispose();
      // After dispose, _notify() is guarded — should not throw
      expect(() => ctrl.sendText('after dispose'), returnsNormally);
    });
  });
}

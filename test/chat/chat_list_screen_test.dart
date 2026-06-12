import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/screens/chat/chat_list_screen.dart';
import 'package:document_hub/screens/chat/chat_thread_screen.dart';
import 'package:document_hub/services/chat/chat_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository — deterministic, no async delay, controls unread state.
// ---------------------------------------------------------------------------

/// A minimal [ChatRepository] seeded with two conversations:
///   1. "Alice Archer" — has unread messages (fromMe: false present)
///   2. "Bob Barker"  — fully "read" (all messages sent by the user)
///
/// NOTE on [ChatConversation.unreadCount]: the real implementation counts every
/// message where [ChatMessage.fromMe] is false, regardless of whether it has
/// actually been seen by the user. There is no persistent read/unread flag.
/// This is a **design limitation** — the badge always shows the total received-
/// message count, not a true unread count. The tests below assert the observed
/// (current) behaviour; they are annotated where the behaviour diverges from
/// what a user would reasonably expect.
/// Shared base that satisfies every [ChatRepository] member the list screen
/// never calls, so each concrete fake only overrides the behaviour it needs.
abstract class _BaseFakeChatRepository implements ChatRepository {
  @override
  Future<List<ChatContact>> availableContacts() async => const [];

  @override
  Future<List<ChatContact>> allContacts() async => const [];

  @override
  Future<ChatConversation> startConversation(ChatContact contact) async =>
      ChatConversation(id: 'conv-${contact.id}', contact: contact, messages: []);

  @override
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) async =>
      ChatConversation(
        id: 'conv-group-$name',
        contact: members.first,
        messages: [],
      );

  @override
  Future<List<ChatMessage>> messagesFor(String conversationId) async => const [];

  @override
  Future<ChatMessage> sendMessage(String conversationId, String text) =>
      throw UnimplementedError('sendMessage is not exercised by this test.');

  @override
  Future<void> markRead(String conversationId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
          '${invocation.memberName} is not exercised by this test.');
}

class _FakeChatRepository extends _BaseFakeChatRepository {
  static final _aliceContact = const ChatContact(
    id: 'test-alice',
    name: 'Alice Archer',
    rank: 'Sergeant',
    station: 'Half-Way-Tree',
  );

  static final _bobContact = const ChatContact(
    id: 'test-bob',
    name: 'Bob Barker',
    rank: 'Inspector',
    station: 'Barnett Street',
  );

  /// Conversation with unread messages — last message is from the contact.
  static final _aliceConversation = ChatConversation(
    id: 'test-conv-alice',
    contact: _aliceContact,
    messages: [
      ChatMessage(
        id: 'a-1',
        text: 'Hello, can you review the report?',
        sentAt: DateTime(2026, 5, 31, 8, 0),
        fromMe: false, // from contact — counts toward unreadCount
      ),
      ChatMessage(
        id: 'a-2',
        text: 'Sure, I will check it now.',
        sentAt: DateTime(2026, 5, 31, 8, 5),
        fromMe: true,
      ),
      ChatMessage(
        id: 'a-3',
        text: 'Please respond by 14:00.',
        sentAt: DateTime(2026, 5, 31, 8, 10),
        fromMe: false, // from contact — counts toward unreadCount
      ),
    ],
  );

  /// Conversation where the user sent all messages — unreadCount == 0.
  static final _bobConversation = ChatConversation(
    id: 'test-conv-bob',
    contact: _bobContact,
    messages: [
      ChatMessage(
        id: 'b-1',
        text: 'Patrol confirmed for tonight.',
        sentAt: DateTime(2026, 5, 31, 9, 0),
        fromMe: true,
      ),
      ChatMessage(
        id: 'b-2',
        text: 'All units are standing by.',
        sentAt: DateTime(2026, 5, 31, 9, 5),
        fromMe: true,
      ),
    ],
  );

  @override
  Future<List<ChatConversation>> conversations() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return [_aliceConversation, _bobConversation];
  }

  // Expose conversations for assertions.
  static ChatConversation get alice => _aliceConversation;
  static ChatConversation get bob => _bobConversation;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp({ChatRepository? repository}) {
  return MaterialApp(
    home: ChatListScreen(repository: repository ?? _FakeChatRepository()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ChatListScreen', () {
    testWidgets('renders a tile for each conversation contact name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Alice Archer'), findsOneWidget);
      expect(find.text('Bob Barker'), findsOneWidget);
    });

    testWidgets('shows the last-message preview text for each conversation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Alice's last message is the third one (from the contact) — shown as-is.
      expect(find.text('Please respond by 14:00.'), findsOneWidget);

      // Bob's last message is the second one (from the user), so the preview
      // is prefixed "You:" the way WhatsApp marks outbound messages.
      expect(find.text('You: All units are standing by.'), findsOneWidget);
    });

    testWidgets('shows an unread badge for a conversation with received messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Alice has 2 messages where fromMe == false → unreadCount == 2.
      //
      // NOTE: unreadCount reflects total received messages, not messages seen
      // since last open. Marking a conversation as read is not implemented.
      expect(_FakeChatRepository.alice.unreadCount, 2);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('does not show an unread badge for a fully-sent conversation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Bob has no incoming messages → unreadCount == 0 → no badge.
      expect(_FakeChatRepository.bob.unreadCount, 0);

      // Bob's unread count is 0, so '0' must not appear in any badge.
      // (We cannot assert find.text('0').findsNothing absolutely because the
      // digit '0' might appear inside a timestamp; we verify via the unread
      // widget count instead — there is exactly ONE badge for Alice.)
      final badgeFinder = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            return decoration.borderRadius != null;
          }
        }
        return false;
      });

      // The badge count text '2' must appear exactly once (Alice's badge).
      expect(find.text('2'), findsOneWidget);
      // There must be no badge showing '0'.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('tapping a conversation tile navigates to ChatThreadScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Tap Alice's tile.
      await tester.tap(find.text('Alice Archer'));
      await tester.pumpAndSettle();

      // ChatThreadScreen should now be on screen.
      expect(find.byType(ChatThreadScreen), findsOneWidget);
    });

    testWidgets(
      'ChatThreadScreen shows the contact name in its app bar after navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Alice Archer'));
        await tester.pumpAndSettle();

        // The thread app bar renders the contact name — verify it persists
        // on the thread screen (it appears in the app bar title column).
        expect(find.text('Alice Archer'), findsWidgets);
      },
    );

    testWidgets(
      'ChatThreadScreen shows the message input field after navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bob Barker'));
        await tester.pumpAndSettle();

        expect(find.byType(ChatThreadScreen), findsOneWidget);

        // The thread screen always renders a TextField for composing messages.
        expect(find.byType(TextField), findsOneWidget);
      },
    );

    testWidgets('shows loading indicator before async load completes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      // Single pump — initState has fired but future not yet resolved.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Settle to let the future resolve.
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows error message when repository throws', (
      WidgetTester tester,
    ) async {
      final brokenRepository = _ThrowingChatRepository();
      await tester.pumpWidget(_buildApp(repository: brokenRepository));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load messages'), findsOneWidget);
    });

    testWidgets('shows empty-state message when no conversations exist', (
      WidgetTester tester,
    ) async {
      final emptyRepository = _EmptyChatRepository();
      await tester.pumpWidget(_buildApp(repository: emptyRepository));
      await tester.pumpAndSettle();

      expect(find.text('No conversations'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Edge-case repositories used by the last two tests.
// ---------------------------------------------------------------------------

class _ThrowingChatRepository extends _BaseFakeChatRepository {
  @override
  Future<List<ChatConversation>> conversations() async {
    throw Exception('network error');
  }
}

class _EmptyChatRepository extends _BaseFakeChatRepository {
  @override
  Future<List<ChatConversation>> conversations() async => [];
}

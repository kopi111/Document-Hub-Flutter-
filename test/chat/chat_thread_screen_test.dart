import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/screens/chat/chat_thread_screen.dart';
import 'package:document_hub/widgets/chat/presence_subtitle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _contact = ChatContact(
  id: 'contact-01',
  name: 'Owen Clarke',
  rank: 'Corporal',
  station: 'Half-Way Tree',
);

/// Two seed messages placed 2 minutes apart so the timestamp logic
/// (_shouldShowTimestamp requires >= 10 min gap) only emits ONE timestamp
/// label for the first message — keeping find.text assertions predictable.
final _seedMessages = <ChatMessage>[
  ChatMessage(
    id: 'msg-seed-01',
    text: 'Confirm your position.',
    sentAt: DateTime(2026, 5, 31, 9, 0),
    fromMe: false,
  ),
  ChatMessage(
    id: 'msg-seed-02',
    text: 'On route to Alpha site.',
    sentAt: DateTime(2026, 5, 31, 9, 2),
    fromMe: true,
  ),
];

ChatConversation _buildConversation({List<ChatMessage>? messages}) {
  return ChatConversation(
    id: 'conv-01',
    contact: _contact,
    messages: messages ?? List<ChatMessage>.from(_seedMessages),
  );
}

Widget _buildTestApp(ChatConversation conversation) {
  return MaterialApp(
    home: ChatThreadScreen(conversation: conversation),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // Prevent google_fonts from attempting network downloads in tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ChatThreadScreen — seed messages render', () {
    testWidgets('incoming seed message text is visible', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      expect(find.text('Confirm your position.'), findsOneWidget);
    });

    testWidgets('outgoing seed message text is visible', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      expect(find.text('On route to Alpha site.'), findsOneWidget);
    });
  });

  group('ChatThreadScreen — app bar displays contact info', () {
    testWidgets('contact name appears in the app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      // The AppBar title Column renders name and rank·station as separate Texts.
      expect(find.text('Owen Clarke'), findsOneWidget);
    });

    testWidgets('a presence subtitle appears in the app bar', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      // The app bar now renders a PresenceSubtitle. The fixture contact is
      // neither online nor has a lastSeen, so the label is "last seen recently".
      expect(find.byType(PresenceSubtitle), findsOneWidget);
      expect(find.text('last seen recently'), findsOneWidget);
    });
  });

  group('ChatThreadScreen — input row widgets exist', () {
    testWidgets('TextField is present', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('send icon appears once the input has text', (tester) async {
      await tester.pumpWidget(_buildTestApp(_buildConversation()));
      await tester.pumpAndSettle();

      // Empty input shows the voice button; the send button only appears
      // after the user types.
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Standing by.');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    });
  });

  group('ChatThreadScreen — send / echo behaviour', () {
    testWidgets(
        'typing text and tapping send echoes the message as a fromMe bubble',
        (tester) async {
      final conversation = _buildConversation();
      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      const outgoingText = 'Delta team in position.';

      await tester.enterText(find.byType(TextField), outgoingText);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // The new message text must appear exactly once as a bubble.
      expect(find.text(outgoingText), findsOneWidget);
    });

    testWidgets('after sending, the input field is cleared', (tester) async {
      final conversation = _buildConversation();
      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      const outgoingText = 'Awaiting further orders.';

      await tester.enterText(find.byType(TextField), outgoingText);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // _inputController.clear() is called inside setState; the TextField
      // value should now be empty.
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty,
          reason:
              'TextField controller text must be empty after a successful send');
    });

    testWidgets('a send appends the echo, then a mock auto-reply arrives',
        (tester) async {
      final conversation = _buildConversation();
      final initialCount = conversation.messages.length; // 2

      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Checkpoint clear.');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump less than the auto-reply delay: only the outgoing echo exists yet.
      await tester.pump(const Duration(milliseconds: 200));
      expect(conversation.messages.length, initialCount + 1,
          reason: 'The outgoing message is appended immediately');
      expect(conversation.messages.last.fromMe, isTrue);

      // Advance past the auto-reply timer (1600ms) so it fires.
      await tester.pump(const Duration(milliseconds: 1700));
      expect(conversation.messages.length, initialCount + 2,
          reason: 'A mock auto-reply is appended after a short delay');
      expect(conversation.messages.last.fromMe, isFalse,
          reason: 'The auto-reply is an inbound message');

      await tester.pumpAndSettle();
    });

    testWidgets(
        'an empty input shows the voice button instead of send, so no blank '
        'message can be added (structural guard)',
        (tester) async {
      final conversation = _buildConversation();
      final initialCount = conversation.messages.length;

      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller!.text, isEmpty);

      // With no text there is no send affordance at all — the voice button
      // is shown — so a blank message is impossible to send.
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(conversation.messages.length, initialCount);
    });
  });

  group('ChatThreadScreen — emoji can be sent', () {
    testWidgets('a message containing emoji echoes as a fromMe bubble',
        (tester) async {
      final conversation = _buildConversation();
      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      const emojiText = 'Suspect heading north 🚓💨 keep eyes open 👀';

      await tester.enterText(find.byType(TextField), emojiText);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump under the auto-reply delay so the echo is still the last message.
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(emojiText), findsOneWidget);
      expect(conversation.messages.last.text, emojiText,
          reason: 'Emoji must survive the send path byte-for-byte');

      await tester.pumpAndSettle();
    });

    testWidgets(
        'an emoji-only message passes the empty-input guard and is sent',
        (tester) async {
      // _sendMessage trims whitespace then checks isEmpty. Emoji are not
      // whitespace, so an emoji-only message must NOT be rejected.
      final conversation = _buildConversation();
      final initialCount = conversation.messages.length;

      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      const emojiOnly = '👍';
      await tester.enterText(find.byType(TextField), emojiOnly);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump under the auto-reply delay so only the echo is present.
      await tester.pump(const Duration(milliseconds: 200));

      expect(conversation.messages.length, initialCount + 1,
          reason: 'An emoji-only message is not blank and must be appended');
      expect(conversation.messages.last.text, emojiOnly);
      expect(conversation.messages.last.fromMe, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets(
        'multi-codepoint emoji (ZWJ sequence + skin tone) is preserved exactly',
        (tester) async {
      final conversation = _buildConversation();
      await tester.pumpWidget(_buildTestApp(conversation));
      await tester.pumpAndSettle();

      // Family (ZWJ sequence) and a skin-tone modifier — the cases most likely
      // to be mangled by naive truncation or single-codepoint handling.
      const compoundEmoji = 'Family safe 👨‍👩‍👧 thumbs up 👍🏾';

      await tester.enterText(find.byType(TextField), compoundEmoji);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 200));

      expect(conversation.messages.last.text, compoundEmoji,
          reason:
              'ZWJ sequences and skin-tone modifiers must round-trip intact');

      await tester.pumpAndSettle();
    });
  });

  group('ChatThreadScreen — empty conversation', () {
    testWidgets('shows placeholder text when there are no messages',
        (tester) async {
      final emptyConversation = _buildConversation(messages: []);
      await tester.pumpWidget(_buildTestApp(emptyConversation));
      await tester.pumpAndSettle();

      expect(
        find.text('No messages yet. Start the conversation.'),
        findsOneWidget,
      );
    });

    testWidgets('sending a message from empty state adds the first bubble',
        (tester) async {
      final emptyConversation = _buildConversation(messages: []);
      await tester.pumpWidget(_buildTestApp(emptyConversation));
      await tester.pumpAndSettle();

      const firstMessage = 'Hello, officer.';
      await tester.enterText(find.byType(TextField), firstMessage);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump under the auto-reply delay so only the first (outgoing) bubble
      // exists.
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(firstMessage), findsOneWidget);
      expect(emptyConversation.messages.length, 1);

      await tester.pumpAndSettle();
    });
  });
}

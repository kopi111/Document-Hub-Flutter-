// QA suite for the JCF Document Hub chat message flow.
//
// Owned by QA. Touches NO app source. Covers two seams:
//   1. MessageBubble's dispatch-by-MessageType (text / voice / image / file /
//      deleted) — proving each kind routes to its dedicated child widget.
//   2. ChatThreadScreen's composer send path in local demo mode (no repository),
//      including careful handling of the 1600 ms simulated auto-reply timer so
//      no timer/future leaks the test.
//
// Run:
//   ~/flutter/bin/flutter test test/chat_qa/flow_test.dart -r expanded

import 'package:document_hub/models/chat/chat_attachment.dart';
import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/message_type.dart';
import 'package:document_hub/screens/chat/chat_thread_controller.dart';
import 'package:document_hub/screens/chat/chat_thread_screen.dart';
import 'package:document_hub/widgets/chat/deleted_message_bubble.dart';
import 'package:document_hub/widgets/chat/file_message_bubble.dart';
import 'package:document_hub/widgets/chat/image_message_bubble.dart';
import 'package:document_hub/widgets/chat/message_bubble.dart';
import 'package:document_hub/widgets/chat/voice_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _contact = ChatContact(
  id: 'contact-qa',
  name: 'Owen Clarke',
  rank: 'Corporal',
  station: 'Half-Way Tree',
);

ChatConversation _conversation({List<ChatMessage>? messages}) {
  return ChatConversation(
    id: 'conv-qa',
    contact: _contact,
    messages: messages ?? <ChatMessage>[],
  );
}

ChatMessage _textMessage() => ChatMessage(
      id: 'm-text',
      conversationId: 'conv-qa',
      text: 'Confirm your position.',
      sentAt: DateTime(2026, 5, 31, 9, 0),
      fromMe: false,
    );

ChatMessage _voiceMessage() => ChatMessage(
      id: 'm-voice',
      conversationId: 'conv-qa',
      text: '',
      sentAt: DateTime(2026, 5, 31, 9, 1),
      fromMe: true,
      type: MessageType.voice,
      attachment: const ChatAttachment(
        url: 'file:///tmp/voice.m4a',
        mimeType: 'audio/m4a',
        durationMs: 4200,
        waveform: [0.2, 0.6, 0.9, 0.4, 0.7],
      ),
    );

ChatMessage _imageMessage() => ChatMessage(
      id: 'm-image',
      conversationId: 'conv-qa',
      text: '',
      sentAt: DateTime(2026, 5, 31, 9, 2),
      fromMe: true,
      type: MessageType.image,
      attachment: const ChatAttachment(
        url: 'https://example.test/photo.jpg',
        mimeType: 'image/jpeg',
        width: 800,
        height: 600,
      ),
    );

ChatMessage _fileMessage() => ChatMessage(
      id: 'm-file',
      conversationId: 'conv-qa',
      text: '',
      sentAt: DateTime(2026, 5, 31, 9, 3),
      fromMe: true,
      type: MessageType.file,
      attachment: const ChatAttachment(
        url: 'https://example.test/brief.pdf',
        name: 'operation-brief.pdf',
        sizeBytes: 2516582,
        mimeType: 'application/pdf',
      ),
    );

ChatMessage _deletedMessage() => ChatMessage(
      id: 'm-deleted',
      conversationId: 'conv-qa',
      text: '',
      sentAt: DateTime(2026, 5, 31, 9, 4),
      fromMe: false,
      isDeleted: true,
    );

/// Pumps a single [MessageBubble] inside the minimum host the widget needs:
/// a MaterialApp (Directionality + Theme) and a finite-width viewport so the
/// 0.72 * width bubble constraint and the image bubble's LayoutBuilder both
/// resolve. The message's own conversation owns the controller, so the bubble's
/// real dispatch logic runs end-to-end.
Future<void> _pumpBubble(WidgetTester tester, ChatMessage message) async {
  final conversation = _conversation(messages: <ChatMessage>[message]);
  final controller = ChatThreadController(conversation);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: MessageBubble(
              message: message,
              conversation: conversation,
              controller: controller,
              searchQuery: '',
              onJumpToMessage: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  // A finite pump (not pumpAndSettle) — the image bubble shows a
  // CircularProgressIndicator placeholder that never settles, and the voice
  // bubble's ticker only starts on tap, so there is nothing to settle here.
  await tester.pump();
}

// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // -------------------------------------------------------------------------
  // 1. MessageBubble dispatches by MessageType
  // -------------------------------------------------------------------------
  group('MessageBubble dispatch by MessageType', () {
    testWidgets('text message renders the text, NOT a media/deleted bubble',
        (tester) async {
      await _pumpBubble(tester, _textMessage());

      expect(find.text('Confirm your position.'), findsOneWidget,
          reason: 'A text message must render its text via the text bubble');
      expect(find.byType(VoiceMessageBubble), findsNothing);
      expect(find.byType(ImageMessageBubble), findsNothing);
      expect(find.byType(FileMessageBubble), findsNothing);
      expect(find.byType(DeletedMessageBubble), findsNothing);
    });

    testWidgets('voice message dispatches to VoiceMessageBubble',
        (tester) async {
      await _pumpBubble(tester, _voiceMessage());

      expect(find.byType(VoiceMessageBubble), findsOneWidget,
          reason: 'MessageType.voice must route to VoiceMessageBubble');
      // A play affordance proves the voice widget actually rendered.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(ImageMessageBubble), findsNothing);
      expect(find.byType(FileMessageBubble), findsNothing);
    });

    testWidgets('image message dispatches to ImageMessageBubble',
        (tester) async {
      await _pumpBubble(tester, _imageMessage());

      expect(find.byType(ImageMessageBubble), findsOneWidget,
          reason: 'MessageType.image must route to ImageMessageBubble');
      expect(find.byType(VoiceMessageBubble), findsNothing);
      expect(find.byType(FileMessageBubble), findsNothing);
    });

    testWidgets('file message dispatches to FileMessageBubble', (tester) async {
      await _pumpBubble(tester, _fileMessage());

      expect(find.byType(FileMessageBubble), findsOneWidget,
          reason: 'MessageType.file must route to FileMessageBubble');
      // The file name and a download affordance prove the file widget rendered.
      expect(find.text('operation-brief.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byType(VoiceMessageBubble), findsNothing);
      expect(find.byType(ImageMessageBubble), findsNothing);
    });

    testWidgets('deleted message dispatches to DeletedMessageBubble tombstone',
        (tester) async {
      await _pumpBubble(tester, _deletedMessage());

      expect(find.byType(DeletedMessageBubble), findsOneWidget,
          reason: 'isDeleted must short-circuit to the tombstone bubble');
      expect(find.textContaining('This message was deleted'), findsOneWidget);
      // The tombstone replaces ALL other content, including media bubbles.
      expect(find.byType(VoiceMessageBubble), findsNothing);
      expect(find.byType(ImageMessageBubble), findsNothing);
      expect(find.byType(FileMessageBubble), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // 2. ChatThreadScreen composer send (local demo mode, no repository)
  // -------------------------------------------------------------------------
  group('ChatThreadScreen composer send (local demo)', () {
    Widget host(ChatConversation conversation) =>
        MaterialApp(home: ChatThreadScreen(conversation: conversation));

    testWidgets(
        'typing and tapping send appends a fromMe bubble with the typed text '
        '(asserted BEFORE the 1600ms auto-reply fires)', (tester) async {
      final conversation = _conversation();
      await tester.pumpWidget(host(conversation));
      await tester.pumpAndSettle();

      const outgoing = 'Delta team in position.';
      await tester.enterText(find.byType(TextField), outgoing);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      // Pump UNDER the 1600ms auto-reply delay: only the echo exists yet.
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(outgoing), findsOneWidget,
          reason: 'The typed message must appear as a bubble');
      expect(conversation.messages.length, 1);
      expect(conversation.messages.last.fromMe, isTrue);
      expect(conversation.messages.last.text, outgoing);

      // Drain the pending auto-reply timer so it does not leak the test.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
    });

    testWidgets('the input field is cleared after a successful send',
        (tester) async {
      final conversation = _conversation();
      await tester.pumpWidget(host(conversation));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Awaiting orders.');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 200));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, isEmpty,
          reason: 'Composer must clear after send');

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
    });

    testWidgets('the simulated auto-reply arrives as an inbound bubble',
        (tester) async {
      final conversation = _conversation();
      await tester.pumpWidget(host(conversation));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Checkpoint clear.');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));

      await tester.pump(const Duration(milliseconds: 200));
      expect(conversation.messages.length, 1,
          reason: 'Only the echo exists before the auto-reply fires');

      await tester.pump(const Duration(milliseconds: 1700));
      expect(conversation.messages.length, 2,
          reason: 'Auto-reply appended after the 1600ms timer');
      expect(conversation.messages.last.fromMe, isFalse,
          reason: 'The auto-reply is inbound');

      await tester.pumpAndSettle();
    });

    testWidgets(
        'empty input shows the mic (voice) action, NOT a send button, so no '
        'blank message can be sent', (tester) async {
      final conversation = _conversation();
      await tester.pumpWidget(host(conversation));
      await tester.pumpAndSettle();

      // With an empty composer the trailing action is the voice record button;
      // the send icon is intentionally absent — this is what guards blank sends.
      expect(find.byIcon(Icons.send_rounded), findsNothing,
          reason: 'Send button must not exist while the input is empty');
      expect(find.byIcon(Icons.mic), findsOneWidget,
          reason: 'The mic record button replaces send when input is empty');
      expect(conversation.messages, isEmpty);

      await tester.pumpAndSettle();
    });

    testWidgets(
        'controller guard: sendText("") throws and appends nothing',
        (tester) async {
      final conversation = _conversation();
      final controller = ChatThreadController(conversation);
      addTearDown(controller.dispose);

      expect(() => controller.sendText('   '), throwsArgumentError,
          reason: 'Whitespace-only sends must be rejected at the controller');
      expect(conversation.messages, isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:document_hub/models/chat/chat_contact.dart';
import 'package:document_hub/models/chat/chat_conversation.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/message_reaction.dart';
import 'package:document_hub/screens/chat/chat_style.dart';
import 'package:document_hub/screens/chat/chat_thread_controller.dart';
import 'package:document_hub/widgets/chat/deleted_message_bubble.dart';
import 'package:document_hub/widgets/chat/disappearing_badge.dart';
import 'package:document_hub/widgets/chat/edited_tag.dart';
import 'package:document_hub/widgets/chat/pinned_message_banner.dart';
import 'package:document_hub/widgets/chat/reaction_chips.dart';
import 'package:document_hub/widgets/chat/read_receipt_ticks.dart';
import 'package:document_hub/widgets/chat/typing_indicator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _contact = ChatContact(
  id: 'c1',
  name: 'Sgt Reid',
  rank: 'Sergeant',
  station: 'Half Way Tree',
);

ChatConversation _conversationWith(List<ChatMessage> messages) =>
    ChatConversation(id: 'conv-1', contact: _contact, messages: messages);

ChatThreadController _controllerWith(List<ChatMessage> messages) =>
    ChatThreadController(_conversationWith(messages));

ChatMessage _msg({
  required String id,
  String text = 'hello',
  bool fromMe = true,
  bool isPinned = false,
  bool isDeleted = false,
  int? ttlSeconds,
  DateTime? sentAt,
}) =>
    ChatMessage(
      id: id,
      text: text,
      sentAt: sentAt ?? DateTime.now(),
      fromMe: fromMe,
      isPinned: isPinned,
      isDeleted: isDeleted,
      ttlSeconds: ttlSeconds,
    );

/// Pumps [child] inside a chat-themed MaterialApp so ChatStyle-dependent
/// widgets resolve their theme/fonts.
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ChatStyle.theme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // -------------------------------------------------------------------------
  // ReactionChips
  // -------------------------------------------------------------------------
  group('ReactionChips', () {
    testWidgets('renders emoji and count', (tester) async {
      final controller = _controllerWith([_msg(id: 'm1')]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        ReactionChips(
          messageId: 'm1',
          reactions: const [
            MessageReaction(emoji: '👍', count: 3, byMe: false),
          ],
          controller: controller,
        ),
      );

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('byMe reaction is visually distinguished by gold border',
        (tester) async {
      final controller = _controllerWith([_msg(id: 'm1')]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        ReactionChips(
          messageId: 'm1',
          reactions: const [
            MessageReaction(emoji: '🔥', count: 2, byMe: true),
            MessageReaction(emoji: '👀', count: 1, byMe: false),
          ],
          controller: controller,
        ),
      );

      final containers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(containers.length, 2);

      Border borderOf(AnimatedContainer c) =>
          (c.decoration as BoxDecoration).border! as Border;

      final activeBorders = containers
          .map(borderOf)
          .where((b) => b.top.color == ChatStyle.gold)
          .toList();
      // Exactly one chip (the byMe one) should carry the gold accent border.
      expect(activeBorders.length, 1);
      expect(activeBorders.first.top.width, 1.5);
    });

    testWidgets('renders nothing when reactions empty', (tester) async {
      final controller = _controllerWith([_msg(id: 'm1')]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        ReactionChips(
          messageId: 'm1',
          reactions: const [],
          controller: controller,
        ),
      );

      expect(find.byType(AnimatedContainer), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // ReadReceiptTicks
  // -------------------------------------------------------------------------
  group('ReadReceiptTicks', () {
    testWidgets('sent -> single gray done tick', (tester) async {
      await _pump(
        tester,
        const ReadReceiptTicks(status: MessageStatus.sent, fromMe: true),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.done);
      expect(icon.color, ChatStyle.textSecondary);
    });

    testWidgets('delivered -> double gray ticks', (tester) async {
      await _pump(
        tester,
        const ReadReceiptTicks(status: MessageStatus.delivered, fromMe: true),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.done_all);
      expect(icon.color, ChatStyle.textSecondary);
    });

    testWidgets('read -> double blue ticks', (tester) async {
      await _pump(
        tester,
        const ReadReceiptTicks(status: MessageStatus.read, fromMe: true),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.done_all);
      expect(icon.color, ChatStyle.readTick);
    });

    testWidgets('inbound (fromMe false) renders no icon', (tester) async {
      await _pump(
        tester,
        const ReadReceiptTicks(status: MessageStatus.read, fromMe: false),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // TypingIndicator
  // -------------------------------------------------------------------------
  group('TypingIndicator', () {
    testWidgets('shows "<name> is typing" when a name is passed',
        (tester) async {
      await _pump(tester, const TypingIndicator(typistName: 'Cpl Brown'));
      await tester.pump(); // start animation frame
      expect(find.text('Cpl Brown is typing'), findsOneWidget);
    });

    testWidgets('shows no name label when typistName is null', (tester) async {
      await _pump(tester, const TypingIndicator());
      await tester.pump();
      expect(find.textContaining('is typing'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // DeletedMessageBubble
  // -------------------------------------------------------------------------
  group('DeletedMessageBubble', () {
    testWidgets('renders tombstone text', (tester) async {
      await _pump(tester, const DeletedMessageBubble(fromMe: true));
      expect(find.text('🚫 This message was deleted'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // EditedTag
  // -------------------------------------------------------------------------
  group('EditedTag', () {
    testWidgets('renders "edited" label', (tester) async {
      await _pump(tester, const EditedTag());
      expect(find.text('edited'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // PinnedMessageBanner
  // -------------------------------------------------------------------------
  group('PinnedMessageBanner', () {
    testWidgets('shows pinned preview when a message is pinned',
        (tester) async {
      final pinned = _msg(
        id: 'p1',
        text: 'Brief at 0800 hours',
        isPinned: true,
      );
      final controller = _controllerWith([pinned]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        PinnedMessageBanner(controller: controller, onJumpTo: (_) {}),
      );

      expect(find.text('Pinned message'), findsOneWidget);
      expect(find.text('Brief at 0800 hours'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('renders shrunk/empty box when nothing is pinned',
        (tester) async {
      final controller = _controllerWith([_msg(id: 'm1', isPinned: false)]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        PinnedMessageBanner(controller: controller, onJumpTo: (_) {}),
      );

      expect(find.text('Pinned message'), findsNothing);
      expect(find.byIcon(Icons.push_pin_rounded), findsNothing);
      // The banner collapses to a zero-size SizedBox.shrink.
      final bannerSize = tester.getSize(find.byType(PinnedMessageBanner));
      expect(bannerSize, Size.zero);
    });

    testWidgets('reacts to controller togglePin: appears then disappears',
        (tester) async {
      final controller = _controllerWith([_msg(id: 'm1', isPinned: false)]);
      addTearDown(controller.dispose);

      await _pump(
        tester,
        PinnedMessageBanner(controller: controller, onJumpTo: (_) {}),
      );
      expect(find.text('Pinned message'), findsNothing);

      controller.togglePin('m1');
      await tester.pumpAndSettle();
      expect(find.text('Pinned message'), findsOneWidget);

      controller.togglePin('m1');
      await tester.pumpAndSettle();
      expect(find.text('Pinned message'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // DisappearingBadge
  // -------------------------------------------------------------------------
  group('DisappearingBadge', () {
    testWidgets('renders flame + countdown for a message with ttlSeconds',
        (tester) async {
      final message = _msg(
        id: 'd1',
        ttlSeconds: 90,
        sentAt: DateTime.now(),
      );

      await _pump(tester, DisappearingBadge(message: message));

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      // 90s remaining formats to minutes -> "1m".
      expect(find.text('1m'), findsOneWidget);
    });

    testWidgets('renders nothing when message has no ttl', (tester) async {
      final message = _msg(id: 'd2', ttlSeconds: null);
      await _pump(tester, DisappearingBadge(message: message));
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
    });

    testWidgets('renders nothing when ttl already elapsed', (tester) async {
      final message = _msg(
        id: 'd3',
        ttlSeconds: 10,
        sentAt: DateTime.now().subtract(const Duration(seconds: 60)),
      );
      await _pump(tester, DisappearingBadge(message: message));
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
    });
  });
}

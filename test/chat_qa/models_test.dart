import 'package:flutter_test/flutter_test.dart';
import 'package:document_hub/models/chat/chat_attachment.dart';
import 'package:document_hub/models/chat/chat_message.dart';
import 'package:document_hub/models/chat/message_reaction.dart';
import 'package:document_hub/models/chat/message_type.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // MessageType wire mapping
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageType wire round-trip', () {
    const allTypes = MessageType.values;

    for (final t in allTypes) {
      test('${t.name} → wire → fromWire', () {
        final wire = t.wire;
        final decoded = MessageTypeWire.fromWire(wire);
        expect(decoded, t, reason: 'wire=$wire');
      });
    }

    test('fromWire null → text', () {
      expect(MessageTypeWire.fromWire(null), MessageType.text);
    });

    test('fromWire unknown → text', () {
      expect(MessageTypeWire.fromWire('gibberish'), MessageType.text);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MessageReaction
  // ─────────────────────────────────────────────────────────────────────────
  group('MessageReaction', () {
    test('fromJson full fields', () {
      final r = MessageReaction.fromJson({
        'emoji': '👍',
        'count': 3,
        'by_me': true,
      });
      expect(r.emoji, '👍');
      expect(r.count, 3);
      expect(r.byMe, isTrue);
    });

    test('fromJson missing count defaults to 1', () {
      final r = MessageReaction.fromJson({'emoji': '❤️'});
      expect(r.count, 1);
    });

    test('fromJson missing by_me defaults to false', () {
      final r = MessageReaction.fromJson({'emoji': '😂'});
      expect(r.byMe, isFalse);
    });

    test('toJson round-trip preserves all fields', () {
      final original = MessageReaction(emoji: '🔥', count: 5, byMe: true);
      final json = original.toJson();
      final decoded = MessageReaction.fromJson(json);
      expect(decoded.emoji, original.emoji);
      expect(decoded.count, original.count);
      expect(decoded.byMe, original.byMe);
    });

    test('copyWith overrides count and byMe, preserves emoji', () {
      const r = MessageReaction(emoji: '👍', count: 1, byMe: false);
      final updated = r.copyWith(count: 10, byMe: true);
      expect(updated.emoji, '👍');
      expect(updated.count, 10);
      expect(updated.byMe, isTrue);
    });

    test('copyWith with no args preserves all fields', () {
      const r = MessageReaction(emoji: '😢', count: 7, byMe: true);
      final same = r.copyWith();
      expect(same.emoji, r.emoji);
      expect(same.count, r.count);
      expect(same.byMe, r.byMe);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatAttachment.readableSize
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatAttachment.readableSize', () {
    test('null sizeBytes → empty string', () {
      const a = ChatAttachment(url: 'http://x/f');
      expect(a.readableSize, '');
    });

    test('0 bytes → "0 B"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 0);
      expect(a.readableSize, '0 B');
    });

    test('512 bytes → "512 B"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 512);
      expect(a.readableSize, '512 B');
    });

    test('1024 bytes → "1.0 KB"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 1024);
      expect(a.readableSize, '1.0 KB');
    });

    test('1536 bytes → "1.5 KB"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 1536);
      expect(a.readableSize, '1.5 KB');
    });

    test('1 MB (1048576 bytes) → "1.0 MB"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 1048576);
      expect(a.readableSize, '1.0 MB');
    });

    test('2.4 MB (2516582 bytes) → "2.4 MB"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 2516582);
      expect(a.readableSize, '2.4 MB');
    });

    test('1 GB → "1.0 GB"', () {
      const a = ChatAttachment(url: 'http://x/f', sizeBytes: 1073741824);
      expect(a.readableSize, '1.0 GB');
    });

    test('fromJson/toJson round-trip preserves all attachment fields', () {
      final json = {
        'url': 'https://cdn.example.com/voice.m4a',
        'name': 'voice.m4a',
        'size_bytes': 204800,
        'mime_type': 'audio/m4a',
        'duration_ms': 3500,
        'waveform': [0.1, 0.5, 0.9, 0.4],
        'width': null,
        'height': null,
      };
      final a = ChatAttachment.fromJson(json);
      expect(a.url, json['url']);
      expect(a.name, json['name']);
      expect(a.sizeBytes, json['size_bytes']);
      expect(a.mimeType, json['mime_type']);
      expect(a.durationMs, json['duration_ms']);
      expect(a.waveform, [0.1, 0.5, 0.9, 0.4]);
      expect(a.width, isNull);
      expect(a.height, isNull);

      final out = a.toJson();
      final a2 = ChatAttachment.fromJson(out);
      expect(a2.url, a.url);
      expect(a2.sizeBytes, a.sizeBytes);
      expect(a2.waveform, a.waveform);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage.fromJson tolerates missing optional fields
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage.fromJson - minimal payload', () {
    final minimalJson = {
      'id': 'msg-1',
      'text': 'Hello',
      'sent_at': '2024-01-15T10:00:00Z',
      'from_me': true,
    };

    test('parses required fields', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.id, 'msg-1');
      expect(m.text, 'Hello');
      expect(m.fromMe, isTrue);
      expect(m.sentAt, DateTime.utc(2024, 1, 15, 10, 0, 0));
    });

    test('defaults: conversationId empty', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.conversationId, '');
    });

    test('defaults: status is sent', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.status, MessageStatus.sent);
    });

    test('defaults: type is text', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.type, MessageType.text);
    });

    test('defaults: attachment is null', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.attachment, isNull);
    });

    test('defaults: reactions empty', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.reactions, isEmpty);
    });

    test('defaults: editedAt null', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.editedAt, isNull);
    });

    test('defaults: isDeleted false', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.isDeleted, isFalse);
    });

    test('defaults: isPinned false', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.isPinned, isFalse);
    });

    test('defaults: isForwarded false', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.isForwarded, isFalse);
    });

    test('defaults: ttlSeconds null', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.ttlSeconds, isNull);
    });

    test('defaults: replyToId null', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.replyToId, isNull);
    });

    test('defaults: forwardedFrom null', () {
      final m = ChatMessage.fromJson(minimalJson);
      expect(m.forwardedFrom, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage.fromJson - full payload
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage.fromJson - full payload', () {
    final fullJson = {
      'id': 'msg-42',
      'conversation_id': 'conv-7',
      'text': 'See attached',
      'sent_at': '2024-03-20T14:30:00.000Z',
      'from_me': false,
      'status': 'read',
      'sender_name': 'Sgt Reid',
      'type': 'file',
      'attachment': {
        'url': 'https://cdn.example.com/report.pdf',
        'name': 'report.pdf',
        'size_bytes': 512000,
        'mime_type': 'application/pdf',
      },
      'reply_to_id': 'msg-40',
      'reply_to_preview': 'Original text',
      'reply_to_sender': 'Cpl Jones',
      'reactions': [
        {'emoji': '👍', 'count': 2, 'by_me': false},
        {'emoji': '❤️', 'count': 1, 'by_me': true},
      ],
      'edited_at': '2024-03-20T14:35:00.000Z',
      'is_deleted': false,
      'is_pinned': true,
      'is_forwarded': true,
      'forwarded_from': 'Det Brown',
      'ttl_seconds': 86400,
    };

    late ChatMessage m;
    setUp(() => m = ChatMessage.fromJson(fullJson));

    test('id', () => expect(m.id, 'msg-42'));
    test('conversationId', () => expect(m.conversationId, 'conv-7'));
    test('text', () => expect(m.text, 'See attached'));
    test('fromMe', () => expect(m.fromMe, isFalse));
    test('status read', () => expect(m.status, MessageStatus.read));
    test('senderName', () => expect(m.senderName, 'Sgt Reid'));
    test('type file', () => expect(m.type, MessageType.file));
    test('attachment name', () => expect(m.attachment?.name, 'report.pdf'));
    test('attachment sizeBytes', () => expect(m.attachment?.sizeBytes, 512000));
    test('replyToId', () => expect(m.replyToId, 'msg-40'));
    test('replyToPreview', () => expect(m.replyToPreview, 'Original text'));
    test('replyToSender', () => expect(m.replyToSender, 'Cpl Jones'));
    test('reactions count', () => expect(m.reactions.length, 2));
    test('reactions[0] emoji', () => expect(m.reactions[0].emoji, '👍'));
    test('reactions[1] byMe', () => expect(m.reactions[1].byMe, isTrue));
    test('editedAt parsed', () {
      expect(m.editedAt, DateTime.utc(2024, 3, 20, 14, 35, 0));
    });
    test('isPinned', () => expect(m.isPinned, isTrue));
    test('isForwarded', () => expect(m.isForwarded, isTrue));
    test('forwardedFrom', () => expect(m.forwardedFrom, 'Det Brown'));
    test('ttlSeconds', () => expect(m.ttlSeconds, 86400));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage status parsing
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage status parsing', () {
    Map<String, dynamic> baseWith(String status) => {
          'id': 'x',
          'text': 't',
          'sent_at': '2024-01-01T00:00:00Z',
          'from_me': true,
          'status': status,
        };

    test('"sent" → MessageStatus.sent', () {
      expect(ChatMessage.fromJson(baseWith('sent')).status, MessageStatus.sent);
    });

    test('"delivered" → MessageStatus.delivered', () {
      expect(
        ChatMessage.fromJson(baseWith('delivered')).status,
        MessageStatus.delivered,
      );
    });

    test('"read" → MessageStatus.read', () {
      expect(ChatMessage.fromJson(baseWith('read')).status, MessageStatus.read);
    });

    test('unknown status → MessageStatus.sent', () {
      expect(
        ChatMessage.fromJson(baseWith('unknown')).status,
        MessageStatus.sent,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage.toJson round-trip
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage toJson round-trip', () {
    test('text message round-trips', () {
      final original = ChatMessage(
        id: 'rt-1',
        conversationId: 'conv-1',
        text: 'Ping',
        sentAt: DateTime.utc(2024, 6, 1, 9, 0, 0),
        fromMe: true,
        status: MessageStatus.delivered,
      );
      final json = original.toJson();
      final decoded = ChatMessage.fromJson(json);
      expect(decoded.id, original.id);
      expect(decoded.conversationId, original.conversationId);
      expect(decoded.text, original.text);
      expect(decoded.sentAt, original.sentAt);
      expect(decoded.fromMe, original.fromMe);
      expect(decoded.status, original.status);
      expect(decoded.type, original.type);
    });

    test('voice message round-trips', () {
      const attachment = ChatAttachment(
        url: 'https://cdn.example.com/note.m4a',
        durationMs: 5000,
        waveform: [0.2, 0.8, 0.5],
      );
      final original = ChatMessage(
        id: 'rt-2',
        text: '',
        sentAt: DateTime.utc(2024, 6, 1),
        fromMe: true,
        type: MessageType.voice,
        attachment: attachment,
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.type, MessageType.voice);
      expect(decoded.attachment?.durationMs, 5000);
      expect(decoded.attachment?.waveform, [0.2, 0.8, 0.5]);
    });

    test('reactions round-trip preserves list', () {
      final original = ChatMessage(
        id: 'rt-3',
        text: 'hi',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: false,
        reactions: const [
          MessageReaction(emoji: '👍', count: 3, byMe: true),
          MessageReaction(emoji: '😂', count: 1, byMe: false),
        ],
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.reactions.length, 2);
      expect(decoded.reactions[0].emoji, '👍');
      expect(decoded.reactions[0].count, 3);
      expect(decoded.reactions[0].byMe, isTrue);
    });

    test('editedAt survives UTC round-trip', () {
      final edited = DateTime.utc(2024, 5, 10, 12, 0, 0);
      final original = ChatMessage(
        id: 'rt-4',
        text: 'edited',
        sentAt: DateTime.utc(2024, 5, 10),
        fromMe: true,
        editedAt: edited,
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.editedAt, edited);
    });

    test('isDeleted=true survives round-trip', () {
      final original = ChatMessage(
        id: 'rt-5',
        text: 'gone',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: true,
        isDeleted: true,
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.isDeleted, isTrue);
    });

    test('isPinned=true survives round-trip', () {
      final original = ChatMessage(
        id: 'rt-6',
        text: 'pinned',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: false,
        isPinned: true,
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.isPinned, isTrue);
    });

    test('forwarded message round-trips', () {
      final original = ChatMessage(
        id: 'rt-7',
        text: 'fwd',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: false,
        isForwarded: true,
        forwardedFrom: 'Sgt Reid',
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.isForwarded, isTrue);
      expect(decoded.forwardedFrom, 'Sgt Reid');
    });

    test('ttlSeconds survives round-trip', () {
      final original = ChatMessage(
        id: 'rt-8',
        text: 'disappears',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: true,
        ttlSeconds: 3600,
      );
      final decoded = ChatMessage.fromJson(original.toJson());
      expect(decoded.ttlSeconds, 3600);
    });

    test('toJson omits null optional fields', () {
      final msg = ChatMessage(
        id: 'rt-9',
        text: 'plain',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: true,
      );
      final json = msg.toJson();
      expect(json.containsKey('attachment'), isFalse);
      expect(json.containsKey('reply_to_id'), isFalse);
      expect(json.containsKey('edited_at'), isFalse);
      expect(json.containsKey('forwarded_from'), isFalse);
      expect(json.containsKey('ttl_seconds'), isFalse);
    });

    test('toJson omits false boolean flags', () {
      final msg = ChatMessage(
        id: 'rt-10',
        text: 'plain',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: false,
        isDeleted: false,
        isPinned: false,
        isForwarded: false,
      );
      final json = msg.toJson();
      expect(json.containsKey('is_deleted'), isFalse);
      expect(json.containsKey('is_pinned'), isFalse);
      expect(json.containsKey('is_forwarded'), isFalse);
    });

    test('toJson omits reactions key when empty', () {
      final msg = ChatMessage(
        id: 'rt-11',
        text: 't',
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: true,
        reactions: const [],
      );
      final json = msg.toJson();
      expect(json.containsKey('reactions'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage.copyWith
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage.copyWith', () {
    final base = ChatMessage(
      id: 'cw-1',
      conversationId: 'conv-a',
      text: 'original',
      sentAt: DateTime.utc(2024, 2, 1),
      fromMe: true,
      status: MessageStatus.sent,
      senderName: 'Alice',
      type: MessageType.text,
      reactions: const [],
      isDeleted: false,
      isPinned: false,
      isForwarded: false,
    );

    test('no-arg copyWith preserves all fields', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.conversationId, base.conversationId);
      expect(copy.text, base.text);
      expect(copy.sentAt, base.sentAt);
      expect(copy.fromMe, base.fromMe);
      expect(copy.status, base.status);
      expect(copy.senderName, base.senderName);
      expect(copy.type, base.type);
      expect(copy.reactions, base.reactions);
      expect(copy.isDeleted, base.isDeleted);
      expect(copy.isPinned, base.isPinned);
      expect(copy.isForwarded, base.isForwarded);
    });

    test('copyWith text overrides text, preserves id', () {
      final copy = base.copyWith(text: 'updated');
      expect(copy.text, 'updated');
      expect(copy.id, 'cw-1');
    });

    test('copyWith status overrides status', () {
      final copy = base.copyWith(status: MessageStatus.read);
      expect(copy.status, MessageStatus.read);
      expect(copy.text, base.text);
    });

    test('copyWith isDeleted overrides', () {
      final copy = base.copyWith(isDeleted: true);
      expect(copy.isDeleted, isTrue);
      expect(copy.id, base.id);
    });

    test('copyWith isPinned overrides', () {
      final copy = base.copyWith(isPinned: true);
      expect(copy.isPinned, isTrue);
      expect(copy.isDeleted, isFalse);
    });

    test('copyWith reactions overrides list', () {
      final newReactions = [
        const MessageReaction(emoji: '🔥', count: 2, byMe: false)
      ];
      final copy = base.copyWith(reactions: newReactions);
      expect(copy.reactions.length, 1);
      expect(copy.reactions[0].emoji, '🔥');
    });

    test('copyWith editedAt sets value', () {
      final edited = DateTime.utc(2024, 6, 15, 8, 0, 0);
      final copy = base.copyWith(editedAt: edited);
      expect(copy.editedAt, edited);
    });

    test('copyWith ttlSeconds sets value', () {
      final copy = base.copyWith(ttlSeconds: 7200);
      expect(copy.ttlSeconds, 7200);
      expect(copy.id, base.id);
    });

    test('copyWith type and attachment together', () {
      const a = ChatAttachment(url: 'http://x/img.jpg', width: 800, height: 600);
      final copy = base.copyWith(type: MessageType.image, attachment: a);
      expect(copy.type, MessageType.image);
      expect(copy.attachment?.width, 800);
      expect(copy.text, base.text);
    });

    test('copyWith forwardedFrom and isForwarded', () {
      final copy = base.copyWith(isForwarded: true, forwardedFrom: 'Bob');
      expect(copy.isForwarded, isTrue);
      expect(copy.forwardedFrom, 'Bob');
    });

    test('immutability: original unchanged after copyWith', () {
      base.copyWith(text: 'mutated', isDeleted: true);
      expect(base.text, 'original');
      expect(base.isDeleted, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ChatMessage.preview getter
  // ─────────────────────────────────────────────────────────────────────────
  group('ChatMessage.preview', () {
    ChatMessage make(MessageType t, {String text = 'Hello', String? attachName, bool isDeleted = false}) {
      return ChatMessage(
        id: 'p-1',
        text: text,
        sentAt: DateTime.utc(2024, 1, 1),
        fromMe: true,
        type: t,
        isDeleted: isDeleted,
        attachment: attachName != null
            ? ChatAttachment(url: 'http://x', name: attachName)
            : null,
      );
    }

    test('deleted → tombstone text', () {
      expect(make(MessageType.text, isDeleted: true).preview,
          'This message was deleted');
    });

    test('deleted overrides type (voice)', () {
      expect(make(MessageType.voice, isDeleted: true).preview,
          'This message was deleted');
    });

    test('text → returns text', () {
      expect(make(MessageType.text, text: 'Ping').preview, 'Ping');
    });

    test('system → returns text', () {
      expect(make(MessageType.system, text: 'User joined').preview, 'User joined');
    });

    test('voice → emoji label', () {
      expect(make(MessageType.voice).preview, '🎤 Voice message');
    });

    test('image → emoji label', () {
      expect(make(MessageType.image).preview, '📷 Photo');
    });

    test('file with name → includes filename', () {
      expect(make(MessageType.file, attachName: 'brief.pdf').preview,
          '📎 brief.pdf');
    });

    test('file without attachment → fallback "File"', () {
      expect(make(MessageType.file).preview, '📎 File');
    });

    test('location → emoji label', () {
      expect(make(MessageType.location).preview, '📍 Location');
    });
  });
}

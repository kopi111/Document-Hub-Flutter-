import '../../models/chat/chat_contact.dart';
import '../../models/chat/chat_conversation.dart';
import '../../models/chat/chat_group.dart';
import '../../models/chat/chat_message.dart';

/// Deterministic placeholder portrait for a given officer or group id.
String officerAvatar(String id) => 'https://i.pravatar.cc/200?u=$id';

/// Contract for loading and mutating officer conversations.
abstract class ChatRepository {
  Future<List<ChatConversation>> conversations();

  /// Officers the user can start a fresh conversation with — i.e. those not
  /// already in a one-to-one [conversations] thread.
  Future<List<ChatContact>> availableContacts();

  /// Opens a conversation with [contact]: returns the existing thread if one
  /// exists, otherwise creates and stores an empty one. The returned thread is
  /// also added to [conversations].
  Future<ChatConversation> startConversation(ChatContact contact);

  /// Creates a new group thread with the given [name] and [members], stores it,
  /// and returns it. Repositories without group support throw.
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) =>
      throw UnsupportedError('This repository does not support group threads.');
}

/// In-memory implementation seeded with realistic JCF officer data.
///
/// The seed list is a single mutable instance so messages appended during a
/// session survive navigation without a backend.
class InMemoryChatRepository implements ChatRepository {
  InMemoryChatRepository();

  // Static so group ids stay unique even if the repository is recreated, since
  // [_conversations] is itself a shared static list.
  static int _groupSequence = 0;

  @override
  Future<List<ChatConversation>> conversations() async => _conversations;

  @override
  Future<List<ChatContact>> availableContacts() async {
    final inThread = _conversations
        .where((conversation) => !conversation.isGroup)
        .map((conversation) => conversation.contact.id)
        .toSet();
    return _roster
        .where((contact) => !inThread.contains(contact.id))
        .toList(growable: false);
  }

  @override
  Future<ChatConversation> startConversation(ChatContact contact) async {
    final existing = _conversations.where((conversation) =>
        !conversation.isGroup && conversation.contact.id == contact.id);
    if (existing.isNotEmpty) return existing.first;
    final conversation = ChatConversation(
      id: 'conv-${contact.id}',
      contact: contact,
      messages: [],
    );
    _conversations.insert(0, conversation);
    return conversation;
  }

  @override
  Future<ChatConversation> startGroupConversation(
    String name,
    List<ChatContact> members,
  ) async {
    if (members.isEmpty) {
      throw ArgumentError('A group conversation needs at least one member.');
    }
    _groupSequence++;
    final group = ChatGroup(
      id: 'grp-new-$_groupSequence',
      name: name,
      // Copy so the group can't be mutated through the caller's list reference.
      members: List<ChatContact>.unmodifiable(members),
      avatarUrl: officerAvatar('grp-new-$_groupSequence'),
    );
    final conversation = ChatConversation(
      id: 'conv-${group.id}',
      contact: members.first,
      group: group,
      messages: [],
    );
    _conversations.insert(0, conversation);
    return conversation;
  }

  /// Roster of officers available to start a new conversation with.
  static final List<ChatContact> _roster = [
    ChatContact(
      id: 'off-201',
      name: 'Marlon Stewart',
      rank: 'Sergeant',
      station: 'Denham Town',
      avatarUrl: officerAvatar('off-201'),
      isOnline: true,
    ),
    ChatContact(
      id: 'off-202',
      name: 'Camille Foster',
      rank: 'Inspector',
      station: 'St. Catherine North',
      avatarUrl: officerAvatar('off-202'),
      lastSeen: DateTime(2026, 5, 31, 8, 40),
    ),
    ChatContact(
      id: 'off-203',
      name: 'Ricardo Bennett',
      rank: 'Constable',
      station: 'Portmore',
      avatarUrl: officerAvatar('off-203'),
      isOnline: true,
    ),
    ChatContact(
      id: 'off-204',
      name: 'Shelly-Ann Grant',
      rank: 'Detective Sergeant',
      station: 'MOCA',
      avatarUrl: officerAvatar('off-204'),
      lastSeen: DateTime(2026, 5, 30, 19, 12),
    ),
    ChatContact(
      id: 'off-205',
      name: 'Andre Walker',
      rank: 'Corporal',
      station: 'Mandeville',
      avatarUrl: officerAvatar('off-205'),
      lastSeen: DateTime(2026, 5, 31, 6, 5),
    ),
    ChatContact(
      id: 'off-206',
      name: 'Keisha Morgan',
      rank: 'Superintendent',
      station: 'Area 4 HQ',
      avatarUrl: officerAvatar('off-206'),
      isOnline: true,
    ),
  ];

  /// Members of the seeded demonstration group.
  static final List<ChatContact> _groupMembers = [
    _roster[0],
    _roster[2],
    _roster[5],
  ];

  static final List<ChatConversation> _conversations = [
    ChatConversation(
      id: 'conv-grp-901',
      contact: _groupMembers.first,
      group: ChatGroup(
        id: 'grp-901',
        name: 'Operation Restore Order',
        members: _groupMembers,
        avatarUrl: officerAvatar('grp-901'),
      ),
      messages: [
        ChatMessage(
          id: 'msg-901-1',
          text: 'Team, briefing at 06:00 sharp at Area 4 HQ. Full kit.',
          sentAt: DateTime(2026, 5, 31, 5, 10),
          fromMe: false,
          senderName: 'Keisha Morgan',
        ),
        ChatMessage(
          id: 'msg-901-2',
          text: 'Copy. Denham Town unit will be there.',
          sentAt: DateTime(2026, 5, 31, 5, 14),
          fromMe: false,
          senderName: 'Marlon Stewart',
        ),
        ChatMessage(
          id: 'msg-901-3',
          text: 'Understood. Rolling out from Portmore now.',
          sentAt: DateTime(2026, 5, 31, 5, 18),
          fromMe: true,
          status: MessageStatus.read,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-001',
      contact: ChatContact(
        id: 'off-101',
        name: 'Tamara Brown',
        rank: 'Sergeant',
        station: 'Half-Way-Tree',
        avatarUrl: officerAvatar('off-101'),
        isOnline: true,
      ),
      messages: [
        ChatMessage(
          id: 'msg-001-1',
          text: 'Good morning Constable. Please confirm the patrol roster for tonight.',
          sentAt: DateTime(2026, 5, 30, 7, 15),
          fromMe: false,
        ),
        ChatMessage(
          id: 'msg-001-2',
          text: 'Morning Sarge. Roster confirmed — four officers on Echo shift.',
          sentAt: DateTime(2026, 5, 30, 7, 22),
          fromMe: true,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg-001-3',
          text: 'Copy that. Ensure they sign the duty log before deployment.',
          sentAt: DateTime(2026, 5, 30, 7, 25),
          fromMe: false,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-002',
      contact: ChatContact(
        id: 'off-102',
        name: 'Devon Clarke',
        rank: 'Inspector',
        station: 'Barnett Street',
        avatarUrl: officerAvatar('off-102'),
        lastSeen: DateTime(2026, 5, 31, 7, 50),
      ),
      messages: [
        ChatMessage(
          id: 'msg-002-1',
          text: 'The exhibit from last night\'s seizure has been logged under EX-2026-0891.',
          sentAt: DateTime(2026, 5, 29, 22, 40),
          fromMe: false,
        ),
        ChatMessage(
          id: 'msg-002-2',
          text: 'Acknowledged Inspector. I will update the case file first thing tomorrow.',
          sentAt: DateTime(2026, 5, 29, 22, 47),
          fromMe: true,
          status: MessageStatus.read,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-003',
      contact: ChatContact(
        id: 'off-103',
        name: 'Nadine Wright',
        rank: 'Corporal',
        station: 'CTOC',
        avatarUrl: officerAvatar('off-103'),
        isOnline: true,
      ),
      messages: [
        ChatMessage(
          id: 'msg-003-1',
          text: 'Can you send over the intelligence brief for Operation Curtain?',
          sentAt: DateTime(2026, 5, 31, 9, 5),
          fromMe: true,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg-003-2',
          text: 'Sending it through secure channel now. Check your inbox.',
          sentAt: DateTime(2026, 5, 31, 9, 11),
          fromMe: false,
        ),
        ChatMessage(
          id: 'msg-003-3',
          text: 'Received. Thank you Corporal.',
          sentAt: DateTime(2026, 5, 31, 9, 14),
          fromMe: true,
          status: MessageStatus.delivered,
        ),
        ChatMessage(
          id: 'msg-003-4',
          text: 'Stand by — the ACP wants an update by 14:00.',
          sentAt: DateTime(2026, 5, 31, 9, 18),
          fromMe: false,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-004',
      contact: ChatContact(
        id: 'off-104',
        name: 'Omar Reid',
        rank: 'Constable',
        station: 'Spanish Town',
        avatarUrl: officerAvatar('off-104'),
        lastSeen: DateTime(2026, 5, 28, 15, 5),
      ),
      messages: [
        ChatMessage(
          id: 'msg-004-1',
          text: 'Vehicle check on plate PB7341 came back clear.',
          sentAt: DateTime(2026, 5, 28, 14, 30),
          fromMe: false,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-005',
      contact: ChatContact(
        id: 'off-105',
        name: 'Patricia Henry',
        rank: 'Superintendent',
        station: 'Kingston Central',
        avatarUrl: officerAvatar('off-105'),
      ),
      messages: [
        ChatMessage(
          id: 'msg-005-1',
          text: 'Ensure your division\'s stats are submitted by Friday COB.',
          sentAt: DateTime(2026, 5, 27, 11, 0),
          fromMe: false,
        ),
        ChatMessage(
          id: 'msg-005-2',
          text: 'Understood Ma\'am. Will have them in by Thursday.',
          sentAt: DateTime(2026, 5, 27, 11, 8),
          fromMe: true,
          status: MessageStatus.read,
        ),
      ],
    ),
    ChatConversation(
      id: 'conv-006',
      contact: ChatContact(
        id: 'off-106',
        name: 'Garfield Thomas',
        rank: 'Detective Corporal',
        station: 'Hunts Bay',
        avatarUrl: officerAvatar('off-106'),
        isOnline: true,
      ),
      messages: [
        ChatMessage(
          id: 'msg-006-1',
          text: 'Witness statement for case CR-2026-1144 is ready for your signature.',
          sentAt: DateTime(2026, 5, 26, 16, 45),
          fromMe: false,
        ),
        ChatMessage(
          id: 'msg-006-2',
          text: 'I will come by Hunts Bay tomorrow morning to sign.',
          sentAt: DateTime(2026, 5, 26, 17, 2),
          fromMe: true,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'msg-006-3',
          text: 'Works for me. I will be in from 08:00.',
          sentAt: DateTime(2026, 5, 26, 17, 10),
          fromMe: false,
        ),
      ],
    ),
  ];
}

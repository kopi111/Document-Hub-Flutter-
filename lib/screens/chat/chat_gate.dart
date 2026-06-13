import 'package:flutter/material.dart';

import '../../services/auth/session.dart';
import '../../services/chat/chat_repository.dart';
import 'chat_list_screen.dart';

/// Opens the chat conversation list. No separate sign-in: the officer already
/// authenticated at the app's front page, so chat reuses [Session.shared]'s
/// bearer token to read and write the same conversations as every other client.
class ChatGate extends StatelessWidget {
  const ChatGate({super.key});

  static final ChatRepository _repository =
      HttpChatRepository(tokenProvider: Session.shared);

  @override
  Widget build(BuildContext context) {
    return ChatListScreen(repository: _repository);
  }
}

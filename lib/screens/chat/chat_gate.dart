import 'package:flutter/material.dart';

import '../../services/auth/auth_service.dart';
import '../../services/auth/http_auth_service.dart';
import '../../services/auth/session.dart';
import '../../services/chat/chat_repository.dart';
import '../auth/ldap_login_screen.dart';
import 'chat_list_screen.dart';

/// Gates the chat behind LDAP sign-in. The first time an officer opens chat they
/// authenticate against the JCF directory through the API's `/auth/login`
/// endpoint; the resulting [AuthSession] is held for the rest of the app session
/// so chat opens straight to the conversation list on later visits.
class ChatGate extends StatelessWidget {
  const ChatGate({super.key});

  /// Shared across every chat entry point so the bearer token survives
  /// navigation and feeds the API client.
  static final Session session = Session();
  static final AuthService _authService = HttpAuthService(session: session);

  /// Backed by the live API and authenticated with the shared session token, so
  /// every signed-in client reads and writes the same conversations.
  static final ChatRepository _repository =
      HttpChatRepository(tokenProvider: session);

  @override
  Widget build(BuildContext context) {
    if (session.current != null) {
      return ChatListScreen(repository: _repository);
    }
    return LdapLoginScreen(
      authService: _authService,
      onSignedIn: (_) => ChatListScreen(repository: _repository),
    );
  }
}

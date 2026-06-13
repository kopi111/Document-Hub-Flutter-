import 'package:enough_mail/enough_mail.dart';

import '../../models/email/email_message.dart';
import 'jcf_mail_config.dart';

/// Raised when the mail server rejects the officer's credentials or cannot
/// be reached during sign-in.
class MailAuthException implements Exception {
  const MailAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Raised when an authenticated session fails to read or send mail.
class MailSyncException implements Exception {
  const MailSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A live, authenticated connection to an officer's JCF mailbox.
///
/// Obtain one through [JcfMailService.signIn]. The session owns an open
/// [MailClient]; call [signOut] when the inbox screen is dismissed.
class JcfMailService {
  JcfMailService._(this._client, this.address);

  final MailClient _client;

  /// The signed-in mailbox address, e.g. `firstname.lastname@jcf.gov.jm`.
  final String address;

  /// Connects to the JCF mail host and authenticates the officer.
  ///
  /// Throws [MailAuthException] when the credentials are rejected or the
  /// server is unreachable.
  static Future<JcfMailService> signIn({
    required String email,
    required String password,
  }) async {
    final account = MailAccount.fromManualSettings(
      name: 'JCF Mail',
      email: email,
      incomingHost: JcfMailConfig.host,
      outgoingHost: JcfMailConfig.host,
      password: password,
      incomingPort: JcfMailConfig.imapPort,
      outgoingPort: JcfMailConfig.smtpPort,
      incomingSocketType: JcfMailConfig.imapSocket,
      outgoingSocketType: JcfMailConfig.smtpSocket,
      outgoingClientDomain: JcfMailConfig.clientDomain,
    );

    final client = MailClient(account, isLogEnabled: false);
    try {
      await client.connect();
    } on MailException catch (error) {
      throw MailAuthException(_describeSignInFailure(error));
    }
    return JcfMailService._(client, email);
  }

  /// Loads the most recent inbox messages, newest first.
  ///
  /// Throws [MailSyncException] when the inbox cannot be read.
  Future<List<EmailMessage>> loadInbox({int count = 30}) async {
    try {
      await _client.selectInbox();
      final messages = await _client.fetchMessages(count: count);
      final mapped = messages.map(_toEmailMessage).toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return mapped;
    } on MailException catch (error) {
      throw MailSyncException('Could not load inbox: ${error.message}');
    }
  }

  /// Sends a plain-text message from the signed-in mailbox.
  ///
  /// Throws [MailSyncException] when the message cannot be delivered.
  Future<void> sendMessage({
    required String to,
    required String subject,
    required String body,
  }) async {
    final builder = MessageBuilder.prepareMultipartAlternativeMessage(
      plainText: body,
      htmlText: '<p>${_escapeHtml(body)}</p>',
    )
      ..from = [MailAddress(null, address)]
      ..to = [MailAddress(null, to)]
      ..subject = subject;
    try {
      await _client.sendMessageBuilder(builder);
    } on MailException catch (error) {
      throw MailSyncException('Could not send message: ${error.message}');
    }
  }

  /// Closes the connection to the mail host.
  Future<void> signOut() => _client.disconnect();

  static EmailMessage _toEmailMessage(MimeMessage message) {
    final from = _firstSender(message);
    final body = _decodeBody(message);
    return EmailMessage(
      id: _stableId(message),
      sender: from.personalName?.trim().isNotEmpty == true
          ? from.personalName!
          : from.email,
      senderAddress: from.email,
      subject: _decodeSubject(message),
      preview: _previewOf(body),
      body: body,
      receivedAt: message.decodeDate() ?? DateTime.now(),
      unread: !message.isSeen,
    );
  }

  static MailAddress _firstSender(MimeMessage message) {
    final senders = message.from;
    if (senders != null && senders.isNotEmpty) return senders.first;
    return const MailAddress('Unknown sender', 'unknown@jcf.gov.jm');
  }

  static String _stableId(MimeMessage message) =>
      message.uid?.toString() ?? message.sequenceId?.toString() ?? 'unknown';

  static String _decodeSubject(MimeMessage message) {
    final subject = message.decodeSubject();
    return (subject == null || subject.trim().isEmpty)
        ? '(No subject)'
        : subject;
  }

  static String _decodeBody(MimeMessage message) {
    final plain = message.decodeTextPlainPart();
    if (plain != null && plain.trim().isNotEmpty) return plain.trim();
    final html = message.decodeTextHtmlPart();
    if (html != null && html.trim().isNotEmpty) return _stripHtml(html);
    return '(This message has no readable text body.)';
  }

  static String _previewOf(String body) {
    final collapsed = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.length <= 140) return collapsed;
    return '${collapsed.substring(0, 140)}…';
  }

  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _escapeHtml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _describeSignInFailure(MailException error) {
    final detail = error.message?.toLowerCase() ?? '';
    final rejectedCredentials = detail.contains('authenticat') ||
        detail.contains('login') ||
        detail.contains('credential') ||
        detail.contains('password');
    if (rejectedCredentials) {
      return 'Sign-in failed. Check your JCF email address and password.';
    }
    return 'Could not reach the JCF mail server. Check your connection and try again.';
  }
}

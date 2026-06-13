import 'package:enough_mail/enough_mail.dart';

/// Connection settings for the JCF mailbox host.
///
/// JCF email is hosted on Rackspace Email, which serves both IMAP and SMTP
/// from the same secure endpoint. These values mirror the working SMTP
/// configuration used by the VM Workflow service.
class JcfMailConfig {
  const JcfMailConfig._();

  static const String host = 'secure.emailsrvr.com';

  static const int imapPort = 993;
  static const SocketType imapSocket = SocketType.ssl;

  static const int smtpPort = 587;
  static const SocketType smtpSocket = SocketType.starttls;

  /// Domain announced to the outgoing server in the SMTP greeting.
  static const String clientDomain = 'jcf.gov.jm';
}

import 'package:url_launcher/url_launcher.dart';

/// Raised when a phone number cannot be handed to the device dialer.
class DialFailure implements Exception {
  const DialFailure(this.number);

  final String number;

  @override
  String toString() => 'Could not open the dialer for $number';
}

/// Opens the device dialer pre-filled with [rawNumber].
///
/// Non-dialable characters (spaces, dashes, parentheses) are stripped so the
/// `tel:` URI is always well-formed. Throws [DialFailure] when no dialer can
/// handle the request rather than failing silently.
Future<void> dialNumber(String rawNumber) async {
  final digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: digits);
  final launched = await launchUrl(uri);
  if (!launched) {
    throw DialFailure(rawNumber);
  }
}

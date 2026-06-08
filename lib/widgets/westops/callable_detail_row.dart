import 'package:flutter/material.dart';

import '../../services/phone_dialer.dart';
import '../../theme/nam_style.dart';

/// A NAM detail row whose value is a tappable phone number. Tapping hands the
/// number to the device dialer; a failed launch surfaces a snackbar rather than
/// failing silently.
///
/// Shares the label column width with [NamDetailRow] so callable and plain rows
/// line up inside the same [NamDetailCard].
class NamCallableDetailRow extends StatelessWidget {
  const NamCallableDetailRow({
    super.key,
    required this.label,
    required this.phoneNumber,
  });

  final String label;
  final String phoneNumber;

  Future<void> _dial(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await dialNumber(phoneNumber);
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not call $phoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _dial(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 116,
              child: Text(
                label.toUpperCase(),
                style: NamStyle.mono(
                  size: 10,
                  weight: FontWeight.w600,
                  color: NamStyle.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.call, size: 16, color: NamStyle.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phoneNumber,
                      style: NamStyle.body(size: 14, color: NamStyle.gold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

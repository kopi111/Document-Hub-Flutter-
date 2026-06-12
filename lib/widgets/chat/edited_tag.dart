// INTEGRATION: Place EditedTag() just before the timestamp Text in the bubble's
// trailing Row whenever message.editedAt != null.

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';

/// Inline "edited" label shown on a bubble when [ChatMessage.editedAt] is set.
class EditedTag extends StatelessWidget {
  const EditedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'edited',
      style: ChatStyle.body(
        size: 11,
        color: ChatStyle.textSecondary,
        weight: FontWeight.w400,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// A bold section title with an optional right-aligned text action
/// (e.g. "Browse by Category" ··· "View All").
class HubSectionHeading extends StatelessWidget {
  const HubSectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: HubStyle.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: Color(0xFF2D6CDF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

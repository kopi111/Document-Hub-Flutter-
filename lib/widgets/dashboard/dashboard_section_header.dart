import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Slab-serif section header with an optional trailing action.
class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onActionPressed != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.robotoSlab(
            textStyle: Theme.of(context).textTheme.titleLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hasAction)
          TextButton(
            onPressed: onActionPressed,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

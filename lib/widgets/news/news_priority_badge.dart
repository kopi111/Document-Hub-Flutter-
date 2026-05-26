import 'package:flutter/material.dart';

import '../../models/news/news_priority.dart';
import '../../theme/jcf_palette.dart';

class NewsPriorityBadge extends StatelessWidget {
  const NewsPriorityBadge({super.key, required this.priority});

  final NewsPriority priority;

  @override
  Widget build(BuildContext context) {
    if (!priority.isFlagged) return const SizedBox.shrink();
    final urgency = _urgencyStyleFor(priority);
    return Semantics(
      label: '${priority.label} priority announcement',
      excludeSemantics: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: urgency.background,
          border: urgency.border != null
              ? Border.all(color: urgency.border!)
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              priority == NewsPriority.urgent
                  ? Icons.priority_high
                  : Icons.flag,
              size: 14,
              color: urgency.foreground,
            ),
            const SizedBox(width: 4),
            Text(
              priority.label.toUpperCase(),
              style: TextStyle(
                color: urgency.foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  UrgencyStyle _urgencyStyleFor(NewsPriority priority) => switch (priority) {
        NewsPriority.urgent => UrgencyStyle.urgent,
        NewsPriority.high => UrgencyStyle.high,
        NewsPriority.normal => UrgencyStyle.routine,
      };
}

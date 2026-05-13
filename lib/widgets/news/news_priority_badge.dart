import 'package:flutter/material.dart';

import '../../models/news/news_priority.dart';

class NewsPriorityBadge extends StatelessWidget {
  const NewsPriorityBadge({super.key, required this.priority});

  final NewsPriority priority;

  @override
  Widget build(BuildContext context) {
    if (!priority.isFlagged) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '${priority.label} priority announcement',
      excludeSemantics: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: priority.backgroundColor(scheme),
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
              color: priority.foregroundColor(scheme),
            ),
            const SizedBox(width: 4),
            Text(
              priority.label.toUpperCase(),
              style: TextStyle(
                color: priority.foregroundColor(scheme),
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
}

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top-of-dashboard greeting that adapts to the time of day.
///
/// Pure presentational widget; the current time is read once at build time so
/// the greeting refreshes naturally as the user returns to the dashboard.
class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final greeting = _greetingFor(now);
    final formattedDate = _formatDate(now);

    return Card(
      color: scheme.primaryContainer,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, Officer',
                    style: GoogleFonts.robotoSlab(
                      textStyle: Theme.of(context).textTheme.headlineSmall,
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer
                              .withValues(alpha: 0.78),
                        ),
                  ),
                ],
              ),
            ),
            const Gap(12),
            CircleAvatar(
              radius: 26,
              backgroundColor:
                  scheme.onPrimaryContainer.withValues(alpha: 0.12),
              child: Icon(
                Icons.shield_outlined,
                size: 28,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greetingFor(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatDate(DateTime now) {
    const weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekday = weekdayNames[now.weekday - 1];
    final month = monthNames[now.month - 1];
    return '$weekday, $month ${now.day}, ${now.year}';
  }
}

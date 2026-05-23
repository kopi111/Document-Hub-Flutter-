import 'package:flutter/material.dart';

import '../../theme/duty_theme.dart';

/// Editorial loading view for the Library dashboard.
///
/// Honest about uncertainty: a centred indicator below a hairline rule rather
/// than mimicking a layout that may not match what loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DutyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: colors.hairline),
        const Expanded(
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}

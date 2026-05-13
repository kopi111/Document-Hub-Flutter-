import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Pair of compact stat cards sitting side-by-side on the duty dashboard.
///
/// Both cards currently use mock series.
/// TODO: replace `documentsThisWeek` with `/api/v1/audit/access` aggregation,
/// and `reminderCounts` with the upcoming reminders service, once those
/// backend endpoints ship.
class DutyStatsRow extends StatelessWidget {
  final List<int> documentsThisWeek;
  final int activeRemindersTotal;
  final List<int> reminderCounts;

  const DutyStatsRow({
    super.key,
    required this.documentsThisWeek,
    required this.activeRemindersTotal,
    required this.reminderCounts,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: 'Documents this week',
              chart: _DocumentsSparkline(values: documentsThisWeek),
              footer: '${documentsThisWeek.last} today',
            ),
          ),
          const Gap(12),
          Expanded(
            child: _StatCard(
              label: 'Active reminders',
              chart: _RemindersBars(values: reminderCounts),
              footer: _remindersFooter(),
              headline: '$activeRemindersTotal',
            ),
          ),
        ],
      ),
    );
  }

  String _remindersFooter() {
    final next7 = reminderCounts.fold<int>(0, (sum, value) => sum + value);
    return 'next 7 days · $next7';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final Widget chart;
  final String footer;
  final String? headline;

  const _StatCard({
    required this.label,
    required this.chart,
    required this.footer,
    this.headline,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(6),
            if (headline != null) ...[
              Text(
                headline!,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Gap(4),
            ],
            SizedBox(height: 48, child: chart),
            const Gap(6),
            Text(
              footer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsSparkline extends StatelessWidget {
  final List<int> values;
  const _DocumentsSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i].toDouble()),
    ];
    final highlightSpot = spots.last;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.32,
            color: scheme.primary,
            barWidth: 2.4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                if (spot == highlightSpot) {
                  return FlDotCirclePainter(
                    radius: 3.6,
                    color: scheme.secondary,
                    strokeWidth: 0,
                  );
                }
                return FlDotCirclePainter(
                  radius: 0,
                  color: scheme.primary,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindersBars extends StatelessWidget {
  final List<int> values;
  const _RemindersBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final ceiling = maxValue == 0 ? 1.0 : maxValue.toDouble();

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceBetween,
        maxY: ceiling,
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 6,
                  borderRadius: BorderRadius.circular(2),
                  color: scheme.secondary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

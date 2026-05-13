import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Grid tile that opens a category and shows its document count.
class CategoryCard extends StatelessWidget {
  final String category;
  final int documentCount;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.documentCount,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tint.withValues(alpha: 0.16),
                tint.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: tint),
              const Gap(8),
              Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: tint,
                ),
              ),
              const Gap(4),
              Text(
                '$documentCount documents',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

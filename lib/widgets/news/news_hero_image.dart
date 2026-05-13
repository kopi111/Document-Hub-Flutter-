import 'package:flutter/material.dart';

class NewsHeroImage extends StatelessWidget {
  const NewsHeroImage({
    super.key,
    required this.imageUrl,
    required this.category,
  });

  final String? imageUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _NewsImagePlaceholder(category: category);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: _buildLoading,
      errorBuilder: (context, error, stackTrace) =>
          _NewsImagePlaceholder(category: category),
    );
  }

  Widget _buildLoading(
    BuildContext context,
    Widget child,
    ImageChunkEvent? progress,
  ) {
    if (progress == null) return child;
    final total = progress.expectedTotalBytes;
    final value = total == null
        ? null
        : progress.cumulativeBytesLoaded / total;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5, value: value),
      ),
    );
  }
}

class _NewsImagePlaceholder extends StatelessWidget {
  const _NewsImagePlaceholder({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.secondaryContainer,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 48,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 6),
          Text(
            category,
            style: TextStyle(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

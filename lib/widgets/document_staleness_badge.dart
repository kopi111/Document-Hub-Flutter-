import 'package:flutter/material.dart';

import '../models/document_cache_state.dart';

class DocumentStalenessBadge extends StatelessWidget {
  const DocumentStalenessBadge({super.key, required this.state});

  final DocumentCacheState state;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(state.status, Theme.of(context).colorScheme);
    if (palette == null) return const SizedBox.shrink();

    return Semantics(
      label: _semanticLabel(),
      excludeSemantics: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          palette.label,
          style: TextStyle(
            color: palette.foreground,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _semanticLabel() {
    final cachedAt = state.cachedAt;
    switch (state.status) {
      case DocumentCacheStatus.live:
        return '';
      case DocumentCacheStatus.cached:
        return 'Cached ${_relativeAge(cachedAt)}';
      case DocumentCacheStatus.expiring:
        return 'Cache expiring soon, ${_relativeAge(cachedAt)}';
      case DocumentCacheStatus.expired:
        return 'Cache expired, not available offline';
      case DocumentCacheStatus.updated:
        return 'Server has an updated version';
    }
  }

  String _relativeAge(DateTime? cachedAt) {
    if (cachedAt == null) return '';
    final delta = DateTime.now().difference(cachedAt);
    if (delta.inDays >= 1) {
      return '${delta.inDays} ${delta.inDays == 1 ? 'day' : 'days'} ago';
    }
    if (delta.inHours >= 1) {
      return '${delta.inHours} ${delta.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    return 'just now';
  }

  _BadgePalette? _paletteFor(DocumentCacheStatus status, ColorScheme scheme) {
    switch (status) {
      case DocumentCacheStatus.live:
        return null;
      case DocumentCacheStatus.cached:
        return _BadgePalette(
          label: 'Cached',
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
        );
      case DocumentCacheStatus.expiring:
        return const _BadgePalette(
          label: 'Expiring',
          background: Color(0xFFFFE0B2),
          foreground: Color(0xFF8B5A00),
        );
      case DocumentCacheStatus.expired:
        return const _BadgePalette(
          label: 'Expired',
          background: Color(0xFFE0E0E0),
          foreground: Color(0xFF616161),
        );
      case DocumentCacheStatus.updated:
        return const _BadgePalette(
          label: 'Updated',
          background: Color(0xFFFFCDD2),
          foreground: Color(0xFFB71C1C),
        );
    }
  }
}

class _BadgePalette {
  final String label;
  final Color background;
  final Color foreground;

  const _BadgePalette({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

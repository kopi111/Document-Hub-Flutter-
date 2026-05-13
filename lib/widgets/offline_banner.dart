import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    required this.connectivity,
    required this.child,
  });

  final ConnectivityService connectivity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: connectivity.onlineStateStream,
      initialData: true,
      builder: (context, snapshot) {
        final online = snapshot.data ?? true;
        if (online) return child;
        return _OfflineLayout(child: child);
      },
    );
  }
}

class _OfflineLayout extends StatelessWidget {
  const _OfflineLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final childMedia = media.copyWith(
      padding: media.padding.copyWith(top: 0),
      viewPadding: media.viewPadding.copyWith(top: 0),
    );
    return Column(
      children: [
        const _OfflineBar(),
        Expanded(child: MediaQuery(data: childMedia, child: child)),
      ],
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar();

  static const Color _background = Color(0xFFFFE0B2);
  static const Color _foreground = Color(0xFF8B5A00);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'You are offline. Showing cached documents only.',
      child: Material(
        color: _background,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 16, color: _foreground),
                SizedBox(width: 8),
                Text(
                  'Offline — showing cached documents',
                  style: TextStyle(
                    color: _foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

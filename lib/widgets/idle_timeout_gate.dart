import 'dart:async';

import 'package:flutter/material.dart';

class IdleTimeoutGate extends StatefulWidget {
  static const Duration defaultTimeout = Duration(minutes: 30);

  const IdleTimeoutGate({
    super.key,
    required this.child,
    this.timeout = defaultTimeout,
  });

  final Widget child;
  final Duration timeout;

  @override
  State<IdleTimeoutGate> createState() => _IdleTimeoutGateState();
}

class _IdleTimeoutGateState extends State<IdleTimeoutGate>
    with WidgetsBindingObserver {
  Timer? _idleTimer;
  DateTime? _backgroundedAt;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restartIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _backgroundedAt = DateTime.now();
        _idleTimer?.cancel();
      case AppLifecycleState.resumed:
        _handleAppResumed();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _handleAppResumed() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt != null) {
      final awayDuration = DateTime.now().difference(backgroundedAt);
      if (awayDuration >= widget.timeout) {
        _lockSession();
        return;
      }
    }
    _restartIdleTimer();
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.timeout, _lockSession);
  }

  void _lockSession() {
    if (!mounted || _locked) return;
    _idleTimer?.cancel();
    setState(() => _locked = true);
  }

  void _resumeSession() {
    if (!mounted || !_locked) return;
    setState(() => _locked = false);
    _restartIdleTimer();
  }

  void _registerActivity(PointerEvent _) {
    if (_locked) return;
    _restartIdleTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _registerActivity,
      child: Stack(
        children: [
          widget.child,
          if (_locked)
            Positioned.fill(
              child: _IdleLockScreen(
                timeout: widget.timeout,
                onResume: _resumeSession,
              ),
            ),
        ],
      ),
    );
  }
}

class _IdleLockScreen extends StatelessWidget {
  const _IdleLockScreen({required this.timeout, required this.onResume});

  final Duration timeout;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final minutes = timeout.inMinutes;

    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primaryContainer,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Session paused', style: textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  'The app has been idle for $minutes minutes. '
                  'You will be re-authenticated when you resume.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onResume,
                  icon: const Icon(Icons.lock_open),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Resume session'),
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

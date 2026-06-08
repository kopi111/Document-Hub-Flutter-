import 'package:flutter/material.dart';

import '../../theme/hub_style.dart';

/// The deep-blue gradient header used across the redesigned screens.
///
/// Renders the status-bar-safe gradient band with an optional leading action,
/// a centred title, optional trailing actions, and the three-colour accent
/// stripe along its bottom edge. A faint diagonal sheen gives the band depth
/// without a bespoke painter.
class HubGradientHeader extends StatelessWidget {
  const HubGradientHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.showBack = false,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(gradient: HubStyle.headerGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: _DiagonalSheen()),
          Column(
            children: [
              SizedBox(height: topInset),
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(width: 48, child: _buildLeading(context)),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: HubStyle.onGradient,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _buildTrailing(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HubStyle.accentBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;
    if (showBack) {
      return _HeaderIconButton(
        icon: Icons.arrow_back,
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTrailing() {
    if (actions.isEmpty) return const SizedBox(width: 48);
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }
}

/// A bordered, translucent square icon button matching the header chrome.
class HubHeaderIconButton extends StatelessWidget {
  const HubHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) =>
      _HeaderIconButton(icon: icon, onPressed: onPressed, tooltip: tooltip);
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: HubStyle.onGradient, size: 22),
          ),
        ),
      ),
    );
  }
}

class _DiagonalSheen extends StatelessWidget {
  const _DiagonalSheen();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
      ),
    );
  }
}

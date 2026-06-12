// INTEGRATION: In chat_thread_screen.dart's AppBar overflow menu, add a
// "Disappearing messages" item that calls
//   DisappearingTimerMenu.show(context, _controller)
// to present the timer picker. No other wiring required.

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';

/// Bottom-sheet menu for enabling or disabling per-thread disappearing messages.
///
/// Displays five options (Off / 30 s / 5 m / 1 h / 1 d). The currently active
/// TTL is highlighted. Selecting an option calls
/// [ChatThreadController.setDisappearing] and dismisses the sheet.
class DisappearingTimerMenu extends StatelessWidget {
  const DisappearingTimerMenu({super.key, required this.controller});

  final ChatThreadController controller;

  /// Shows [DisappearingTimerMenu] as a modal bottom sheet and resolves when
  /// the user picks an option or dismisses.
  static Future<void> show(
    BuildContext context,
    ChatThreadController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChatStyle.cardRadius),
        ),
      ),
      builder: (_) => DisappearingTimerMenu(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _Sheet(controller: controller),
    );
  }
}

// ---------------------------------------------------------------------------

class _Sheet extends StatelessWidget {
  const _Sheet({required this.controller});

  final ChatThreadController controller;

  static const _options = <_TimerOption>[
    _TimerOption(label: 'Off', seconds: null),
    _TimerOption(label: '30 seconds', seconds: 30),
    _TimerOption(label: '5 minutes', seconds: 300),
    _TimerOption(label: '1 hour', seconds: 3600),
    _TimerOption(label: '1 day', seconds: 86400),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHeader(),
          ..._options.map(
            (opt) => _OptionRow(
              option: opt,
              active: controller.disappearingTtlSeconds == opt.seconds,
              onTap: () {
                controller.setDisappearing(opt.seconds);
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: ChatStyle.gold,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text('Disappearing Messages', style: ChatStyle.title(size: 16)),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.active,
    required this.onTap,
  });

  final _TimerOption option;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? ChatStyle.gold : ChatStyle.textSecondary,
        size: 22,
      ),
      title: Text(
        option.label,
        style: ChatStyle.body(
          size: 15,
          weight: active ? FontWeight.w600 : FontWeight.w400,
          color: ChatStyle.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _TimerOption {
  const _TimerOption({required this.label, required this.seconds});

  final String label;
  final int? seconds;
}

// INTEGRATION: In chat_thread_screen.dart, call AttachmentMenu.show from the
// '+'/paperclip IconButton in the composer row:
//   AttachmentMenu.show(context,
//     onPhoto:    () => _pickPhoto(controller),
//     onCamera:   () => _openCamera(controller),
//     onFile:     () => _pickFile(controller),
//     onLocation: () => _shareLocation(controller),
//   );
// Wire onPhoto/onCamera to ImagePicker (already in pubspec) and onFile to
// StubFileAttachmentPicker (replace with file_picker: ^8.x for production).

import 'package:flutter/material.dart';

import '../../screens/chat/chat_style.dart';

/// Telegram-style attachment type picker presented as a modal bottom sheet.
///
/// Call [AttachmentMenu.show] from the composer's attachment button. The sheet
/// dismisses itself before invoking the selected callback so the navigation
/// stack stays clean.
class AttachmentMenu {
  AttachmentMenu._();

  static void show(
    BuildContext context, {
    required VoidCallback onPhoto,
    required VoidCallback onCamera,
    required VoidCallback onFile,
    required VoidCallback onLocation,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black26,
      builder: (_) => _AttachmentSheet(
        onPhoto: onPhoto,
        onCamera: onCamera,
        onFile: onFile,
        onLocation: onLocation,
      ),
    );
  }
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({
    required this.onPhoto,
    required this.onCamera,
    required this.onFile,
    required this.onLocation,
  });

  final VoidCallback onPhoto;
  final VoidCallback onCamera;
  final VoidCallback onFile;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: ChatStyle.surface,
            borderRadius: BorderRadius.circular(ChatStyle.cardRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachOption(
                icon: Icons.photo_library_rounded,
                label: 'Photo',
                iconColor: const Color(0xFF7B61FF),
                backgroundColor: const Color(0x247B61FF),
                onTap: onPhoto,
              ),
              _AttachOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                iconColor: const Color(0xFFFF6B6B),
                backgroundColor: const Color(0x24FF6B6B),
                onTap: onCamera,
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'File',
                iconColor: ChatStyle.gold,
                backgroundColor: const Color(0x243390EC),
                onTap: onFile,
              ),
              _AttachOption(
                icon: Icons.location_on_rounded,
                label: 'Location',
                iconColor: const Color(0xFF43A047),
                backgroundColor: const Color(0x2443A047),
                onTap: onLocation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: ChatStyle.body(
              size: 12,
              weight: FontWeight.w500,
              color: ChatStyle.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

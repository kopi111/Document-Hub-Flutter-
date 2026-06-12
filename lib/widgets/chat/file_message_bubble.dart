// INTEGRATION: In chat_thread_screen.dart message builder, render this widget when
// message.type == MessageType.file, inside the same bubble container row used for
// other types. The widget handles its own rounded card and sizing.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/chat/chat_attachment.dart';
import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';

/// Document bubble rendered for messages whose type is [MessageType.file].
///
/// Shows a colour-coded MIME icon, the file name and human-readable size, and a
/// download/open button that invokes [url_launcher] to hand the URL to the OS.
class FileMessageBubble extends StatelessWidget {
  const FileMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final att = message.attachment;
    if (att == null) return const SizedBox.shrink();

    final bubbleColor =
        message.fromMe ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(ChatStyle.bubbleRadius),
        border: Border.all(color: ChatStyle.hairline, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _MimeIcon(mimeType: att.mimeType),
          const SizedBox(width: 10),
          Flexible(child: _FileDetails(attachment: att)),
          const SizedBox(width: 6),
          _OpenButton(url: att.url),
        ],
      ),
    );
  }
}

class _MimeIcon extends StatelessWidget {
  const _MimeIcon({required this.mimeType});

  final String? mimeType;

  (IconData, Color) _typeSpec() {
    final mime = mimeType ?? '';
    if (mime == 'application/pdf') {
      return (Icons.picture_as_pdf_rounded, const Color(0xFFE53935));
    }
    if (mime.startsWith('image/')) {
      return (Icons.image_rounded, const Color(0xFF43A047));
    }
    if (mime.startsWith('video/')) {
      return (Icons.videocam_rounded, const Color(0xFF1E88E5));
    }
    if (mime.startsWith('audio/')) {
      return (Icons.audiotrack_rounded, const Color(0xFF8E24AA));
    }
    if (mime.contains('word') || mime.contains('document')) {
      return (Icons.description_rounded, const Color(0xFF1565C0));
    }
    if (mime.contains('sheet') || mime.contains('excel')) {
      return (Icons.table_chart_rounded, const Color(0xFF2E7D32));
    }
    if (mime.contains('zip') || mime.contains('rar')) {
      return (Icons.folder_zip_rounded, const Color(0xFF6D4C41));
    }
    return (Icons.insert_drive_file_rounded, ChatStyle.gold);
  }

  Color _backgroundFor(Color icon) {
    return Color.fromARGB(
      31,
      (icon.r * 255).round(),
      (icon.g * 255).round(),
      (icon.b * 255).round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeSpec();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _backgroundFor(color),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _FileDetails extends StatelessWidget {
  const _FileDetails({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final size = attachment.readableSize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          attachment.name ?? 'File',
          style: ChatStyle.body(
            size: 13,
            weight: FontWeight.w600,
            color: ChatStyle.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (size.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(size, style: ChatStyle.body(size: 11)),
        ],
      ],
    );
  }
}

class _OpenButton extends StatelessWidget {
  const _OpenButton({required this.url});

  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.download_rounded,
          color: ChatStyle.gold,
          size: 22,
        ),
      ),
    );
  }
}

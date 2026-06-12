// INTEGRATION: In chat_thread_screen.dart, dispatch to ImageMessageBubble from
// the message list builder when msg.type == MessageType.image:
//   case MessageType.image: return ImageMessageBubble(message: msg);
// Wrap each item in standard horizontal padding (ChatStyle.pageInset) as you
// do for text bubbles. No other changes needed — tap-to-open is self-contained.

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';
import 'photo_viewer_screen.dart';

const double _kMaxBubbleWidth = 260.0;
const double _kMinImageHeight = 100.0;
const double _kMaxImageHeight = 320.0;

/// Telegram-style image bubble. Sizes itself from [ChatAttachment.width] /
/// [ChatAttachment.height] and opens [PhotoViewerScreen] on tap.
class ImageMessageBubble extends StatelessWidget {
  const ImageMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildAligned);
  }

  Widget _buildAligned(BuildContext context, BoxConstraints constraints) {
    final bubbleWidth = _bubbleWidth(constraints.maxWidth);
    return Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: _buildBubble(context, bubbleWidth),
    );
  }

  Widget _buildBubble(BuildContext context, double width) {
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: message.fromMe
              ? ChatStyle.outgoingBubble
              : ChatStyle.incomingBubble,
          borderRadius: BorderRadius.circular(ChatStyle.bubbleRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ChatStyle.bubbleRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageFrame(width),
              if (message.text.isNotEmpty) _buildCaption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFrame(double width) {
    final attachment = message.attachment;
    if (attachment == null) return const _ErrorPlaceholder();
    return Hero(
      tag: 'photo-${message.id}',
      child: SizedBox(
        width: width,
        height: _imageHeight(width, attachment.width, attachment.height),
        child: CachedNetworkImage(
          imageUrl: attachment.url,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _LoadingPlaceholder(),
          errorWidget: (_, _, _) => const _ErrorPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildCaption() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
        child: Text(
          message.text,
          style: ChatStyle.body(size: 13, color: ChatStyle.textPrimary),
        ),
      );

  double _bubbleWidth(double availableWidth) =>
      math.min(availableWidth * 0.75, _kMaxBubbleWidth);

  double _imageHeight(double width, int? srcWidth, int? srcHeight) {
    if (srcWidth == null || srcHeight == null || srcWidth == 0) return 180.0;
    return (width * srcHeight / srcWidth).clamp(_kMinImageHeight, _kMaxImageHeight);
  }

  void _openViewer(BuildContext context) {
    final attachment = message.attachment;
    if (attachment == null) return;
    Navigator.of(context).push(
      PhotoViewerScreen.route(
        attachment: attachment,
        caption: message.text.isEmpty ? null : message.text,
        heroTag: 'photo-${message.id}',
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: ChatStyle.surfaceRaised,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ChatStyle.gold,
          ),
        ),
      );
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: ChatStyle.surfaceRaised,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: ChatStyle.textSecondary,
          ),
        ),
      );
}

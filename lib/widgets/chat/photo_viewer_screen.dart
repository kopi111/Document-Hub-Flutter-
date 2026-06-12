// INTEGRATION: PhotoViewerScreen is opened by ImageMessageBubble.onTap via
// PhotoViewerScreen.route(...) — no changes to chat_thread_screen.dart are
// needed. The route uses a Hero keyed to 'photo-<messageId>' shared with the
// bubble, so the image flies from the bubble into the viewer automatically.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/chat/chat_attachment.dart';
import '../../screens/chat/chat_style.dart';

/// Fullscreen image viewer with pinch-zoom ([InteractiveViewer]) and
/// swipe-down-to-dismiss. Opens via [PhotoViewerScreen.route].
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.attachment,
    this.caption,
    this.heroTag,
  });

  final ChatAttachment attachment;
  final String? caption;

  /// Must match the [Hero.tag] used in the source bubble so the fly-in
  /// animation plays. Defaults to the attachment URL when omitted.
  final String? heroTag;

  static Route<void> route({
    required ChatAttachment attachment,
    String? caption,
    String? heroTag,
  }) =>
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => PhotoViewerScreen(
          attachment: attachment,
          caption: caption,
          heroTag: heroTag,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      );

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final _transform = TransformationController();
  double _dragY = 0;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  bool get _atBaseScale =>
      (_transform.value.getMaxScaleOnAxis() - 1.0).abs() < 0.05;

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (!_atBaseScale || d.delta.dy < 0) return;
    setState(() => _dragY += d.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final velocity = d.velocity.pixelsPerSecond.dy;
    if (_dragY > 120 || velocity > 600) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragY = 0);
    }
  }

  String get _effectiveHeroTag =>
      widget.heroTag ?? 'photo-${widget.attachment.url}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Transform.translate(
          offset: Offset(0, _dragY),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildViewer(),
              _buildCloseButton(),
              if (widget.caption != null) _buildCaptionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewer() => InteractiveViewer(
        transformationController: _transform,
        minScale: 0.5,
        maxScale: 8.0,
        child: Center(
          child: Hero(
            tag: _effectiveHeroTag,
            child: CachedNetworkImage(
              imageUrl: widget.attachment.url,
              fit: BoxFit.contain,
              placeholder: (_, _) => const CircularProgressIndicator(
                color: ChatStyle.gold,
              ),
              errorWidget: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 64,
              ),
            ),
          ),
        ),
      );

  Widget _buildCloseButton() => SafeArea(
        child: Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );

  Widget _buildCaptionBar() => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _CaptionBar(caption: widget.caption!),
      );
}

class _CaptionBar extends StatelessWidget {
  const _CaptionBar({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Colors.transparent],
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 32, 16, bottomPadding + 16),
      child: Text(
        caption,
        style: ChatStyle.body(color: Colors.white, size: 14),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

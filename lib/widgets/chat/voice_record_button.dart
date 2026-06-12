// INTEGRATION: Drop VoiceRecordButton(controller: controller, recorder: StubVoiceRecorder())
// into ChatThreadScreen's input row to the right of the text field, replacing or
// sitting beside the send button. For production, swap StubVoiceRecorder with a
// RecordVoiceRecorder (package:record ^5.x, add to pubspec.yaml).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/chat/message_type.dart';
import '../../screens/chat/chat_style.dart';
import '../../screens/chat/chat_thread_controller.dart';
import '../../services/chat/voice_recorder.dart';

class VoiceRecordButton extends StatefulWidget {
  const VoiceRecordButton({
    super.key,
    required this.controller,
    required this.recorder,
  });

  final ChatThreadController controller;
  final VoiceRecorder recorder;

  @override
  State<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends State<VoiceRecordButton> {
  static const double _cancelThresholdDx = -80.0;
  static const Color _recordingRed = Color(0xFFE53935);

  bool _recording = false;
  bool _slidingToCancel = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _stopTicker();
    _removeOverlay();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
      _overlay?.markNeedsBuild();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(
      builder: (_) => _RecordingOverlay(
        elapsedSeconds: _elapsedSeconds,
        slidingToCancel: _slidingToCancel,
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  Future<void> _startRecording() async {
    try {
      await widget.recorder.start();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _recording = true;
      _slidingToCancel = false;
      _elapsedSeconds = 0;
    });
    _startTicker();
    _showOverlay();
  }

  Future<void> _finishRecording() async {
    _stopTicker();
    _removeOverlay();
    if (!_recording) return;
    setState(() => _recording = false);
    if (_slidingToCancel) {
      await widget.recorder.cancel();
      return;
    }
    try {
      final attachment = await widget.recorder.stop();
      if (mounted) {
        widget.controller.sendAttachment(attachment, type: MessageType.voice);
      }
    } catch (_) {
      // Duration too short or recorder already in invalid state; discard silently.
    }
  }

  void _onLongPressStart(LongPressStartDetails _) => _startRecording();

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_recording) return;
    final sliding = details.offsetFromOrigin.dx < _cancelThresholdDx;
    if (sliding == _slidingToCancel) return;
    setState(() => _slidingToCancel = sliding);
    _overlay?.markNeedsBuild();
  }

  void _onLongPressEnd(LongPressEndDetails _) => _finishRecording();

  void _onLongPressCancel() => _finishRecording();

  Color get _buttonColor =>
      _recording && !_slidingToCancel ? _recordingRed : ChatStyle.gold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressMoveUpdate: _onLongPressMoveUpdate,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _buttonColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 22),
      ),
    );
  }
}

class _RecordingOverlay extends StatelessWidget {
  const _RecordingOverlay({
    required this.elapsedSeconds,
    required this.slidingToCancel,
  });

  final int elapsedSeconds;
  final bool slidingToCancel;

  String get _timerLabel {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          height: 60,
          color: ChatStyle.surface,
          padding: const EdgeInsets.symmetric(horizontal: ChatStyle.pageInset),
          child: Row(
            children: [
              Opacity(
                opacity: elapsedSeconds.isEven ? 1.0 : 0.25,
                child: const Icon(
                  Icons.circle,
                  color: Color(0xFFE53935),
                  size: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timerLabel,
                style: ChatStyle.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: const Color(0xFFE53935),
                ),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: slidingToCancel ? 0.25 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.chevron_left,
                      color: ChatStyle.textSecondary,
                      size: 18,
                    ),
                    Text(
                      'Slide to cancel',
                      style: ChatStyle.body(
                        size: 13,
                        color: ChatStyle.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ChatStyle.pageInset),
            ],
          ),
        ),
      ),
    );
  }
}

// INTEGRATION: In ChatThreadScreen's bubble renderer, check
// message.type == MessageType.voice and render VoiceMessageBubble(message: message)
// instead of the plain text bubble. Real audio playback: add package:just_audio ^0.9.x
// to pubspec.yaml, then replace _play/_pause with AudioPlayer calls and feed real
// amplitude data from the player's positionStream into _progress.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chat/chat_message.dart';
import '../../screens/chat/chat_style.dart';

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  static const int _tickIntervalMs = 100;

  bool _playing = false;
  double _progress = 0.0;
  Timer? _ticker;

  int get _durationMs {
    final d = widget.message.attachment?.durationMs;
    if (d == null) return 3000;
    return d < 100 ? 100 : (d > 600000 ? 600000 : d);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _togglePlayback() => _playing ? _pause() : _play();

  void _play() {
    if (_progress >= 1.0) _progress = 0.0;
    setState(() => _playing = true);
    _ticker = Timer.periodic(
      const Duration(milliseconds: _tickIntervalMs),
      (_) {
        final next = _progress + _tickIntervalMs / _durationMs;
        setState(() => _progress = math.min(1.0, next));
        if (_progress >= 1.0) _resetAfterPlayback();
      },
    );
  }

  void _pause() {
    _ticker?.cancel();
    setState(() => _playing = false);
  }

  void _resetAfterPlayback() {
    _ticker?.cancel();
    setState(() {
      _playing = false;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fromMe = widget.message.fromMe;
    final waveform = widget.message.attachment?.waveform ?? _defaultWaveform;

    return Container(
      decoration: BoxDecoration(
        color: fromMe ? ChatStyle.outgoingBubble : ChatStyle.incomingBubble,
        borderRadius: BorderRadius.circular(ChatStyle.bubbleRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlayPauseButton(playing: _playing, onTap: _togglePlayback),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 32,
                child: CustomPaint(
                  painter: _WaveformPainter(
                    waveform: waveform,
                    progress: _progress,
                    playedColor: ChatStyle.gold,
                    unplayedColor:
                        fromMe ? const Color(0xFFB2DFDB) : ChatStyle.hairline,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_durationMs),
                style: ChatStyle.body(size: 11, color: ChatStyle.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDuration(int ms) {
    final total = ms ~/ 1000;
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  static final List<double> _defaultWaveform = List.generate(50, (i) {
    final v = 0.2 + 0.6 * math.sin(i / 50 * math.pi * 3);
    return math.min(1.0, math.max(0.1, v));
  });
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: ChatStyle.gold,
          shape: BoxShape.circle,
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          color: ChatStyle.onGold,
          size: 22,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.playedColor,
    required this.unplayedColor,
  });

  final List<double> waveform;
  final double progress;
  final Color playedColor;
  final Color unplayedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;
    final barCount = waveform.length;
    final totalGapWidth = size.width * 0.3;
    final barWidth = (size.width - totalGapWidth) / barCount;
    final gap = totalGapWidth / math.max(1, barCount - 1);
    final midY = size.height / 2;
    final playedPaint = Paint()..color = playedColor;
    final unplayedPaint = Paint()..color = unplayedColor;

    for (var i = 0; i < barCount; i++) {
      final x = i * (barWidth + gap);
      final barHeight = math.max(
        2.0,
        math.min(size.height, size.height * 0.9 * waveform[i]),
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, midY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        rect,
        i / barCount < progress ? playedPaint : unplayedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.waveform != waveform;
}

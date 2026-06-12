import 'dart:math' as math;

import '../../models/chat/chat_attachment.dart';

// INTEGRATION: Replace StubVoiceRecorder with RecordVoiceRecorder backed by
// `package:record ^5.x` (add to pubspec.yaml). RecordVoiceRecorder.start() calls
// record.start(path: tmpPath, encoder: AudioEncoder.aacLc, samplingRate: 44100);
// stop() calls record.stop(), reads the file, and substitutes real amplitude
// samples (polled via record.amplitude) for the synthetic waveform below.

abstract class VoiceRecorder {
  Future<void> start();
  Future<ChatAttachment> stop();
  Future<void> cancel();
}

class StubVoiceRecorder implements VoiceRecorder {
  DateTime? _startedAt;
  bool _active = false;
  int _generation = 0;

  @override
  Future<void> start() async {
    if (_active) throw StateError('Recording already in progress.');
    _startedAt = DateTime.now();
    _active = true;
  }

  @override
  Future<ChatAttachment> stop() async {
    if (!_active) throw StateError('No recording in progress.');
    final started = _startedAt!;
    _active = false;
    _startedAt = null;
    final id = ++_generation;
    final rawMs = DateTime.now().difference(started).inMilliseconds;
    final durationMs = rawMs < 500 ? 500 : (rawMs > 120000 ? 120000 : rawMs);
    return ChatAttachment(
      url: 'stub://voice-note-$id.m4a',
      mimeType: 'audio/m4a',
      durationMs: durationMs,
      waveform: _syntheticWaveform(seed: id),
    );
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _startedAt = null;
  }

  static List<double> _syntheticWaveform({required int seed, int barCount = 50}) {
    final rng = math.Random(seed);
    return List.generate(barCount, (i) {
      final envelope = math.sin(i / barCount * math.pi);
      final noise = 0.5 + 0.5 * rng.nextDouble();
      return math.min(1.0, math.max(0.05, 0.1 + 0.9 * envelope * noise));
    });
  }
}

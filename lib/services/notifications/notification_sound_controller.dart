import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'notification_sound_preferences.dart';

/// Single source of truth for the notification chime: holds the on/off
/// preference and plays the sound when a new bulletin arrives.
///
/// The bell calls [chime] on genuine new arrivals; the About screen reads
/// [enabled] and flips it with [setEnabled]. Listeners (the About switch)
/// rebuild when the preference changes.
class NotificationSoundController extends ChangeNotifier {
  NotificationSoundController._();

  static final NotificationSoundController instance =
      NotificationSoundController._();

  static const _chimeAsset = 'sounds/notification.wav';

  final NotificationSoundPreferences _preferences =
      NotificationSoundPreferences();
  final AudioPlayer _player = AudioPlayer(playerId: 'jcf-notification-chime');

  bool _enabled = true;
  bool _loaded = false;

  bool get enabled => _enabled;

  /// Loads the saved preference once, before the first chime can fire.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    _enabled = await _preferences.isSoundEnabled();
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (enabled == _enabled) return;
    _enabled = enabled;
    notifyListeners();
    await _preferences.setSoundEnabled(enabled);
  }

  /// Plays the chime when sound is enabled; a no-op otherwise. Best-effort —
  /// a playback failure (e.g. a browser autoplay block) never surfaces.
  Future<void> chime() async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource(_chimeAsset));
    } catch (_) {
      // Best-effort: the badge still updates even if the sound cannot play.
    }
  }
}

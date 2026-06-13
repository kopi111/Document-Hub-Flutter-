import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the notification chime is enabled. Defaults to on so
/// officers hear new bulletins until they choose to silence them.
class NotificationSoundPreferences {
  static const _soundEnabledKey = 'notification_sound_enabled_v1';

  Future<bool> isSoundEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundEnabledKey, enabled);
  }
}

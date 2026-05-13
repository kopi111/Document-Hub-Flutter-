import 'package:shared_preferences/shared_preferences.dart';

class FirstLaunchPreferences {
  static const _privacyNoticeAcknowledgedKey = 'privacy_notice_acknowledged_v2';
  static const _eulaAcceptedKey = 'eula_accepted_v2';

  Future<bool> hasAcknowledgedPrivacyNotice() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_privacyNoticeAcknowledgedKey) ?? false;
  }

  Future<void> recordPrivacyNoticeAcknowledged() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_privacyNoticeAcknowledgedKey, true);
  }

  Future<bool> hasAcceptedEula() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_eulaAcceptedKey) ?? false;
  }

  Future<void> recordEulaAccepted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_eulaAcceptedKey, true);
  }
}

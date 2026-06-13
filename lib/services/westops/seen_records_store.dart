import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which WestOps records the officer has already opened, so the
/// "NEW" tag on a freshly-filed record clears once it has actually been viewed
/// instead of standing on the newest record forever. Persisted so it survives
/// restarts and reloads.
class SeenRecordsStore extends ChangeNotifier {
  SeenRecordsStore._();

  static final SeenRecordsStore instance = SeenRecordsStore._();

  static const _key = 'seen_record_ids_v1';

  final Set<String> _seen = {};
  bool _loaded = false;

  /// Loads the saved ids once, before the lists first decide what is "NEW".
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final preferences = await SharedPreferences.getInstance();
    _seen.addAll(preferences.getStringList(_key) ?? const []);
    notifyListeners();
  }

  bool isSeen(String id) => _seen.contains(id);

  /// Records that [id] has been viewed and persists the change.
  Future<void> markSeen(String id) async {
    if (!_seen.add(id)) return;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, _seen.toList());
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/notifications/app_notification.dart';
import '../api/api_config.dart';

/// Fetches officer push notifications from the backend `/v1/notifications` feed.
/// Returns an empty list on any failure so the bell never breaks when the API is
/// unreachable.
class ApiNotificationsClient {
  ApiNotificationsClient({http.Client? client, ApiConfig config = const ApiConfig()})
      : _client = client ?? http.Client(),
        _config = config;

  final http.Client _client;
  final ApiConfig _config;

  Future<List<AppNotification>> fetch() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/notifications?page_size=50');
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return const [];
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>? ?? const [];
      return items
          .map((item) => AppNotification.fromApiJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Marks a single backend notification read so it stays cleared across polls
  /// and app restarts. Best-effort: failures are swallowed like [fetch].
  Future<void> markRead(String remoteId) async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/notifications/$remoteId/read');
      await _client.post(uri).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Best-effort; the local dismissal already cleared it for this session.
    }
  }

  /// Marks every backend notification read ("mark all read").
  Future<void> markAllRead() async {
    try {
      final uri = Uri.parse('${_config.baseUrl}/notifications/read-all');
      await _client.post(uri).timeout(const Duration(seconds: 6));
    } catch (_) {
      // Best-effort.
    }
  }
}

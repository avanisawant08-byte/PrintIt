import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.read(apiProvider);
  return NotificationService(apiClient);
});

class NotificationService {
  final ApiClient _apiClient;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService(this._apiClient);

  /// Call this after login to register the FCM token with the backend.
  /// All notification display logic is now handled in main.dart.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('push_notifications_enabled') ?? true;
    
    if (!isEnabled) {
      debugPrint("ℹ️ Push notifications are disabled in settings, skipping FCM registration.");
      return;
    }

    // 1. Get the FCM token and send to server
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint("✅ FCM Token: ${token.substring(0, 20)}...");
        await _sendTokenToServer(token);
      } else {
        debugPrint("⚠️ FCM token is null");
      }
    } catch (e) {
      debugPrint("❌ Error getting FCM token: $e");
    }

    // 2. Listen to token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint("🔄 FCM token refreshed");
      _sendTokenToServer(newToken);
    });
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _apiClient.post('/auth/fcm-token', data: {'fcm_token': token});
      debugPrint("✅ FCM token sent to server");
    } catch (e) {
      debugPrint("❌ Failed to send FCM token: $e");
    }
  }

  Future<void> deleteTokenFromServer() async {
    try {
      await _apiClient.delete('/auth/fcm-token');
      debugPrint("✅ FCM token removed from server");
    } catch (e) {
      debugPrint("❌ Failed to remove FCM token from server: $e");
    }
  }
}

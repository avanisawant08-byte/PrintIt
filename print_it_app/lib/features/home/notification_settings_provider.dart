import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/services/notification_service.dart';

class NotificationSettingsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSettings();
    return true; // Default until loaded
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('push_notifications_enabled') ?? true;
  }

  Future<void> toggle(bool isEnabled) async {
    // Optimistically update UI
    state = isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications_enabled', isEnabled);

    if (isEnabled) {
      // Re-initialize to get a new token
      await ref.read(notificationServiceProvider).initialize();
    } else {
      // Delete token to stop receiving notifications
      try {
        await ref.read(notificationServiceProvider).deleteTokenFromServer();
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        // Handle gracefully if token already deleted or error occurs
      }
    }
  }
}

final notificationSettingsProvider = NotifierProvider<NotificationSettingsNotifier, bool>(() {
  return NotificationSettingsNotifier();
});

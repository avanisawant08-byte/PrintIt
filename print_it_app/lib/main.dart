import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/auth_provider.dart';
import 'firebase_options.dart';

// Global key to show Snackbars without context
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global instance — accessible from notification_service.dart
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// The notification channel definition
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'print_it_channel',
  'PrintIt Notifications',
  description: 'Notifications for PrintIt order updates',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ===== Set up local notifications on mobile =====
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      debugPrint('✅ Notification channel created');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await flutterLocalNotificationsPlugin.initialize(
        settings: const InitializationSettings(android: androidSettings),
      );
      debugPrint('✅ Local notifications initialized');

      await androidPlugin?.requestNotificationsPermission();
      debugPrint('✅ Notification permission requested');

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground message: ${message.notification?.title}');
        final notification = message.notification;
        if (notification != null) {
          flutterLocalNotificationsPlugin.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'print_it_channel',
                'PrintIt Notifications',
                channelDescription: 'Notifications for PrintIt order updates',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                showWhen: true,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📩 Notification tap opened app: ${message.data}');
      });
    } catch (e) {
      debugPrint('Mobile native notification setup error: $e');
    }
  } else {
    // Web platform initialization
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Web Firebase initialized');
    } catch (e) {
      debugPrint('Web Firebase initialization skipped/failed: $e');
    }
  }

  // Pre-hydrate persistent user session from local storage before rendering first frame
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userDataStr = prefs.getString('user_data');
    if (token != null && userDataStr != null && userDataStr.isNotEmpty) {
      final decoded = jsonDecode(userDataStr);
      if (decoded is Map) {
        AuthNotifier.initialCachedUser = Map<String, dynamic>.from(decoded);
        debugPrint('✅ Initial session hydrated for user: ${AuthNotifier.initialCachedUser?['phone'] ?? AuthNotifier.initialCachedUser?['email']}');
      }
    }
  } catch (e) {
    debugPrint('Session pre-hydration notice: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Print It',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      routerConfig: appRouter,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

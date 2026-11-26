import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import 'api_service.dart';

/// Top-level background message handler required by firebase_messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final options = DefaultFirebaseOptions.currentPlatformOrNull;
  if (options == null) return;
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: options);
  }
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'fitmaxim_default_channel',
    'FitMaxim Notifications',
    description: 'Gym updates, renewal alerts, and offers',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static Future<void>? _initFuture;
  static String? _currentToken;
  static bool _hasPendingTap = false;

  /// Called when a push notification arrives while the app is in the foreground.
  static VoidCallback? onForegroundMessage;

  /// Called when the user taps a push notification (foreground, background, or terminated).
  static VoidCallback? onNotificationTapped;

  static bool get isInitialized => _initialized;
  static String? get currentToken => _currentToken;

  /// Initializes Firebase, local notifications, and FCM listeners.
  /// Gracefully no-ops on platforms without Firebase options configured yet.
  static Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  static Future<void> _doInit() async {
    final options = DefaultFirebaseOptions.currentPlatformOrNull;
    if (options == null) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options).timeout(const Duration(seconds: 5));
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Show banner, badge, and sound when a notification arrives in the foreground on iOS.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 5));

      // Initialize local notifications for Android foreground display & tap handling.
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (_) => _handleTap(),
      );

      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_androidChannel);
      }

      // Foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        onForegroundMessage?.call();
        // On iOS, setForegroundNotificationPresentationOptions already renders the system banner.
        if (Platform.isAndroid && message.notification != null) {
          _showLocalNotification(message);
        }
      });

      // Notification tapped from background
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _handleTap());

      // Notification tapped from terminated state
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 5), onTimeout: () => null);
      if (initialMessage != null) {
        _hasPendingTap = true;
      }

      // Keep backend updated when FCM rotates the device token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        debugPrint('[FCM] Token refreshed: $newToken');
        _syncTokenToBackend(newToken);
      });

      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] Initialization skipped: $e');
    }
  }

  /// Consumes any pending notification tap from a cold start once navigation is mounted.
  static void consumePendingTap() {
    if (_hasPendingTap) {
      _hasPendingTap = false;
      onNotificationTapped?.call();
    }
  }

  static void _handleTap() {
    if (onNotificationTapped != null) {
      onNotificationTapped!.call();
    } else {
      _hasPendingTap = true;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;
    await _localNotifications.show(
      notif.hashCode,
      notif.title ?? 'FitMaxim',
      notif.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Requests OS notification permission, retrieves the FCM token, and registers
  /// it with the GymOS backend (best-effort).
  static Future<void> registerForMember() async {
    if (!_initialized) {
      await init();
    }
    if (!_initialized) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Notification permission denied by user.');
        return;
      }

      // On iOS, APNs token is required before FCM can vend a token on physical devices.
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('[FCM] APNs token not yet available (expected on iOS Simulator without APNs).');
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _currentToken = token;
        debugPrint('[FCM] Device token: $token');
        await _syncTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Could not register device token: $e');
    }
  }

  /// Best-effort unregistration on sign-out so logged-out devices stop receiving alerts.
  static Future<void> unregisterForMember() async {
    if (!_initialized) return;
    final tokenToRemove = _currentToken;
    _currentToken = null;
    if (tokenToRemove != null) {
      try {
        await ApiService.post('/portal/device-token/remove', body: {
          'token': tokenToRemove,
          'platform': Platform.isIOS ? 'ios' : 'android',
        });
      } catch (_) {
        // Ignore network errors during logout.
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {
      // Ignore if token deletion fails (e.g. iOS Simulator without APNs).
    }
  }

  static Future<void> _syncTokenToBackend(String token) async {
    try {
      await ApiService.post('/portal/device-token', body: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // Best-effort: never disrupt app flow if backend endpoint is not yet live.
    }
  }
}

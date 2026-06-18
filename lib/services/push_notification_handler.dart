import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationPlatform {
  android,
  ios,
  web,
}

class PushNotificationPayload {
  final String? bookingId;
  final String? movieId;
  final String? promotionId;
  final String type;
  final String? title;
  final String? body;

  PushNotificationPayload({
    this.bookingId,
    this.movieId,
    this.promotionId,
    required this.type,
    this.title,
    this.body,
  });

  static PushNotificationPayload fromMap(Map<String, dynamic> data) {
    return PushNotificationPayload(
      bookingId: data['bookingId'] as String?,
      movieId: data['movieId'] as String?,
      promotionId: data['promotionId'] as String?,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String?,
      body: data['body'] as String?,
    );
  }

  NotificationRoute get route {
    return switch (type) {
      'booking' || 'payment' || 'ticket' => NotificationRoute.booking(bookingId ?? ''),
      'movie' => NotificationRoute.movie(movieId ?? ''),
      'promotion' => NotificationRoute.promotion(promotionId ?? ''),
      _ => NotificationRoute.home(),
    };
  }
}

class NotificationRoute {
  final String path;
  final Map<String, String> queryParams;

  NotificationRoute({required this.path, this.queryParams = const {}});

  factory NotificationRoute.home() => NotificationRoute(path: '/');
  factory NotificationRoute.booking(String bookingId) => NotificationRoute(
    path: '/booking/$bookingId',
    queryParams: {'bookingId': bookingId},
  );
  factory NotificationRoute.movie(String movieId) => NotificationRoute(
    path: '/movie/$movieId',
    queryParams: {'movieId': movieId},
  );
  factory NotificationRoute.promotion(String promotionId) => NotificationRoute(
    path: '/promotion/$promotionId',
    queryParams: {'promotionId': promotionId},
  );
}

typedef NotificationTapCallback = void Function(NotificationRoute route);

class PushNotificationHandler {
  static PushNotificationHandler? _instance;
  static PushNotificationHandler get instance => _instance!;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationTapCallback? onNotificationTap;
  String? _currentToken;
  NotificationPlatform _platform = NotificationPlatform.android;
  bool _isInitialized = false;
  bool _permissionGranted = false;

  PushNotificationHandler._internal({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  static Future<PushNotificationHandler> initialize({
    NotificationTapCallback? onNotificationTap,
  }) async {
    _instance ??= PushNotificationHandler._internal();
    await _instance!._initialize(onNotificationTap: onNotificationTap);
    return _instance!;
  }

  Future<void> _initialize({NotificationTapCallback? onNotificationTap}) async {
    if (_isInitialized) return;

    this.onNotificationTap = onNotificationTap;

    await Firebase.initializeApp();

    _detectPlatform();
    await _setupLocalNotifications();
    await _setupFirebaseMessaging();
    _setupTokenRefreshListener();

    _isInitialized = true;
  }

  void _detectPlatform() {
    _platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => NotificationPlatform.ios,
      TargetPlatform.android => NotificationPlatform.android,
      _ => NotificationPlatform.android,
    };
  }

  Future<void> _setupLocalNotifications() async {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  Future<void> _setupFirebaseMessaging() async {
    final settings = await requestPermission();
    if (!settings) return;

    _currentToken = await _messaging.getToken();
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    if (_platform == NotificationPlatform.ios) {
      await _messaging.setAutoInitEnabled(true);
    }
  }

  void _setupTokenRefreshListener() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _permissionGranted = switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional => true,
      _ => false,
    };

    return _permissionGranted;
  }

  String? get currentToken => _currentToken;

  NotificationPlatform get platform => _platform;

  bool get isInitialized => _isInitialized;

  Future<String?> getToken() async {
    if (!_isInitialized) return null;
    _currentToken ??= await _messaging.getToken();
    return _currentToken;
  }

  void _onTokenRefresh(String newToken) {
    _currentToken = newToken;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification == null) return;
    _showLocalNotification(
      title: message.notification!.title ?? 'CineLuxe',
      body: message.notification!.body ?? '',
      payload: message.data,
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = Map<String, dynamic>.from(
        Uri.splitQueryString(payload).map(
          (key, value) => MapEntry(key, value),
        ),
      );
      final notification = PushNotificationPayload.fromMap(data);
      onNotificationTap?.call(notification.route);
    } catch (_) {
      onNotificationTap?.call(NotificationRoute.home());
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'cineluxe_notifications',
      'CineLuxe Notifications',
      channelDescription: 'Thông báo từ CineLuxe Cinema Booking',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payloadString = payload?.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payloadString,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'token_store.dart';

// 백그라운드 메시지 핸들러 (top-level function이어야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('Background message: ${message.notification?.title}');
  } catch (e) {
    debugPrint('Background handler error: $e');
  }
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseMessaging? _messaging;
  FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  // 알림 채널 (Android와 동일)
  static const AndroidNotificationChannel chargeChannel = AndroidNotificationChannel(
    'charge_channel',
    '충전 알림',
    description: '충전 관련 알림을 받습니다',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel giftChannel = AndroidNotificationChannel(
    'gift_channel',
    '선물 알림',
    description: '선물 관련 알림을 받습니다',
    importance: Importance.high,
  );

  bool _isInitialized = false;

  /// Firebase 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firebase가 이미 초기화되었는지 확인
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isInitialized = true;

      // 백그라운드 핸들러 설정
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 알림 권한 요청 (iOS)
      await _requestPermission();

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // 포그라운드 메시지 리스너
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 알림 탭 시 앱 열릴 때
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      _isInitialized = false;
      // Firebase 초기화 실패해도 앱은 계속 실행 (푸시 기능만 비활성화)
    }
  }

  /// Firebase 초기화 확인 및 재시도
  Future<bool> ensureInitialized() async {
    if (_isInitialized && Firebase.apps.isNotEmpty) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Firebase ensureInitialized error: $e');
      return false;
    }
  }

  /// 알림 권한 요청
  Future<void> _requestPermission() async {
    final settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Android 알림 채널 생성
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(chargeChannel);
      await androidPlugin.createNotificationChannel(giftChannel);
    }
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? '',
        body: notification.body ?? '',
        channelId: chargeChannel.id,
      );
    }
  }

  /// 알림 탭으로 앱 열릴 때
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.data}');
    // 필요시 특정 화면으로 이동하는 로직 추가
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == chargeChannel.id ? chargeChannel.name : giftChannel.name,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    try {
      final token = await messaging.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// 서버에 FCM 토큰 등록 (일반 사용자)
  Future<void> registerUserToken() async {
    try {
      final token = await getToken();
      final userId = await TokenStore.getUserId();

      if (token != null && userId != null && userId.isNotEmpty) {
        await _apiService.registerUserToken(userId, token);
        debugPrint('User token registered successfully');
      }
    } catch (e) {
      debugPrint('Error registering user token: $e');
    }
  }

  /// 서버에 FCM 토큰 등록 (관리자)
  Future<void> registerAdminToken() async {
    try {
      final token = await getToken();

      if (token != null) {
        await _apiService.registerAdminToken(token, 'admin');
        debugPrint('Admin token registered successfully');
      }
    } catch (e) {
      debugPrint('Error registering admin token: $e');
    }
  }

  /// 토큰 갱신 리스너
  void listenToTokenRefresh() {
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM Token refreshed: $newToken');

      final userId = await TokenStore.getUserId();
      final rate = await TokenStore.getUserRate();

      if (userId != null && userId.isNotEmpty) {
        if (rate == 'ADMIN') {
          await registerAdminToken();
        } else {
          await registerUserToken();
        }
      }
    });
  }

  /// 충전 완료 로컬 알림 (Android와 동일)
  Future<void> notifyChargeComplete(int amount) async {
    await _showLocalNotification(
      title: '충전 신청 완료',
      body: '${_formatAmount(amount)} 접수됨',
      channelId: chargeChannel.id,
    );
  }

  /// 선물 수신 로컬 알림
  Future<void> notifyGiftReceived(String senderName, int amount) async {
    await _showLocalNotification(
      title: '포인트 선물 도착',
      body: '$senderName님이 ${_formatAmount(amount)}를 선물했습니다',
      channelId: giftChannel.id,
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} p';
  }
}

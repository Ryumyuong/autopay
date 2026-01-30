import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();

  // 딥링크로 전달된 user_id를 저장
  String? pendingPaymentUserId;

  // 결제 딥링크 스트림 컨트롤러
  final _paymentStreamController = StreamController<String>.broadcast();
  Stream<String> get paymentStream => _paymentStreamController.stream;

  /// 딥링크 초기화 및 리스너 설정
  Future<void> initialize() async {
    // 앱이 딥링크로 열렸을 때 (콜드 스타트)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // 앱이 실행 중일 때 딥링크 수신 (웜 스타트)
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    }, onError: (e) {
      debugPrint('Deep link stream error: $e');
    });
  }

  /// 딥링크 처리
  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    String? userId;

    // autopay://payment?user_id=xxx 형식 처리
    if (uri.scheme == 'autopay' && uri.host == 'payment') {
      userId = uri.queryParameters['user_id'];
    }
    // http://223.130.146.117:8080/pay.html?user_id=xxx 형식 처리
    else if ((uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host == '223.130.146.117' &&
             uri.path.contains('pay.html')) {
      userId = uri.queryParameters['user_id'];
    }

    if (userId != null && userId.isNotEmpty) {
      pendingPaymentUserId = userId;
      debugPrint('Payment user_id: $userId');
      // 스트림으로도 전달 (앱이 이미 실행 중일 때)
      _paymentStreamController.add(userId);
    }
  }

  /// 대기 중인 결제 user_id 가져오기 (한 번 가져오면 초기화)
  String? consumePendingPaymentUserId() {
    final userId = pendingPaymentUserId;
    pendingPaymentUserId = null;
    return userId;
  }

  /// 대기 중인 결제가 있는지 확인
  bool get hasPendingPayment => pendingPaymentUserId != null;
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 더썸데이 쇼핑몰 서버에 FCM 토큰을 등록/해제한다.
///
/// 오토페이 서버와 더썸데이는 같은 Firebase 프로젝트(autoagence-34831)를 쓰기 때문에
/// 토큰 하나로 양쪽 모두에서 이 앱으로 푸시를 보낼 수 있다.
/// 등록에 실패해도 오토페이 기능에는 영향을 주지 않는다.
class SomedayPushService {
  // TODO 도메인 + HTTPS 로 전환할 것
  static const String baseUrl = 'http://110.165.17.240:8088';

  // 더썸데이 서버 application.properties 의 push.api-key 와 같은 값이어야 한다
  static const String _apiKey = 'someday-push-6f2a91c47b';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': _apiKey,
    },
  ));

  /// 토큰 등록. 실패해도 예외를 밖으로 던지지 않는다.
  static Future<void> register(String autoPayId, String token) async {
    try {
      await _dio.post('/api/device/register', data: {
        'autoPayId': autoPayId,
        'token': token,
      });
      debugPrint('SomedayPush: register ok - $autoPayId');
    } catch (e) {
      debugPrint('SomedayPush: register failed - $e');
    }
  }

  /// 토큰 해제(로그아웃). 실패해도 예외를 밖으로 던지지 않는다.
  static Future<void> unregister(String autoPayId) async {
    try {
      await _dio.post('/api/device/unregister', data: {
        'autoPayId': autoPayId,
      });
      debugPrint('SomedayPush: unregister ok - $autoPayId');
    } catch (e) {
      debugPrint('SomedayPush: unregister failed - $e');
    }
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  // iOS에서 접근성 옵션 설정 (백그라운드에서도 접근 가능)
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  static const _keyUserId = 'user_id';
  static const _keyUserName = 'user_name';
  static const _keyUserRate = 'user_rate';
  static const _keyFcmToken = 'fcm_token';
  static const _keyIsLoggedIn = 'is_logged_in';

  // 사용자 ID 저장/조회
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  // 사용자 이름 저장/조회
  static Future<void> saveUserName(String userName) async {
    await _storage.write(key: _keyUserName, value: userName);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  // 사용자 등급 저장/조회
  static Future<void> saveUserRate(String rate) async {
    await _storage.write(key: _keyUserRate, value: rate);
  }

  static Future<String?> getUserRate() async {
    return await _storage.read(key: _keyUserRate);
  }

  // FCM 토큰 저장/조회
  static Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _keyFcmToken, value: token);
  }

  static Future<String?> getFcmToken() async {
    return await _storage.read(key: _keyFcmToken);
  }

  // 로그인 상태 저장/조회
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // 로그인 정보 저장
  static Future<void> saveLoginInfo({
    required String userId,
    required String userName,
    required String rate,
  }) async {
    await saveUserId(userId);
    await saveUserName(userName);
    await saveUserRate(rate);
    await setLoggedIn(true);
  }

  // 모든 데이터 삭제 (로그아웃)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://223.130.146.117:8080'; // 실제 서버

  final Dio _dio;

  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // 로그인
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/api/login', data: request.toJson());
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 아이디 중복 확인
  Future<bool> checkIdExists(String id) async {
    try {
      final response = await _dio.get('/user/check/$id');
      return response.data as bool;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 회원가입
  Future<Map<String, dynamic>> signup(String id, SignupData data) async {
    try {
      final response = await _dio.post('/user/$id', data: data.toJson());
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 사용자 정보 조회
  Future<Person> getPerson(String id) async {
    try {
      final response = await _dio.get('/api/data2/$id');
      return Person.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 포인트 업데이트
  Future<Person> updatePerson(String id, Person person) async {
    try {
      final response = await _dio.post('/api/data2/$id', data: person.toJson());
      return Person.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 거래 내역 조회
  Future<List<History>> getHistory(String id) async {
    try {
      final response = await _dio.get('/api/data3/$id');
      final list = response.data as List;
      return list.map((e) => History.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 거래 내역 저장
  Future<Map<String, dynamic>> postHistory(String id, History history) async {
    try {
      final response = await _dio.post('/api/data4/$id', data: history.toJson());
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FCM 토큰 등록 (관리자)
  Future<void> registerAdminToken(String token, String role) async {
    try {
      await _dio.post('/api/device/register', data: {
        'token': token,
        'role': role,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // FCM 토큰 등록 (사용자)
  Future<void> registerUserToken(String userId, String token) async {
    try {
      await _dio.post('/api/device/registerUser', data: {
        'userId': userId,
        'token': token,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 충전 신청
  Future<Map<String, dynamic>> requestCharge(ChargeReqDTO request) async {
    try {
      final response = await _dio.post('/api/charge/request', data: request.toJson());
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 관리자에게 충전 알림 푸시
  Future<void> notifyAdminForCharge(ChargePushReq request) async {
    try {
      await _dio.post('/api/notify/charge', data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 결제 알림
  Future<void> notifyPayment(PaymentPushReq request) async {
    try {
      await _dio.post('/api/notify/payment', data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 정산 알림
  Future<void> notifySettlement(PaymentPushReq request) async {
    try {
      await _dio.post('/api/notify/settlement', data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 회원탈퇴
  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/user/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 회원탈퇴 알림 (관리자에게)
  Future<void> notifyWithdraw(String userId, String userName) async {
    try {
      await _dio.post('/api/notify/withdraw', data: {
        'userId': userId,
        'userName': userName,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 아이디 찾기 (Android와 동일)
  Future<Map<String, dynamic>> findUserId(String name, String phone, String email) async {
    try {
      final response = await _dio.get('/api/user/findId', queryParameters: {
        'name': name,
        'phone': phone,
        'email': email,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 사용자 검색 (Android와 동일)
  Future<List<Person>> searchUsers(String name) async {
    try {
      final response = await _dio.get('/api/user/search', queryParameters: {
        'name': name,
      });
      final list = response.data as List;
      return list.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 선물 알림 (Android와 동일)
  Future<void> notifyGift(GiftPushReq request) async {
    try {
      await _dio.post('/api/notify/gift', data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      switch (statusCode) {
        case 400:
          return '잘못된 요청입니다.';
        case 401:
          return '인증에 실패했습니다.';
        case 404:
          return '요청한 정보를 찾을 수 없습니다.';
        case 500:
          return '서버 오류가 발생했습니다.';
        default:
          return '오류가 발생했습니다. ($statusCode)';
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '서버 연결 시간이 초과되었습니다.';
    }
    return '네트워크 오류가 발생했습니다.';
  }
}

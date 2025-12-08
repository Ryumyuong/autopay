import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상
  static const Color primary = Color(0xFF1A1A2E);
  static const Color primaryDark = Color(0xFF16213E);
  static const Color accent = Color(0xFF0F3460);
  static const Color background = Color(0xFF1A1A2E);

  // 텍스트 색상
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF808080);

  // 버튼 색상
  static const Color buttonPrimary = Color(0xFF4A90A4);
  static const Color buttonDisabled = Color(0xFF404040);

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);

  // 거래 타입 색상
  static const Color charge = Color(0xFF4CAF50); // 충전 - 녹색
  static const Color payment = Color(0xFFE53935); // 결제 - 빨강
}

class AppDimens {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 20.0;
  static const double fontXXLarge = 24.0;
  static const double fontTitle = 32.0;
}

class AppStrings {
  static const String appName = '오토페이';
  static const String adminId = 'admin';

  // 버튼 텍스트
  static const String login = '로그인';
  static const String signup = '회원가입';
  static const String logout = '로그아웃';
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String charge = '충전';
  static const String payment = '결제';
  static const String settlement = '정산';

  // 에러 메시지
  static const String networkError = '네트워크 오류가 발생했습니다.';
  static const String serverError = '서버 오류가 발생했습니다.';
  static const String loginRequired = '로그인이 필요합니다.';
  static const String insufficientPoints = '포인트가 부족합니다.';
}

class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String logoWhite = 'assets/images/logo_white.png';
  static const String opening = 'assets/images/opening.png';
}

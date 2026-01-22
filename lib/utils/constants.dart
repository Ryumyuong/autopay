import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상 (흰색 테마)
  static const Color primary = Color(0xFFFFFFFF);
  static const Color primaryDark = Color(0xFF1A2332);
  static const Color accent = Color(0xFF074F8A);
  static const Color background = Color(0xFFFFFFFF);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);

  // 버튼 색상
  static const Color buttonPrimary = Color(0xFF074F8A);
  static const Color buttonBlack = Color(0xFF000000);
  static const Color buttonDisabled = Color(0xFFCCCCCC);

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color pointGold = Color(0xFFFFCB22);

  // 거래 타입 색상
  static const Color charge = Color(0xFF4CAF50); // 충전 - 녹색
  static const Color payment = Color(0xFFE53935); // 결제 - 빨강

  // 카드/박스 색상
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
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
  static const String logos = 'assets/images/logos.png';
  static const String logoWhite = 'assets/images/logo_white.png';
  static const String opening = 'assets/images/opening.png';

  // 메인 화면 카드 이미지
  static const String point = 'assets/images/point.png';
  static const String charge = 'assets/images/charge.png';
  static const String pointC = 'assets/images/point_c.png';
  static const String chargeC = 'assets/images/charge_c.png';
  static const String pointa = 'assets/images/pointa.png';
  static const String chargea = 'assets/images/chargea.png';
  static const String number = 'assets/images/number.png';
  static const String numbera = 'assets/images/numbera.png';
  static const String link = 'assets/images/link.png';

  // 기타 이미지
  static const String telImg = 'assets/images/tel_img.png';
  static const String addBanner = 'assets/images/add_banner.jpg';
}

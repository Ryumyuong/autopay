import 'package:intl/intl.dart';

class Formatters {
  static final _numberFormat = NumberFormat('#,###', 'ko_KR');

  /// 금액을 포맷팅 (예: 1000000 -> "1,000,000")
  static String formatCurrency(int? amount) {
    if (amount == null) return '0';
    return _numberFormat.format(amount);
  }

  /// 금액을 포인트 포맷팅 (예: 1000000 -> "1,000,000 p")
  static String formatPoint(int? amount) {
    return '${formatCurrency(amount)} p';
  }

  /// 금액을 원화 포맷팅 (예: 1000000 -> "1,000,000원")
  static String formatWon(int? amount) {
    return '${formatCurrency(amount)}원';
  }

  /// 날짜 포맷팅 (예: "2024-01-15T10:30:00" -> "2024.01.15 10:30")
  static String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 날짜만 포맷팅 (예: "2024-01-15T10:30:00" -> "2024.01.15")
  static String formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy.MM.dd').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  /// 시간만 포맷팅 (예: "2024-01-15T10:30:00" -> "10:30")
  static String formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }
}

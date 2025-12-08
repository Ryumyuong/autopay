import 'person.dart';

class LoginResponse {
  final bool success;
  final String? message;
  final Person? person;

  LoginResponse({
    required this.success,
    this.message,
    this.person,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      person: json['person'] != null
          ? Person.fromJson(json['person'] as Map<String, dynamic>)
          : null,
    );
  }
}

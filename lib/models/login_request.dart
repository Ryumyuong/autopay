class LoginRequest {
  final String id;
  final String password;

  LoginRequest({
    required this.id,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
    };
  }
}

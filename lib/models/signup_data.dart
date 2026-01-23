class SignupData {
  final String id;
  final String password;
  final String name;
  final String? phone;
  final String? email;
  final String? birth;
  final String? company;

  SignupData({
    required this.id,
    required this.password,
    required this.name,
    this.phone,
    this.email,
    this.birth,
    this.company,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'name': name,
      'phone': phone,
      'email': email,
      'birth': birth,
      'company': company,
    };
  }
}

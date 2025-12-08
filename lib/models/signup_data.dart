class SignupData {
  final String id;
  final String password;
  final String name;
  final String? email;
  final String? birth;
  final String? company;

  SignupData({
    required this.id,
    required this.password,
    required this.name,
    this.email,
    this.birth,
    this.company,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'password': password,
      'name': name,
      'email': email,
      'birth': birth,
      'company': company,
    };
  }
}

class Person {
  final String? id;
  final String? name;
  final int? point;
  final String? password;
  final String? email;
  final String? birth;
  final String? company;
  final String? rate;
  final String? time;

  Person({
    this.id,
    this.name,
    this.point,
    this.password,
    this.email,
    this.birth,
    this.company,
    this.rate,
    this.time,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String?,
      name: json['name'] as String?,
      point: json['point'] is int
          ? json['point'] as int
          : (json['point'] as num?)?.toInt(),
      password: json['password'] as String?,
      email: json['email'] as String?,
      birth: json['birth'] as String?,
      company: json['company'] as String?,
      rate: json['rate'] as String?,
      time: json['time'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'point': point,
      'password': password,
      'email': email,
      'birth': birth,
      'company': company,
      'rate': rate,
      'time': time,
    };
  }

  Person copyWith({
    String? id,
    String? name,
    int? point,
    String? password,
    String? email,
    String? birth,
    String? company,
    String? rate,
    String? time,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      point: point ?? this.point,
      password: password ?? this.password,
      email: email ?? this.email,
      birth: birth ?? this.birth,
      company: company ?? this.company,
      rate: rate ?? this.rate,
      time: time ?? this.time,
    );
  }

  bool get isAdmin => rate == 'ADMIN';
  bool get isUser => rate == 'USER';
}

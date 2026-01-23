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
  final bool? withdrawn;
  final String? phone;

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
    this.withdrawn,
    this.phone,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    // time 필드 처리 (객체 또는 문자열일 수 있음)
    String? timeStr;
    if (json['time'] is String) {
      timeStr = json['time'] as String?;
    } else if (json['time'] is Map) {
      // Firestore Timestamp 객체인 경우
      final timeMap = json['time'] as Map;
      final seconds = timeMap['seconds'] as int?;
      if (seconds != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        timeStr = dt.toString();
      }
    }

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
      time: timeStr,
      withdrawn: json['withdrawn'] as bool?,
      phone: json['phone'] as String?,
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
      'withdrawn': withdrawn,
      'phone': phone,
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
    bool? withdrawn,
    String? phone,
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
      withdrawn: withdrawn ?? this.withdrawn,
      phone: phone ?? this.phone,
    );
  }

  bool get isAdmin => rate == 'ADMIN';
  bool get isUser => rate == 'USER';
}

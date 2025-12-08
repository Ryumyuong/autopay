class History {
  final String? id;
  final String? ids;
  final String? name;
  final int? payment;
  final String? time;
  final String? type;
  final String? company;
  final String? chargeName;

  History({
    this.id,
    this.ids,
    this.name,
    this.payment,
    this.time,
    this.type,
    this.company,
    this.chargeName,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      id: json['id'] as String?,
      ids: json['ids'] as String?,
      name: json['name'] as String?,
      payment: json['payment'] is int
          ? json['payment'] as int
          : (json['payment'] as num?)?.toInt(),
      time: json['time'] as String?,
      type: json['type'] as String?,
      company: json['company'] as String?,
      chargeName: json['chargeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ids': ids,
      'name': name,
      'payment': payment,
      'time': time,
      'type': type,
      'company': company,
      'chargeName': chargeName,
    };
  }

  bool get isPayment => type == 'PAYMENT';
  bool get isCharge => type == 'CHARGE';
}

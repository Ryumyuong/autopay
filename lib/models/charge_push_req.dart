class ChargePushReq {
  final String? userId;
  final int? amount;

  ChargePushReq({
    this.userId,
    this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
    };
  }
}

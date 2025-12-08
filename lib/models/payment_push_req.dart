class PaymentPushReq {
  final String payerId;
  final String? payerName;
  final String payeeId;
  final String? payeeName;
  final int amount;

  PaymentPushReq({
    required this.payerId,
    this.payerName,
    required this.payeeId,
    this.payeeName,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'payerId': payerId,
      'payerName': payerName,
      'payeeId': payeeId,
      'payeeName': payeeName,
      'amount': amount,
    };
  }
}

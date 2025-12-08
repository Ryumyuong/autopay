class ChargeReqDTO {
  final int amount;
  final String autopayId;

  ChargeReqDTO({
    required this.amount,
    required this.autopayId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'autopayId': autopayId,
    };
  }
}

class GiftPushReq {
  final String senderId;
  final String? senderName;
  final String receiverId;
  final String? receiverName;
  final int amount;

  GiftPushReq({
    required this.senderId,
    this.senderName,
    required this.receiverId,
    this.receiverName,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'amount': amount,
    };
  }
}

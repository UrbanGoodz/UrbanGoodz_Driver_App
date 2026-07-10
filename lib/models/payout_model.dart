class PayoutModel {
  final String id;
  final double amount;
  final String status;
  final String requestedDate;
  final String completedDate;
  final String paymentMethod;
  final String transactionId;
  final String notes;

  PayoutModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.requestedDate,
    this.completedDate = '',
    required this.paymentMethod,
    this.transactionId = '',
    this.notes = '',
  });

  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      requestedDate: json['requested_date'] as String,
      completedDate: json['completed_date'] as String? ?? '',
      paymentMethod: json['payment_method'] as String,
      transactionId: json['transaction_id'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'requested_date': requestedDate,
      'completed_date': completedDate,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'notes': notes,
    };
  }
}

class EarningsModel {
  final String date;
  final double amount;
  final String source;
  final String jobId;
  final String status;
  final double tips;
  final double bonuses;
  final double mileage;

  EarningsModel({
    required this.date,
    required this.amount,
    required this.source,
    required this.jobId,
    required this.status,
    this.tips = 0.0,
    this.bonuses = 0.0,
    this.mileage = 0.0,
  });

  factory EarningsModel.fromJson(Map<String, dynamic> json) {
    return EarningsModel(
      date: json['date'] as String,
      amount: (json['amount'] as num).toDouble(),
      source: json['source'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      tips: (json['tips'] as num?)?.toDouble() ?? 0.0,
      bonuses: (json['bonuses'] as num?)?.toDouble() ?? 0.0,
      mileage: (json['mileage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'amount': amount,
      'source': source,
      'job_id': jobId,
      'status': status,
      'tips': tips,
      'bonuses': bonuses,
      'mileage': mileage,
    };
  }
}

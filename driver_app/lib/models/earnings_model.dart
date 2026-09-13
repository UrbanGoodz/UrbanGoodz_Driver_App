import 'package:urban_goodz_driver/utils/json_number.dart';
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
      amount: jsonDouble(json['amount']),
      source: json['source'] as String,
      jobId: json['job_id'] as String,
      status: json['status'] as String,
      tips: jsonDouble(json['tips']),
      bonuses: jsonDouble(json['bonuses']),
      mileage: jsonDouble(json['mileage']),
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

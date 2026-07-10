class OpportunityModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final double reward;
  final String status;
  final String validFrom;
  final String validUntil;
  final String terms;
  final bool isActive;

  OpportunityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.reward,
    required this.status,
    required this.validFrom,
    required this.validUntil,
    required this.terms,
    this.isActive = true,
  });

  factory OpportunityModel.fromJson(Map<String, dynamic> json) {
    return OpportunityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      reward: (json['reward'] as num).toDouble(),
      status: json['status'] as String,
      validFrom: json['valid_from'] as String,
      validUntil: json['valid_until'] as String,
      terms: json['terms'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'reward': reward,
      'status': status,
      'valid_from': validFrom,
      'valid_until': validUntil,
      'terms': terms,
      'is_active': isActive,
    };
  }
}

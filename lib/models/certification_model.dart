class CertificationModel {
  final String id;
  final String name;
  final String issuingAuthority;
  final String issueDate;
  final String expiryDate;
  final String status;
  final String documentUrl;
  final bool isRequired;

  CertificationModel({
    required this.id,
    required this.name,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expiryDate,
    required this.status,
    this.documentUrl = '',
    this.isRequired = false,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      issuingAuthority: json['issuing_authority'] as String,
      issueDate: json['issue_date'] as String,
      expiryDate: json['expiry_date'] as String,
      status: json['status'] as String,
      documentUrl: json['document_url'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'issuing_authority': issuingAuthority,
      'issue_date': issueDate,
      'expiry_date': expiryDate,
      'status': status,
      'document_url': documentUrl,
      'is_required': isRequired,
    };
  }
}

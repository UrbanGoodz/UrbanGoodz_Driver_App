class DispatchNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final String? jobType;
  final int? jobId;
  final String status; // read | unread
  final String priority; // high | normal
  final bool requiresAction;
  final List<String> reviewFlags;
  final String? createdAt;
  final String? readAt;
  final bool canOpen;
  final bool canDismiss;

  DispatchNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.jobType,
    this.jobId,
    required this.status,
    required this.priority,
    required this.requiresAction,
    this.reviewFlags = const [],
    this.createdAt,
    this.readAt,
    this.canOpen = true,
    this.canDismiss = true,
  });

  factory DispatchNotification.fromJson(Map<String, dynamic> n) =>
      DispatchNotification(
        id: int.tryParse(n['id']?.toString() ?? '') ?? 0,
        type: n['type']?.toString() ?? 'notification',
        title: n['title']?.toString() ?? '',
        body: n['body']?.toString() ?? '',
        jobType: n['job_type']?.toString(),
        jobId: n['job_id'] == null ? null : int.tryParse(n['job_id'].toString()),
        status: n['status']?.toString() ?? 'unread',
        priority: n['priority']?.toString() ?? 'normal',
        requiresAction: n['requires_action'] == true,
        reviewFlags: List<String>.from(n['review_flags'] ?? []),
        createdAt: n['created_at']?.toString(),
        readAt: n['read_at']?.toString(),
        canOpen: n['can_open'] != false,
        canDismiss: n['can_dismiss'] != false,
      );

  bool get isHighPriority => priority == 'high';
  bool get isAgeOrMedical =>
      reviewFlags.contains('age_restricted_review') ||
      reviewFlags.contains('medical_review_required') ||
      type == 'age_verification_required' ||
      type == 'medical_review_required';
}

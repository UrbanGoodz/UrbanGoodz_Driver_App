class ApiConfig {
  // Live admin host (per Session 2 P8 contract). Swap for staging via env if needed.
  static const String baseUrl = 'https://admin.urbangoodzdelivery.com';
  static const String driverApiPrefix = '/api/v1/urban-goodz/driver';

  // Business Courier (9)
  static const String businessJobs = '$driverApiPrefix/business-jobs';
  static String businessJobDetail(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId';
  static String businessJobAccept(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/accept';
  static String businessJobStart(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/start';
  static String businessJobPickup(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/pickup';
  static String businessJobDelivery(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/delivery';
  static String businessJobProofPickup(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/proof-pickup';
  static String businessJobProofDelivery(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/proof-delivery';
  static String businessJobException(int jobId) =>
      '$driverApiPrefix/business-jobs/$jobId/exception';

  // Capability (8)
  static const String capabilityProfile = '$driverApiPrefix/capability-profile';
  static const String capabilitySummary = '$driverApiPrefix/capability-summary';
  static const String capabilityVehicle = '$driverApiPrefix/capability-profile/vehicle';
  static const String capabilityCargo = '$driverApiPrefix/capability-profile/cargo';
  static const String capabilityZones = '$driverApiPrefix/capability-profile/zones';
  static const String capabilityWorkTypes =
      '$driverApiPrefix/capability-profile/work-types';
  static const String capabilityTags = '$driverApiPrefix/capability-profile/tags';
  static const String capabilityAvailability =
      '$driverApiPrefix/capability-profile/availability';

  // Job Discovery (3)
  static const String jobDiscovery = '$driverApiPrefix/job-discovery';
  static const String jobDiscoverySummary = '$driverApiPrefix/job-discovery/summary';
  static String jobDiscoveryDetail(String type, int id) =>
      '$driverApiPrefix/job-discovery/$type/$id';

  // Dispatch Notifications (5)
  static const String dispatchNotifications =
      '$driverApiPrefix/dispatch-notifications';
  static const String dispatchUnreadCount =
      '$driverApiPrefix/dispatch-notifications/unread-count';
  static const String dispatchReadAll =
      '$driverApiPrefix/dispatch-notifications/read-all';
  static String dispatchRead(int id) =>
      '$driverApiPrefix/dispatch-notifications/$id/read';
  static String dispatchDismiss(int id) =>
      '$driverApiPrefix/dispatch-notifications/$id/dismiss';
}

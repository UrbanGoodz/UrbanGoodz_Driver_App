class ApiConfig {
  static const String baseUrl = 'https://admin.urbangoodzdelivery.com';
  static const String driverApiPrefix = '/api/v1/urban-goodz/driver';

  // Auth (legacy delivery-man routes)
  static const String driverLogin = '/api/v1/auth/delivery-man/login';
  static const String updateFcmToken = '/api/v1/delivery-man/update-fcm-token';
  static const String driverProfile = '/api/v1/delivery-man/profile';
  static const String recordLocation =
      '/api/v1/delivery-man/record-location-data';

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
  static const String capabilityVehicle =
      '$driverApiPrefix/capability-profile/vehicle';
  static const String capabilityCargo =
      '$driverApiPrefix/capability-profile/cargo';
  static const String capabilityZones =
      '$driverApiPrefix/capability-profile/zones';
  static const String capabilityWorkTypes =
      '$driverApiPrefix/capability-profile/work-types';
  static const String capabilityTags =
      '$driverApiPrefix/capability-profile/tags';
  static const String capabilityAvailability =
      '$driverApiPrefix/capability-profile/availability';

  // Job Discovery (3)
  static const String jobDiscovery = '$driverApiPrefix/job-discovery';
  static const String jobDiscoverySummary =
      '$driverApiPrefix/job-discovery/summary';
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

  // Earnings & Payouts (3)
  static const String earnings = '$driverApiPrefix/earnings';
  static const String payoutRequest = '$driverApiPrefix/payout-request';
  static const String payoutHistory = '$driverApiPrefix/payout-history';

  // Active Jobs (6)
  static const String activeJobs = '$driverApiPrefix/active-jobs';
  static String activeJobDetail(int jobId) =>
      '$driverApiPrefix/active-jobs/$jobId';
  static String activeJobStart(int jobId) =>
      '$driverApiPrefix/active-jobs/$jobId/start';
  static String activeJobComplete(int jobId) =>
      '$driverApiPrefix/active-jobs/$jobId/complete';
  static String activeJobCancel(int jobId) =>
      '$driverApiPrefix/active-jobs/$jobId/cancel';
  static String activeJobStatus(int jobId) =>
      '$driverApiPrefix/active-jobs/$jobId/status';

  // Load Board (2)
  static const String loadBoard = '$driverApiPrefix/load-board';
  static String loadBoardBid(int loadId) =>
      '$driverApiPrefix/load-board/$loadId/bid';
  static String loadBoardAccept(int loadId) =>
      '$driverApiPrefix/load-board/$loadId/accept';

  // Opportunities (2)
  static const String opportunities = '$driverApiPrefix/opportunities';
  static String opportunityClaim(int id) =>
      '$driverApiPrefix/opportunities/$id/claim';

  // Vehicles (1)
  static const String vehicles = '$driverApiPrefix/vehicles';

  // Certifications (3)
  static const String certifications = '$driverApiPrefix/certifications';
  static String certificationUpload(int id) =>
      '$driverApiPrefix/certifications/$id/upload';
  static String certificationRenew(int id) =>
      '$driverApiPrefix/certifications/$id/renew';

  // Dedicated Routes (Stage A & B)
  static const String assignedRoutes = '$driverApiPrefix/routes';
  static String routeDetail(int routeId) => '$driverApiPrefix/routes/$routeId';
  static String resequenceRoute(int routeId) =>
      '$driverApiPrefix/routes/$routeId/sequence';
  static String routeStarted(int routeId) =>
      '$driverApiPrefix/routes/$routeId/started';
  static String routeCompleted(int routeId) =>
      '$driverApiPrefix/routes/$routeId/completed';
  static String scanPickup(int routeId) =>
      '$driverApiPrefix/routes/$routeId/scan-pickup';
  static String scanDropoff(int routeId) =>
      '$driverApiPrefix/routes/$routeId/scan-dropoff';
  static String scanException(int routeId) =>
      '$driverApiPrefix/routes/$routeId/scan-exception';

  // AI Assistant
  static const String aiDriverPrefix = '/api/v1/urban-goodz/cross-app/ai/driver';
  static const String aiDailySummary = '$aiDriverPrefix/daily-summary';
  static const String aiRouteOptimization = '$aiDriverPrefix/route-optimization';
  static const String aiVerifyPackage = '$aiDriverPrefix/verify-package';
  static const String aiVerifyDelivery = '$aiDriverPrefix/verify-delivery';
  static const String aiLoadRecommendations = '$aiDriverPrefix/load-recommendations';
  static const String aiEarningsComparison = '$aiDriverPrefix/earnings-comparison';
}

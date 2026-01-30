/// API Constants for the application
/// Base URL and endpoints for backend integration

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  /// Base URL for the API
  static const String baseUrl = 'https://duneshine.bztechhub.com';

  /// API Endpoints
  static const String loginEndpoint = '/api/employee/login';
  static const String logoutEndpoint = '/api/employee/logout';
  static const String profileEndpoint = '/api/employee/profile';
  static const String availabilityEndpoint = '/api/employee/availability';
  static const String todaysJobsEndpoint = '/api/employee/jobs/today';
  static const String jobDetailsEndpoint = '/api/employee/jobs'; // /{id}
  static const String checkInEndpoint = '/api/employee/attendance/check-in';
  static const String checkOutEndpoint = '/api/employee/attendance/check-out';

  /// Full URL helper methods
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get profileUrl => '$baseUrl$profileEndpoint';
  static String get availabilityUrl => '$baseUrl$availabilityEndpoint';
  static String get todaysJobsUrl => '$baseUrl$todaysJobsEndpoint';
  static String jobDetailsUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId';
  static String navigateToJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/navigate';
  static String arrivedAtJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/reached';
  static String verifyStartOtpUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/verify-start-otp';
  static String startWashUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/start-wash';
  static String finishWashUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/finish-wash';
  static String completeJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/complete';
  static String get checkInUrl => '$baseUrl$checkInEndpoint';
  static String get checkOutUrl => '$baseUrl$checkOutEndpoint';
}

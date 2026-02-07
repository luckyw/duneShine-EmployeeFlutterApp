/// API Constants for the application
/// Base URL and endpoints for backend integration

class ApiConstants {
  // Private constructor to prevent instantiation
  ApiConstants._();

  /// Environment base URLs — change [_defaultBaseUrl] to switch default env.
  static const String _baseUrlDev = 'https://duneshine.bztechhub.com';
  static const String _baseUrlProd = 'https://duneshine.ae';

  /// Default base URL — change this single line to switch between prod and AE.
  /// CI can override via: flutter build apk --dart-define=BASE_URL=https://...
  // static const String _defaultBaseUrl = _baseUrlDev;
  static const String _defaultBaseUrl = _baseUrlProd; // Switch to production

  static String get baseUrl =>
      String.fromEnvironment('BASE_URL', defaultValue: _defaultBaseUrl);

  /// Full URL for a storage path (e.g. image path from API).
  static String storageUrl(String path) => '$baseUrl/storage/$path';

  /// API Endpoints
  static const String loginEndpoint = '/api/employee/login';
  static const String logoutEndpoint = '/api/employee/logout';
  static const String profileEndpoint = '/api/employee/profile';
  static const String availabilityEndpoint = '/api/employee/availability';
  static const String todaysJobsEndpoint = '/api/employee/jobs/today';
  static const String jobDetailsEndpoint = '/api/employee/jobs'; // /{id}
  static const String propertyDetailsEndpoint = '/api/properties'; // /{id}
  static const String checkInEndpoint = '/api/employee/attendance/check-in';
  static const String checkOutEndpoint = '/api/employee/attendance/check-out';
  static const String updateLocationEndpoint = '/api/employee/update-location';

  /// Full URL helper methods
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get profileUrl => '$baseUrl$profileEndpoint';
  static String get availabilityUrl => '$baseUrl$availabilityEndpoint';
  static String get todaysJobsUrl => '$baseUrl$todaysJobsEndpoint';
  static String jobDetailsUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId';
  static String propertyDetailsUrl(int propertyId) => '$baseUrl$propertyDetailsEndpoint/$propertyId';
  static String navigateToJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/navigate';
  static String arrivedAtJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/reached';
  static String verifyStartOtpUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/verify-start-otp';
  static String startWashUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/start-wash';
  static String finishWashUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/finish-wash';
  static String completeJobUrl(int jobId) => '$baseUrl$jobDetailsEndpoint/$jobId/complete';
  static String get checkInUrl => '$baseUrl$checkInEndpoint';
  static String get checkOutUrl => '$baseUrl$checkOutEndpoint';
  static String get updateLocationUrl => '$baseUrl$updateLocationEndpoint';
}

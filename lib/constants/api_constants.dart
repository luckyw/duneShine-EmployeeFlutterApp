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

  /// Full URL helper methods
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
}

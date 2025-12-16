import 'package:flutter/foundation.dart';

/// Auth Service for managing authentication state
/// Stores token and employee data after successful login
class AuthService {
  // Private constructor for singleton pattern
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // Store authentication data
  String? _token;
  Map<String, dynamic>? _employeeData;

  /// Get the current auth token
  String? get token => _token;

  /// Get the current employee data
  Map<String, dynamic>? get employeeData => _employeeData;

  /// Check if user is logged in
  bool get isLoggedIn => _token != null;

  /// Set authentication data after successful login
  void setAuthData({
    required String token,
    required Map<String, dynamic> employeeData,
  }) {
    _token = token;
    _employeeData = employeeData;
    debugPrint('Auth data set - Token: ${token.substring(0, 10)}...');
  }

  /// Clear authentication data (logout)
  void clearAuthData() {
    _token = null;
    _employeeData = null;
    debugPrint('Auth data cleared');
  }

  /// Get employee name
  String get employeeName => _employeeData?['name'] ?? 'Employee';

  /// Get employee phone
  String get employeePhone => _employeeData?['phone'] ?? '';

  /// Get employee email
  String get employeeEmail => _employeeData?['email'] ?? '';

  /// Get employee profile image URL
  String? get employeeProfileImage {
    final image = _employeeData?['profile_image'];
    if (image != null && image.toString().isNotEmpty) {
      return 'https://duneshine.bztechhub.com/storage/$image';
    }
    return null;
  }
}

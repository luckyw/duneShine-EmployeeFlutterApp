import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// Auth Service for managing authentication state
/// Uses flutter_secure_storage for persistent, encrypted token storage
/// - iOS: Uses Keychain
/// - Android: Uses EncryptedSharedPreferences
class AuthService {
  // Private constructor for singleton pattern
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  // Secure storage instance with platform-specific options
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _employeeDataKey = 'employee_data';
  static const String _isShiftStartedKey = 'is_shift_started';

  // In-memory cache for quick access
  String? _token;
  Map<String, dynamic>? _employeeData;
  bool _isShiftStarted = false;

  /// Get the current auth token
  String? get token => _token;

  /// Get the current employee data
  Map<String, dynamic>? get employeeData => _employeeData;

  /// Get the current shift status
  bool get isShiftStarted => _isShiftStarted;

  /// Check if user is logged in
  bool get isLoggedIn => _token != null;

  /// Initialize auth service - call this on app startup
  /// Loads saved token and employee data from secure storage
  Future<bool> initialize() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final employeeDataJson = await _storage.read(key: _employeeDataKey);
      
      if (employeeDataJson != null) {
        _employeeData = jsonDecode(employeeDataJson) as Map<String, dynamic>;
      }

      final shiftStartedStr = await _storage.read(key: _isShiftStartedKey);
      _isShiftStarted = shiftStartedStr == 'true';

      return isLoggedIn;
    } catch (e) {
      debugPrint('AuthService initialization error: $e');
      return false;
    }
  }

  /// Set authentication data after successful login
  /// Saves token and employee data to secure storage
  Future<void> setAuthData({
    required String token,
    required Map<String, dynamic> employeeData,
  }) async {
    _token = token;
    _employeeData = employeeData;

    try {
      // Save to secure storage
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(
        key: _employeeDataKey,
        value: jsonEncode(employeeData),
      );
      // Save to secure storage
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  /// Clear authentication data (logout)
  /// Removes token and employee data from secure storage
  Future<void> clearAuthData() async {
    _token = null;
    _employeeData = null;
    _isShiftStarted = false;

    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _employeeDataKey);
      await _storage.delete(key: _isShiftStartedKey);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  /// Set the current shift status
  Future<void> setShiftStatus(bool value) async {
    _isShiftStarted = value;
    try {
      await _storage.write(key: _isShiftStartedKey, value: value.toString());
    } catch (e) {
      debugPrint('Error saving shift status: $e');
    }
  }

  /// Get employee name
  String get employeeName => _employeeData?['name'] ?? 'Employee';

  /// Get employee phone
  String get employeePhone => _employeeData?['phone'] ?? '';

  /// Get employee email
  String get employeeEmail => _employeeData?['email'] ?? '';

  /// Get employee ID
  int? get employeeId => _employeeData?['id'];

  /// Get employee profile image URL
  String? get employeeProfileImage {
    final image = _employeeData?['profile_image'];
    if (image != null && image.toString().isNotEmpty) {
      return ApiConstants.storageUrl(image.toString());
    }
    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../constants/api_constants.dart';
import '../models/customer_subscription_model.dart';

/// API Service for handling HTTP requests
class ApiService {
  // Private constructor for singleton pattern
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  /// Login with phone number and OTP
  /// Returns a map containing the response data
  Future<Map<String, dynamic>> login({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Logout with Bearer token authorization
  /// Returns a map containing the response data
  Future<Map<String, dynamic>> logout({required String token}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.logoutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Logout failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get employee profile information
  /// Returns a map containing the employee profile data including vendor info
  Future<Map<String, dynamic>> getProfile({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.profileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch profile',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Set employee availability for specific dates
  /// available_dates: List of date strings in 'YYYY-MM-DD' format
  /// isAvailable: true to mark as available, false to mark as unavailable
  Future<Map<String, dynamic>> setAvailability({
    required String token,
    required List<String> availableDates,
    required bool isAvailable,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.availabilityUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'available_dates': availableDates,
          'is_available': isAvailable,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update availability',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Set availability error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get employee availability dates
  /// Returns a list of availability records with dates and status
  Future<Map<String, dynamic>> getAvailability({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.availabilityUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch availability',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Get availability error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get today's jobs for the authenticated employee
  /// Returns a map containing the response data with jobs list
  Future<Map<String, dynamic>> getTodaysJobs({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.todaysJobsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch jobs',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get details of a specific job by ID
  /// Returns a map containing the job data
  Future<Map<String, dynamic>> getJobDetails({
    required int jobId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.jobDetailsUrl(jobId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch job details',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get property details by property ID
  /// Returns a map containing the property data
  Future<Map<String, dynamic>> getPropertyDetails({
    required int propertyId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.propertyDetailsUrl(propertyId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch property details',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Start navigation to a job - updates status to "en_route"
  /// Returns a map containing the updated job data
  Future<Map<String, dynamic>> navigateToJob({
    required int jobId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.navigateToJobUrl(jobId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to start navigation',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Mark arrival at job location - updates status to "arrived" and generates OTP
  /// Returns a map containing the updated job data with start_otp
  Future<Map<String, dynamic>> arrivedAtJob({
    required int jobId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.arrivedAtJobUrl(jobId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to mark arrival',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify start OTP to begin the job
  /// Returns success/failure based on OTP verification
  /// For subscription jobs, OTP is optional - pass null or empty to skip
  Future<Map<String, dynamic>> verifyStartOtp({
    required int jobId,
    String? otp,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }
      final response = await http.post(
        Uri.parse(ApiConstants.verifyStartOtpUrl(jobId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'OTP verification failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Start wash with before photo upload
  /// Uses multipart form data to upload photo
  Future<Map<String, dynamic>> startWash({
    required int jobId,
    required String photoPath,
    required String token,
  }) async {
    try {
      // Check file size before upload (max 10MB)
      final file = File(photoPath);
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB

      if (fileSize > maxSize) {
        return {
          'success': false,
          'message':
              'Photo is too large (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Maximum size is 10MB.',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.startWashUrl(jobId)),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add photo file
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

      // Send with 30 second timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to start wash',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Start wash error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Finish wash with after photo upload
  /// Uses multipart form data to upload completion photo
  /// Optionally sends duration in seconds
  Future<Map<String, dynamic>> finishWash({
    required int jobId,
    required String photoPath,
    required String token,
    int? durationSeconds,
  }) async {
    try {
      // Check file size before upload (max 10MB)
      final file = File(photoPath);
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB

      if (fileSize > maxSize) {
        return {
          'success': false,
          'message':
              'Photo is too large (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Maximum size is 10MB.',
        };
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.finishWashUrl(jobId)),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add photo file
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));

      // Add duration if provided
      if (durationSeconds != null) {
        request.fields['duration_seconds'] = durationSeconds.toString();
      }

      // Send with 30 second timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to finish wash',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Finish wash error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Complete job with end OTP verification
  /// Marks the job as completed after verifying customer's end OTP
  /// For subscription jobs, OTP is optional - pass null or empty to skip
  Future<Map<String, dynamic>> completeJob({
    required int jobId,
    String? otp,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (otp != null && otp.isNotEmpty) {
        body['otp'] = otp;
      }
      final response = await http.post(
        Uri.parse(ApiConstants.completeJobUrl(jobId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to complete job',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Complete job error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Employee attendance check-in
  /// Returns a map containing the response data
  Future<Map<String, dynamic>> checkIn({required String token}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.checkInUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Check-in failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Employee attendance check-out
  /// Returns a map containing the response data
  Future<Map<String, dynamic>> checkOut({required String token}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.checkOutUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Check-out failed',
          'data': responseData,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Update employee location during shift
  /// Sends GPS coordinates to the backend every 300 seconds
  Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.updateLocationUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update location',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Update location error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Update employee profile
  /// Allows updating name, email (backend only), and profile photo
  /// Uses multipart form data for photo upload
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String phone,
    String? email,
    String? profilePhotoPath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.profileUrl),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields['name'] = name;
      request.fields['phone'] = phone;
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      // Add profile photo if provided
      if (profilePhotoPath != null && profilePhotoPath.isNotEmpty) {
        final file = File(profilePhotoPath);
        final fileSize = await file.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          return {
            'success': false,
            'message':
                'Photo is too large (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB). Maximum size is 10MB.',
          };
        }

        request.files.add(
          await http.MultipartFile.fromPath('profile_photo', profilePhotoPath),
        );
      }

      // Send with 30 second timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(
        streamedResponse,
      ).timeout(const Duration(seconds: 10));

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
          'data': responseData,
        };
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// MOCKED: Get customer details by phone number
  Future<Map<String, dynamic>> getCustomerDetails({
    required String phoneNumber,
    required String token,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple mock validation
    if (phoneNumber.length < 8) {
      return {'success': false, 'message': 'Invalid phone number', 'data': {}};
    }

    // Mock data
    final mockData = {
      'id': 'cust_12345',
      'name': 'Ahmed Al-Farsi',
      'phone': phoneNumber,
      'car_model': 'Toyota Land Cruiser',
      'car_plate': 'DXB 12345',
      'current_plan': 'Weekly Wash',
      'subscription_end_date': DateTime.now()
          .subtract(const Duration(days: 5))
          .toIso8601String(), // Expired
      'last_subscription_date': DateTime.now()
          .subtract(const Duration(days: 35))
          .toIso8601String(),
      'is_subscription_active': false,
    };

    return {
      'success': true,
      'data': {'customer': mockData},
    };
  }

  /// MOCKED: Send OTP for renewal verification
  Future<Map<String, dynamic>> sendRenewalOtp({
    required String phoneNumber,
    required String token,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    debugPrint('MOCK OTP sent to $phoneNumber: 123456');

    return {'success': true, 'message': 'OTP sent successfully', 'data': {}};
  }

  /// MOCKED: Verify renewal OTP
  Future<Map<String, dynamic>> verifyRenewalOtp({
    required String phoneNumber,
    required String otp,
    required String token,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (otp == '123456') {
      return {
        'success': true,
        'message': 'OTP verified successfully',
        'data': {},
      };
    } else {
      return {'success': false, 'message': 'Invalid OTP', 'data': {}};
    }
  }

  /// MOCKED: Renew subscription
  Future<Map<String, dynamic>> renewSubscription({
    required String customerId,
    required String token,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    return {
      'success': true,
      'message': 'Subscription renewed successfully',
      'data': {
        'new_end_date': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      },
    };
  }
}

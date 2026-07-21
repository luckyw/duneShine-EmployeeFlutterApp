import 'api_service.dart';

/// Mock API Service — used when app is run with:
///   flutter run --dart-define=USE_MOCK_API=true
///
/// Simulates the full job lifecycle (assigned → en_route → arrived →
/// in_progress → washing → washed → completed) entirely in memory.
/// No real network calls are made.
class MockApiService extends ApiService {
  MockApiService() : super.internal();

  // ── Stateful mock job ──────────────────────────────────────────────
  // Uses a real Job-model-compatible JSON structure that matches
  // Job.fromJson / Booking.fromJson / TimeSlot.fromJson exactly.
  static final List<Map<String, dynamic>> _mockJobs = [
    {
      'id': 101,
      'booking_id': 1,
      'scheduled_date': DateTime.now().toIso8601String().split('T')[0],
      'time_slot_id': 1,
      'employee_id': 62,
      'status': 'assigned',
      'start_otp': '1234',
      'end_otp': '5678',
      'start_otp_verified_at': null,
      'end_otp_verified_at': null,
      'en_route_at': null,
      'arrived_at': null,
      'started_at': null,
      'washed_at': null,
      'completed_at': null,
      'photos_before': <String>[],
      'photos_after': <String>[],
      'photos_before_urls': <String>[],
      'photos_after_urls': <String>[],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'time_slot': {
        'id': 1,
        'start_time': '09:00:00',
        'end_time': '10:00:00',
        'status': true,
      },
      'booking': {
        'id': 1,
        'user_id': 20,
        'vehicle_id': 30,
        'vendor_id': 10,
        'type': 'one-time',
        'total_price': '150.00',
        'payment_status': 'paid',
        'status': 'confirmed',
        'notes': null,
        'services_payload': [
          {'id': 1, 'name': 'Full Wash', 'price': '150.00'},
        ],
        'customer': {
          'id': 20,
          'name': 'John Doe',
          'email': 'john@example.com',
          'phone': '+971501234567',
          'id_proof_image': null,
        },
        'property': {
          'id': 50,
          'name': 'Mock Springs',
          'address': 'Villa 42, Mock Springs, Dubai',
          'building_number': '42',
          'zone': 'Zone A',
          'geo_location': null,
          'latitude': '26.6484',
          'longitude': '78.1698',
          'google_maps_url': null,
          'hierarchy_path': 'Villa 42, Mock Springs, Dubai',
          'resolved_location': null,
        },
        'vehicle': {
          'id': 30,
          'user_id': 20,
          'brand_name': 'Toyota',
          'model': 'Camry',
          'color': 'White',
          'number_plate': 'DXB A 12345',
          'parking_notes': 'Near the main gate',
          'image': null,
          'image_url': null,
        },
      },
    },
  ];

  // ── Helpers ────────────────────────────────────────────────────────

  /// Simulate network latency
  Future<void> _delay() async =>
      Future.delayed(const Duration(milliseconds: 800));

  Map<String, dynamic>? _findJob(int jobId) {
    try {
      return _mockJobs.firstWhere((j) => j['id'] == jobId);
    } catch (_) {
      return null;
    }
  }

  int _findIndex(int jobId) =>
      _mockJobs.indexWhere((j) => j['id'] == jobId);

  // ── Overrides ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getTodaysJobs({required String token}) async {
    await _delay();
    return {
      'success': true,
      'data': {'jobs': _mockJobs},
    };
  }

  @override
  Future<Map<String, dynamic>> getJobDetails({
    required int jobId,
    required String token,
  }) async {
    await _delay();
    final job = _findJob(jobId);
    if (job == null) return {'success': false, 'message': 'Job not found'};
    return {
      'success': true,
      'data': {'job': job},
    };
  }

  @override
  Future<Map<String, dynamic>> navigateToJob({
    required int jobId,
    required String token,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    _mockJobs[idx]['status'] = 'en_route';
    _mockJobs[idx]['en_route_at'] = DateTime.now().toIso8601String();
    return {
      'success': true,
      'data': {'job': _mockJobs[idx]},
    };
  }

  @override
  Future<Map<String, dynamic>> arrivedAtJob({
    required int jobId,
    required String token,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    _mockJobs[idx]['status'] = 'arrived';
    _mockJobs[idx]['arrived_at'] = DateTime.now().toIso8601String();
    return {
      'success': true,
      'data': {'job': _mockJobs[idx], 'start_otp': '1234'},
    };
  }

  @override
  Future<Map<String, dynamic>> verifyStartOtp({
    required int jobId,
    String? otp,
    required String token,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    // Accept '1234' OR skip OTP for subscription-type jobs
    if (otp == '1234' || otp == null || otp.isEmpty) {
      _mockJobs[idx]['status'] = 'in_progress';
      _mockJobs[idx]['started_at'] = DateTime.now().toIso8601String();
      _mockJobs[idx]['start_otp_verified_at'] = DateTime.now().toIso8601String();
      return {
        'success': true,
        'data': {'job': _mockJobs[idx]},
      };
    }
    return {'success': false, 'message': 'Invalid OTP. Use 1234 for mock.'};
  }

  @override
  Future<Map<String, dynamic>> startWash({
    required int jobId,
    required String photoPath,
    required String token,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    _mockJobs[idx]['status'] = 'washing';
    (_mockJobs[idx]['photos_before'] as List).add(photoPath);
    (_mockJobs[idx]['photos_before_urls'] as List).add(photoPath);
    return {
      'success': true,
      'data': {'job': _mockJobs[idx]},
    };
  }

  @override
  Future<Map<String, dynamic>> finishWash({
    required int jobId,
    required String photoPath,
    required String token,
    int? durationSeconds,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    _mockJobs[idx]['status'] = 'washed';
    _mockJobs[idx]['washed_at'] = DateTime.now().toIso8601String();
    (_mockJobs[idx]['photos_after'] as List).add(photoPath);
    (_mockJobs[idx]['photos_after_urls'] as List).add(photoPath);
    return {
      'success': true,
      'data': {'job': _mockJobs[idx], 'end_otp': '5678'},
    };
  }

  @override
  Future<Map<String, dynamic>> completeJob({
    required int jobId,
    String? otp,
    required String token,
  }) async {
    await _delay();
    final idx = _findIndex(jobId);
    if (idx == -1) return {'success': false, 'message': 'Job not found'};
    if (otp == '5678' || otp == null || otp.isEmpty) {
      _mockJobs[idx]['status'] = 'completed';
      _mockJobs[idx]['completed_at'] = DateTime.now().toIso8601String();
      _mockJobs[idx]['end_otp_verified_at'] = DateTime.now().toIso8601String();
      return {
        'success': true,
        'data': {'job': _mockJobs[idx]},
      };
    }
    return {'success': false, 'message': 'Invalid OTP. Use 5678 for mock.'};
  }
}

/// Job Model Classes for Employee Jobs API
/// Parses the response from /api/employee/jobs/today

class TimeSlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool status;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? true,
    );
  }

  /// Format time as "HH:MM AM/PM"
  String get formattedStartTime {
    try {
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        return '${hour.toString().padLeft(2, '0')}:$minute $period';
      }
    } catch (_) {}
    return startTime;
  }
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Property {
  final int id;
  final String name;
  final String? address;
  final String? buildingNumber;
  final String? zone;
  final String geoLocation;

  Property({
    required this.id,
    required this.name,
    this.address,
    this.buildingNumber,
    this.zone,
    required this.geoLocation,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      buildingNumber: json['building_number'],
      zone: json['zone'],
      geoLocation: json['geo_location'] ?? '',
    );
  }

  /// Full address for display
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return '$name, $address';
    }
    return name;
  }
}

class Vehicle {
  final int id;
  final int userId;
  final String brandName;
  final String model;
  final String color;
  final String numberPlate;
  final String? parkingNotes;
  final String? image;
  final String? imageUrl;

  Vehicle({
    required this.id,
    required this.userId,
    required this.brandName,
    required this.model,
    required this.color,
    required this.numberPlate,
    this.parkingNotes,
    this.image,
    this.imageUrl,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      brandName: json['brand_name'] ?? 'Unknown',
      model: json['model'] ?? '',
      color: json['color'] ?? '',
      numberPlate: json['number_plate'] ?? '',
      parkingNotes: json['parking_notes'],
      image: json['image'],
      imageUrl: json['image_url'],
    );
  }

  /// Display name for the vehicle (e.g., "BMW Sia - White")
  String get displayName => '$brandName $model - $color';
}

class ServicePayload {
  final int id;
  final String name;
  final String price;

  ServicePayload({
    required this.id,
    required this.name,
    required this.price,
  });

  factory ServicePayload.fromJson(Map<String, dynamic> json) {
    return ServicePayload(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
    );
  }
}

class Booking {
  final int id;
  final int userId;
  final int vehicleId;
  final int? apartmentId;
  final int? propertyId;
  final int vendorId;
  final String type;
  final String totalPrice;
  final String paymentStatus;
  final String status;
  final List<ServicePayload> servicesPayload;
  final String? notes;
  final Customer? customer;
  final Property? property;
  final Vehicle? vehicle;

  Booking({
    required this.id,
    required this.userId,
    required this.vehicleId,
    this.apartmentId,
    this.propertyId,
    required this.vendorId,
    required this.type,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    required this.servicesPayload,
    this.notes,
    this.customer,
    this.property,
    this.vehicle,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      apartmentId: json['apartment_id'],
      propertyId: json['property_id'],
      vendorId: json['vendor_id'] ?? 0,
      type: json['type'] ?? '',
      totalPrice: json['total_price'] ?? '0.00',
      paymentStatus: json['payment_status'] ?? '',
      status: json['status'] ?? '',
      servicesPayload: (json['services_payload'] as List<dynamic>?)
              ?.map((e) => ServicePayload.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: json['notes'],
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      property: json['property'] != null
          ? Property.fromJson(json['property'] as Map<String, dynamic>)
          : (json['apartment'] != null 
              ? Property.fromJson(json['apartment'] as Map<String, dynamic>)
              : null),
      vehicle: json['vehicle'] != null
          ? Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Helper to get the property/location name
  String get locationName => property?.name ?? 'Unknown Location';

  /// Helper to get the full formatted address
  String get fullAddress => property?.fullAddress ?? 'Unknown Address';

  /// Helper to get geo location coordinates
  String get geoLocation => property?.geoLocation ?? '';
}

class Job {
  final int id;
  final int bookingId;
  final String scheduledDate;
  final int timeSlotId;
  final int employeeId;
  final String status;
  final String? startOtp;
  final String? startOtpVerifiedAt;
  final String? endOtp;
  final String? endOtpVerifiedAt;
  final String? enRouteAt;
  final String? arrivedAt;
  final String? startedAt;
  final String? washedAt;
  final String? completedAt;
  final List<String> photosBefore;
  final List<String> photosAfter;
  final List<String> photosBeforeUrls;
  final List<String> photosAfterUrls;
  final Booking? booking;
  final TimeSlot? timeSlot;
  final String createdAt;
  final String updatedAt;

  Job({
    required this.id,
    required this.bookingId,
    required this.scheduledDate,
    required this.timeSlotId,
    required this.employeeId,
    required this.status,
    this.startOtp,
    this.startOtpVerifiedAt,
    this.endOtp,
    this.endOtpVerifiedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.startedAt,
    this.washedAt,
    this.completedAt,
    required this.photosBefore,
    required this.photosAfter,
    required this.photosBeforeUrls,
    required this.photosAfterUrls,
    this.booking,
    this.timeSlot,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      scheduledDate: json['scheduled_date'] ?? '',
      timeSlotId: json['time_slot_id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      status: json['status'] ?? 'unknown',
      startOtp: json['start_otp']?.toString(),
      startOtpVerifiedAt: json['start_otp_verified_at'],
      endOtp: json['end_otp']?.toString(),
      endOtpVerifiedAt: json['end_otp_verified_at'],
      enRouteAt: json['en_route_at'],
      arrivedAt: json['arrived_at'],
      startedAt: json['started_at'],
      washedAt: json['washed_at'],
      completedAt: json['completed_at'],
      photosBefore: (json['photos_before'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosAfter: (json['photos_after'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosBeforeUrls: (json['photos_before_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosAfterUrls: (json['photos_after_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      booking: json['booking'] != null
          ? Booking.fromJson(json['booking'] as Map<String, dynamic>)
          : null,
      timeSlot: json['time_slot'] != null
          ? TimeSlot.fromJson(json['time_slot'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  /// Check if job is completed
  bool get isCompleted => status == 'completed';

  /// Check if job is upcoming (not yet started or in progress)
  bool get isUpcoming => !isCompleted;

  /// Get display status text
  String get displayStatus {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}

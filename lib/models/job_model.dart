/// Job Model Classes for Employee Jobs API
/// Parses the response from /api/employee/jobs/today

import '../constants/api_constants.dart';

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
  final String? idProofImage;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.idProofImage,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      idProofImage: json['id_proof_image'],
    );
  }

  /// Get full ID proof image URL
  String? get idProofImageUrl {
    if (idProofImage != null && idProofImage!.isNotEmpty) {
      // Check if it's already a full URL
      if (idProofImage!.startsWith('http')) {
        return idProofImage;
      }
      return ApiConstants.storageUrl(idProofImage!);
    }
    return null;
  }
}

class Property {
  final int id;
  final String name;
  final String? address;
  final String? buildingNumber;
  final String? zone;
  final String? geoLocation; // Legacy field
  final String? latitude;
  final String? longitude;
  final String? googleMapsUrl;
  final String? hierarchyPath;
  final Map<String, dynamic>? resolvedLocation;

  Property({
    required this.id,
    required this.name,
    this.address,
    this.buildingNumber,
    this.zone,
    this.geoLocation,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.hierarchyPath,
    this.resolvedLocation,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      buildingNumber: json['building_number'],
      zone: json['zone'],
      geoLocation: json['geo_location'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      googleMapsUrl: json['google_maps_url'],
      hierarchyPath: json['hierarchy_path'],
      resolvedLocation: json['resolved_location'] as Map<String, dynamic>?,
    );
  }

  /// Get the best available latitude
  String? get resolvedLatitude {
    if (resolvedLocation != null && resolvedLocation!['latitude'] != null) {
      return resolvedLocation!['latitude'].toString();
    }
    return latitude;
  }

  /// Get the best available longitude
  String? get resolvedLongitude {
    if (resolvedLocation != null && resolvedLocation!['longitude'] != null) {
      return resolvedLocation!['longitude'].toString();
    }
    return longitude;
  }

  /// Full address for display
  String get fullAddress {
    if (hierarchyPath != null && hierarchyPath!.isNotEmpty) {
      return hierarchyPath!;
    }
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

  ServicePayload({required this.id, required this.name, required this.price});

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
      servicesPayload:
          (json['services_payload'] as List<dynamic>?)
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
  String get geoLocation {
    final lat = property?.resolvedLatitude;
    final lng = property?.resolvedLongitude;
    if (lat != null && lng != null) {
      return '$lat,$lng';
    }
    return property?.geoLocation ?? '';
  }

  /// Get direct Google Maps URL if available
  String? get googleMapsUrl => property?.googleMapsUrl;

  /// Create a copy of this Booking with optionally replaced fields
  Booking copyWith({
    int? id,
    int? userId,
    int? vehicleId,
    int? apartmentId,
    int? propertyId,
    int? vendorId,
    String? type,
    String? totalPrice,
    String? paymentStatus,
    String? status,
    List<ServicePayload>? servicesPayload,
    String? notes,
    Customer? customer,
    Property? property,
    Vehicle? vehicle,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      apartmentId: apartmentId ?? this.apartmentId,
      propertyId: propertyId ?? this.propertyId,
      vendorId: vendorId ?? this.vendorId,
      type: type ?? this.type,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      servicesPayload: servicesPayload ?? this.servicesPayload,
      notes: notes ?? this.notes,
      customer: customer ?? this.customer,
      property: property ?? this.property,
      vehicle: vehicle ?? this.vehicle,
    );
  }
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
      photosBefore:
          (json['photos_before'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosAfter:
          (json['photos_after'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosBeforeUrls:
          (json['photos_before_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosAfterUrls:
          (json['photos_after_urls'] as List<dynamic>?)
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

  /// Check if job is a subscription booking
  bool get isSubscription => booking?.type == 'subscription';

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

  /// Create a copy of this Job with optionally replaced fields
  Job copyWith({
    int? id,
    int? bookingId,
    String? scheduledDate,
    int? timeSlotId,
    int? employeeId,
    String? status,
    String? startOtp,
    String? startOtpVerifiedAt,
    String? endOtp,
    String? endOtpVerifiedAt,
    String? enRouteAt,
    String? arrivedAt,
    String? startedAt,
    String? washedAt,
    String? completedAt,
    List<String>? photosBefore,
    List<String>? photosAfter,
    List<String>? photosBeforeUrls,
    List<String>? photosAfterUrls,
    Booking? booking,
    TimeSlot? timeSlot,
    String? createdAt,
    String? updatedAt,
  }) {
    return Job(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      employeeId: employeeId ?? this.employeeId,
      status: status ?? this.status,
      startOtp: startOtp ?? this.startOtp,
      startOtpVerifiedAt: startOtpVerifiedAt ?? this.startOtpVerifiedAt,
      endOtp: endOtp ?? this.endOtp,
      endOtpVerifiedAt: endOtpVerifiedAt ?? this.endOtpVerifiedAt,
      enRouteAt: enRouteAt ?? this.enRouteAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      washedAt: washedAt ?? this.washedAt,
      completedAt: completedAt ?? this.completedAt,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      photosBeforeUrls: photosBeforeUrls ?? this.photosBeforeUrls,
      photosAfterUrls: photosAfterUrls ?? this.photosAfterUrls,
      booking: booking ?? this.booking,
      timeSlot: timeSlot ?? this.timeSlot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Merges this job with another job (typically from a status update API)
  /// while preserving nested objects (booking, timeSlot) if the other is null.
  Job mergeWith(Job other) {
    return other.copyWith(
      booking: other.booking ?? booking,
      timeSlot: other.timeSlot ?? timeSlot,
    );
  }
}

/// Employee Profile Model
/// Represents the employee profile data returned from /api/employee/profile

import '../constants/api_constants.dart';

class VendorModel {
  final int id;
  final String name;
  final String email;
  final int? serviceId;
  final String? logo;
  final String? description;
  final String? idCardNumber;
  final String? idProofImage;
  final String? crNumber;
  final String? crProofImage;
  final String? phone;
  final String role;
  final bool status;
  final String? address;
  final String? rate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VendorModel({
    required this.id,
    required this.name,
    required this.email,
    this.serviceId,
    this.logo,
    this.description,
    this.idCardNumber,
    this.idProofImage,
    this.crNumber,
    this.crProofImage,
    this.phone,
    required this.role,
    required this.status,
    this.address,
    this.rate,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    return VendorModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      serviceId: json['service_id'] as int?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      idCardNumber: json['id_card_number'] as String?,
      idProofImage: json['id_proof_image'] as String?,
      crNumber: json['cr_number'] as String?,
      crProofImage: json['cr_proof_image'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'vendor',
      status: json['status'] == true || json['status'] == 1,
      address: json['address'] as String?,
      rate: json['rate']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'service_id': serviceId,
      'logo': logo,
      'description': description,
      'id_card_number': idCardNumber,
      'id_proof_image': idProofImage,
      'cr_number': crNumber,
      'cr_proof_image': crProofImage,
      'phone': phone,
      'role': role,
      'status': status,
      'address': address,
      'rate': rate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get full logo URL
  String? get logoUrl {
    if (logo != null && logo!.isNotEmpty) {
      return ApiConstants.storageUrl(logo!);
    }
    return null;
  }
}

class EmployeeProfileModel {
  final int id;
  final String name;
  final String email;
  final int? serviceId;
  final String? logo;
  final String? description;
  final String? idCardNumber;
  final String? idProofImage;
  final String? crNumber;
  final String? crProofImage;
  final String? phone;
  final String role;
  final bool status;
  final String? address;
  final String? rate;
  final int? vendorId;
  final VendorModel? vendor;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmployeeProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.serviceId,
    this.logo,
    this.description,
    this.idCardNumber,
    this.idProofImage,
    this.crNumber,
    this.crProofImage,
    this.phone,
    required this.role,
    required this.status,
    this.address,
    this.rate,
    this.vendorId,
    this.vendor,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      serviceId: json['service_id'] as int?,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      idCardNumber: json['id_card_number'] as String?,
      idProofImage: json['id_proof_image'] as String?,
      crNumber: json['cr_number'] as String?,
      crProofImage: json['cr_proof_image'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'employee',
      status: json['status'] == true || json['status'] == 1,
      address: json['address'] as String?,
      rate: json['rate']?.toString(),
      vendorId: json['vendor_id'] as int?,
      vendor: json['vendor'] != null
          ? VendorModel.fromJson(json['vendor'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'service_id': serviceId,
      'logo': logo,
      'description': description,
      'id_card_number': idCardNumber,
      'id_proof_image': idProofImage,
      'cr_number': crNumber,
      'cr_proof_image': crProofImage,
      'phone': phone,
      'role': role,
      'status': status,
      'address': address,
      'rate': rate,
      'vendor_id': vendorId,
      'vendor': vendor?.toJson(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get full ID proof image URL
  String? get idProofImageUrl {
    if (idProofImage != null && idProofImage!.isNotEmpty) {
      return ApiConstants.storageUrl(idProofImage!);
    }
    return null;
  }

  /// Get vendor name
  String get vendorName => vendor?.name ?? 'Unknown Vendor';

  /// Get vendor logo URL
  String? get vendorLogoUrl => vendor?.logoUrl;
}

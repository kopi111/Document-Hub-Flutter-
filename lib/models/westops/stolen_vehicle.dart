import 'dart:convert';
import 'dart:typed_data';

/// Stolen vehicle record sourced from the WestOps `StolenVehicles` table.
///
/// Only the columns the UI renders are preserved.
class StolenVehicle {
  final String id;
  final String make;
  final String model;
  final int? year;
  final String? color;
  final String? licensePlate;
  final String? description;
  final DateTime dateStolen;
  final String? lastKnownLocation;
  final String? ownerName;
  final String? ownerContact;
  final double? rewardAmount;
  final String? status;
  final String? photoUrl;

  // Investigating officer assignment.
  final String? investigatingOfficer;

  /// Phone number that reaches the investigating officer directly.
  final String? investigatingOfficerPhone;
  final String? investigatingOfficerSupervisor;
  final String? stationName;
  final String? stationContactNumber;

  /// Locally captured photo (gallery/camera) for records added in-app.
  final Uint8List? photoBytes;

  const StolenVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.dateStolen,
    this.year,
    this.color,
    this.licensePlate,
    this.description,
    this.lastKnownLocation,
    this.ownerName,
    this.ownerContact,
    this.rewardAmount,
    this.status,
    this.investigatingOfficer,
    this.investigatingOfficerPhone,
    this.investigatingOfficerSupervisor,
    this.stationName,
    this.stationContactNumber,
    this.photoBytes,
    this.photoUrl,
  });

  String get displayName {
    final yearText = year == null ? '' : '$year ';
    return '$yearText$make $model';
  }

  factory StolenVehicle.fromJson(Map<String, dynamic> json) {
    return StolenVehicle(
      id: (json['id'] as String?) ?? '',
      make: (json['make'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      dateStolen: _parseDate(json['date_stolen'] as String?) ?? DateTime.now().toUtc(),
      year: json['year'] as int?,
      color: json['color'] as String?,
      licensePlate: json['license_plate'] as String?,
      description: json['description'] as String?,
      lastKnownLocation: json['last_known_location'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerContact: json['owner_contact'] as String?,
      rewardAmount: (json['reward_amount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      photoUrl: json['photo_url'] as String?,
      photoBytes: _decodePhoto(json['photo_base64'] as String?),
      investigatingOfficer: json['investigating_officer'] as String?,
      investigatingOfficerPhone: json['investigating_officer_phone'] as String?,
      investigatingOfficerSupervisor:
          json['investigating_officer_supervisor'] as String?,
      stationName: json['station_name'] as String?,
      stationContactNumber: json['station_contact_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final photoB64 = photoBytes != null ? base64Encode(photoBytes!) : null;
    return {
      'id': id,
      'make': make,
      'model': model,
      'date_stolen': dateStolen.toUtc().toIso8601String(),
      if (year != null) 'year': year,
      if (color != null) 'color': color,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (description != null) 'description': description,
      if (lastKnownLocation != null) 'last_known_location': lastKnownLocation,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerContact != null) 'owner_contact': ownerContact,
      if (rewardAmount != null) 'reward_amount': rewardAmount,
      if (status != null) 'status': status,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoB64 != null) 'photo_base64': photoB64,
      if (investigatingOfficer != null) 'investigating_officer': investigatingOfficer,
      if (investigatingOfficerPhone != null)
        'investigating_officer_phone': investigatingOfficerPhone,
      if (investigatingOfficerSupervisor != null)
        'investigating_officer_supervisor': investigatingOfficerSupervisor,
      if (stationName != null) 'station_name': stationName,
      if (stationContactNumber != null) 'station_contact_number': stationContactNumber,
    };
  }

  static DateTime? _parseDate(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toUtc();

  static Uint8List? _decodePhoto(String? base64Photo) {
    if (base64Photo == null) return null;
    try {
      return base64Decode(base64Photo);
    } on FormatException {
      return null;
    }
  }
}

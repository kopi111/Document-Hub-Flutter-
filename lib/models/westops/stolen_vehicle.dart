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
}

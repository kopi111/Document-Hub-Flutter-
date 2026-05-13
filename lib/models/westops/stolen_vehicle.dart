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
    this.photoUrl,
  });

  String get displayName {
    final yearText = year == null ? '' : '$year ';
    return '$yearText$make $model';
  }
}

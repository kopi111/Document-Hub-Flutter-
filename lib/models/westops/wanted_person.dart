import 'dart:typed_data';

import 'sighting.dart';

/// Wanted person record sourced from the WestOps `wanted_persons` table.
///
/// Only the columns the UI renders are preserved. The full schema lives at
/// `~/projects/WestOPs/sql/westapp.sql`; future fields land here when a
/// screen actually needs them.
class WantedPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String? alias;
  final String? gender;
  final int? age;
  final DateTime? dateOfBirth;
  final String? occupation;
  final String? address;
  final String? placesFrequented;
  final String? crimeDescription;
  final String? photoUrl;

  /// Locally captured photo (gallery/camera) for records added in-app.
  final Uint8List? photoBytes;
  final double? rewardAmount;

  /// Phone number that reaches the investigating officer directly.
  final String? investigatingOfficerPhone;
  final String? investigatingOfficer;
  final String? investigatingOfficerSupervisor;
  final String? stationContactNumber;
  final String? stationName;
  final String? stationNumber;
  final String? status;

  /// Append-only trail of where the person has been seen.
  final List<Sighting> sightings;

  // Capture resolution, populated once the person is apprehended.
  final DateTime? capturedDate;
  final String? capturedLocation;
  final String? capturedBy;
  final String? captureNotes;

  const WantedPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.alias,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.occupation,
    this.address,
    this.placesFrequented,
    this.crimeDescription,
    this.photoUrl,
    this.photoBytes,
    this.rewardAmount,
    this.investigatingOfficerPhone,
    this.investigatingOfficer,
    this.investigatingOfficerSupervisor,
    this.stationContactNumber,
    this.stationName,
    this.stationNumber,
    this.status,
    this.sightings = const [],
    this.capturedDate,
    this.capturedLocation,
    this.capturedBy,
    this.captureNotes,
  });

  static const String statusWanted = 'Wanted';
  static const String statusCaptured = 'Captured';

  String get fullName => '$firstName $lastName';

  bool get isCaptured => status == statusCaptured;

  String get displayName {
    final knownAs = alias;
    if (knownAs == null || knownAs.isEmpty) return fullName;
    return '$fullName "$knownAs"';
  }

  WantedPerson copyWith({
    String? status,
    List<Sighting>? sightings,
    DateTime? capturedDate,
    String? capturedLocation,
    String? capturedBy,
    String? captureNotes,
  }) {
    return WantedPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      alias: alias,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      occupation: occupation,
      address: address,
      placesFrequented: placesFrequented,
      crimeDescription: crimeDescription,
      photoUrl: photoUrl,
      photoBytes: photoBytes,
      rewardAmount: rewardAmount,
      investigatingOfficerPhone: investigatingOfficerPhone,
      investigatingOfficer: investigatingOfficer,
      investigatingOfficerSupervisor: investigatingOfficerSupervisor,
      stationContactNumber: stationContactNumber,
      stationName: stationName,
      stationNumber: stationNumber,
      status: status ?? this.status,
      sightings: sightings ?? this.sightings,
      capturedDate: capturedDate ?? this.capturedDate,
      capturedLocation: capturedLocation ?? this.capturedLocation,
      capturedBy: capturedBy ?? this.capturedBy,
      captureNotes: captureNotes ?? this.captureNotes,
    );
  }
}

import 'dart:convert';
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

  factory WantedPerson.fromJson(Map<String, dynamic> json) {
    return WantedPerson(
      id: (json['id'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      alias: json['alias'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      dateOfBirth: _parseDate(json['date_of_birth'] as String?),
      occupation: json['occupation'] as String?,
      address: json['address'] as String?,
      placesFrequented: json['places_frequented'] as String?,
      crimeDescription: json['crime_description'] as String?,
      photoUrl: json['photo_url'] as String?,
      photoBytes: _decodePhoto(json['photo_base64'] as String?),
      rewardAmount: (json['reward_amount'] as num?)?.toDouble(),
      investigatingOfficerPhone: json['investigating_officer_phone'] as String?,
      investigatingOfficer: json['investigating_officer'] as String?,
      investigatingOfficerSupervisor:
          json['investigating_officer_supervisor'] as String?,
      stationContactNumber: json['station_contact_number'] as String?,
      stationName: json['station_name'] as String?,
      stationNumber: json['station_number'] as String?,
      status: json['status'] as String?,
      capturedDate: _parseDate(json['captured_date'] as String?),
      capturedLocation: json['captured_location'] as String?,
      capturedBy: json['captured_by'] as String?,
      captureNotes: json['capture_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final photoB64 = photoBytes != null ? base64Encode(photoBytes!) : null;
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (alias != null) 'alias': alias,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toUtc().toIso8601String(),
      if (occupation != null) 'occupation': occupation,
      if (address != null) 'address': address,
      if (placesFrequented != null) 'places_frequented': placesFrequented,
      if (crimeDescription != null) 'crime_description': crimeDescription,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoB64 != null) 'photo_base64': photoB64,
      if (rewardAmount != null) 'reward_amount': rewardAmount,
      if (investigatingOfficerPhone != null)
        'investigating_officer_phone': investigatingOfficerPhone,
      if (investigatingOfficer != null)
        'investigating_officer': investigatingOfficer,
      if (investigatingOfficerSupervisor != null)
        'investigating_officer_supervisor': investigatingOfficerSupervisor,
      if (stationContactNumber != null)
        'station_contact_number': stationContactNumber,
      if (stationName != null) 'station_name': stationName,
      if (stationNumber != null) 'station_number': stationNumber,
      if (status != null) 'status': status,
      if (capturedDate != null)
        'captured_date': capturedDate!.toUtc().toIso8601String(),
      if (capturedLocation != null) 'captured_location': capturedLocation,
      if (capturedBy != null) 'captured_by': capturedBy,
      if (captureNotes != null) 'capture_notes': captureNotes,
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

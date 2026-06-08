import 'dart:typed_data';

import 'sighting.dart';

/// Missing person report sourced from the WestOps `MissingPersons` table.
///
/// Only the columns the UI renders are preserved.
class MissingPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String? gender;
  final int? age;
  final DateTime? dateOfBirth;
  final DateTime reportedDate;
  final String? occupation;
  final String? address;
  final String? lastSeenLocation;
  final String? description;

  // Physical description.
  final String? height;
  final String? weight;
  final String? complexion;
  final String? tattoos;
  final String? physicalAbilities;

  final String? photoUrl;

  /// Locally captured photo (gallery/camera) for records added in-app.
  final Uint8List? photoBytes;
  final String? contactPerson;
  final String? contactPhoneNumber;
  final String? investigatingOfficer;
  final String? investigatingOfficerSupervisor;
  final String? stationContactNumber;
  final String? stationName;
  final String? stationNumber;
  final String? status;

  /// Append-only trail of where the person has been seen.
  final List<Sighting> sightings;

  final DateTime? foundDate;
  final String? foundLocation;
  final String? foundBy;
  final String? foundNotes;

  const MissingPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.reportedDate,
    this.gender,
    this.age,
    this.dateOfBirth,
    this.occupation,
    this.address,
    this.lastSeenLocation,
    this.description,
    this.height,
    this.weight,
    this.complexion,
    this.tattoos,
    this.physicalAbilities,
    this.photoUrl,
    this.photoBytes,
    this.contactPerson,
    this.contactPhoneNumber,
    this.investigatingOfficer,
    this.investigatingOfficerSupervisor,
    this.stationContactNumber,
    this.stationName,
    this.stationNumber,
    this.status,
    this.sightings = const [],
    this.foundDate,
    this.foundLocation,
    this.foundBy,
    this.foundNotes,
  });

  static const String statusMissing = 'Missing';
  static const String statusFound = 'Found';

  String get fullName => '$firstName $lastName';

  bool get isFound => status == statusFound;

  MissingPerson copyWith({
    String? status,
    List<Sighting>? sightings,
    DateTime? foundDate,
    String? foundLocation,
    String? foundBy,
    String? foundNotes,
  }) {
    return MissingPerson(
      id: id,
      firstName: firstName,
      lastName: lastName,
      reportedDate: reportedDate,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      occupation: occupation,
      address: address,
      lastSeenLocation: lastSeenLocation,
      description: description,
      height: height,
      weight: weight,
      complexion: complexion,
      tattoos: tattoos,
      physicalAbilities: physicalAbilities,
      photoUrl: photoUrl,
      photoBytes: photoBytes,
      contactPerson: contactPerson,
      contactPhoneNumber: contactPhoneNumber,
      investigatingOfficer: investigatingOfficer,
      investigatingOfficerSupervisor: investigatingOfficerSupervisor,
      stationContactNumber: stationContactNumber,
      stationName: stationName,
      stationNumber: stationNumber,
      status: status ?? this.status,
      sightings: sightings ?? this.sightings,
      foundDate: foundDate ?? this.foundDate,
      foundLocation: foundLocation ?? this.foundLocation,
      foundBy: foundBy ?? this.foundBy,
      foundNotes: foundNotes ?? this.foundNotes,
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'sighting.dart';

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
  final DateTime? lastSeenDate;
  final String? description;
  final String? height;
  final String? weight;
  final String? complexion;
  final String? tattoos;
  final String? physicalAbilities;
  final String? photoUrl;

  /// Locally captured photo bytes (camera/gallery). Populated from [photoBase64] on deserialise.
  final Uint8List? photoBytes;

  /// Raw base64 string as received from the API (`photo_base64`).
  final String? photoBase64;

  final String? parish;
  final DateTime? createdAt;
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
    this.lastSeenDate,
    this.description,
    this.height,
    this.weight,
    this.complexion,
    this.tattoos,
    this.physicalAbilities,
    this.photoUrl,
    this.photoBytes,
    this.photoBase64,
    this.parish,
    this.createdAt,
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

  factory MissingPerson.fromJson(Map<String, dynamic> json) {
    final photoB64 = json['photo_base64'] as String?;
    return MissingPerson(
      id: (json['id'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      dateOfBirth: _parseDate(json['date_of_birth'] as String?),
      reportedDate: _parseDate(json['reported_date'] as String?) ?? DateTime.now().toUtc(),
      occupation: json['occupation'] as String?,
      address: json['address'] as String?,
      lastSeenLocation: json['last_seen_location'] as String?,
      lastSeenDate: _parseDate(json['last_seen_date'] as String?),
      description: json['description'] as String?,
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      complexion: json['complexion'] as String?,
      tattoos: json['tattoos'] as String?,
      physicalAbilities: json['physical_abilities'] as String?,
      photoUrl: json['photo_url'] as String?,
      photoBase64: photoB64,
      photoBytes: _decodePhoto(photoB64),
      parish: json['parish'] as String?,
      createdAt: _parseDate(json['created_at'] as String?),
      contactPerson: json['contact_person'] as String?,
      contactPhoneNumber: json['contact_phone_number'] as String?,
      investigatingOfficer: json['investigating_officer'] as String?,
      investigatingOfficerSupervisor: json['investigating_officer_supervisor'] as String?,
      stationContactNumber: json['station_contact_number'] as String?,
      stationName: json['station_name'] as String?,
      stationNumber: json['station_number'] as String?,
      status: json['status'] as String?,
      foundDate: _parseDate(json['found_date'] as String?),
      foundLocation: json['found_location'] as String?,
      foundBy: json['found_by'] as String?,
      foundNotes: json['found_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final photoB64 =
        photoBase64 ?? (photoBytes != null ? base64Encode(photoBytes!) : null);
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toUtc().toIso8601String(),
      'reported_date': reportedDate.toUtc().toIso8601String(),
      if (occupation != null) 'occupation': occupation,
      if (address != null) 'address': address,
      if (lastSeenLocation != null) 'last_seen_location': lastSeenLocation,
      if (lastSeenDate != null)
        'last_seen_date': lastSeenDate!.toUtc().toIso8601String(),
      if (description != null) 'description': description,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (complexion != null) 'complexion': complexion,
      if (tattoos != null) 'tattoos': tattoos,
      if (physicalAbilities != null) 'physical_abilities': physicalAbilities,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (photoB64 != null) 'photo_base64': photoB64,
      if (parish != null) 'parish': parish,
      if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
      if (contactPerson != null) 'contact_person': contactPerson,
      if (contactPhoneNumber != null) 'contact_phone_number': contactPhoneNumber,
      if (investigatingOfficer != null) 'investigating_officer': investigatingOfficer,
      if (investigatingOfficerSupervisor != null)
        'investigating_officer_supervisor': investigatingOfficerSupervisor,
      if (stationContactNumber != null) 'station_contact_number': stationContactNumber,
      if (stationName != null) 'station_name': stationName,
      if (stationNumber != null) 'station_number': stationNumber,
      if (status != null) 'status': status,
      if (foundDate != null) 'found_date': foundDate!.toUtc().toIso8601String(),
      if (foundLocation != null) 'found_location': foundLocation,
      if (foundBy != null) 'found_by': foundBy,
      if (foundNotes != null) 'found_notes': foundNotes,
    };
  }

  static DateTime? _parseDate(String? s) =>
      s == null ? null : DateTime.tryParse(s)?.toUtc();

  static Uint8List? _decodePhoto(String? base64Photo) {
    if (base64Photo == null) return null;
    try {
      return base64Decode(base64Photo);
    } on FormatException {
      return null;
    }
  }

  MissingPerson copyWith({
    String? id,
    String? status,
    List<Sighting>? sightings,
    DateTime? foundDate,
    String? foundLocation,
    String? foundBy,
    String? foundNotes,
    String? parish,
    DateTime? lastSeenDate,
    String? photoBase64,
    Uint8List? photoBytes,
    DateTime? createdAt,
  }) {
    return MissingPerson(
      id: id ?? this.id,
      firstName: firstName,
      lastName: lastName,
      reportedDate: reportedDate,
      gender: gender,
      age: age,
      dateOfBirth: dateOfBirth,
      occupation: occupation,
      address: address,
      lastSeenLocation: lastSeenLocation,
      lastSeenDate: lastSeenDate ?? this.lastSeenDate,
      description: description,
      height: height,
      weight: weight,
      complexion: complexion,
      tattoos: tattoos,
      physicalAbilities: physicalAbilities,
      photoUrl: photoUrl,
      photoBytes: photoBytes ?? this.photoBytes,
      photoBase64: photoBase64 ?? this.photoBase64,
      parish: parish ?? this.parish,
      createdAt: createdAt ?? this.createdAt,
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

/// Missing person report sourced from the WestOps `MissingPersons` table.
///
/// Only the columns the UI renders are preserved.
class MissingPerson {
  final String id;
  final String firstName;
  final String lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final DateTime reportedDate;
  final String? lastSeenLocation;
  final String? description;
  final String? photoUrl;
  final String? contactPerson;
  final String? contactPhoneNumber;
  final String? investigatingOfficer;
  final String? investigatingOfficerSupervisor;
  final String? stationContactNumber;
  final String? stationName;
  final String? stationNumber;
  final String? status;
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
    this.dateOfBirth,
    this.lastSeenLocation,
    this.description,
    this.photoUrl,
    this.contactPerson,
    this.contactPhoneNumber,
    this.investigatingOfficer,
    this.investigatingOfficerSupervisor,
    this.stationContactNumber,
    this.stationName,
    this.stationNumber,
    this.status,
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
      dateOfBirth: dateOfBirth,
      lastSeenLocation: lastSeenLocation,
      description: description,
      photoUrl: photoUrl,
      contactPerson: contactPerson,
      contactPhoneNumber: contactPhoneNumber,
      investigatingOfficer: investigatingOfficer,
      investigatingOfficerSupervisor: investigatingOfficerSupervisor,
      stationContactNumber: stationContactNumber,
      stationName: stationName,
      stationNumber: stationNumber,
      status: status ?? this.status,
      foundDate: foundDate ?? this.foundDate,
      foundLocation: foundLocation ?? this.foundLocation,
      foundBy: foundBy ?? this.foundBy,
      foundNotes: foundNotes ?? this.foundNotes,
    );
  }
}

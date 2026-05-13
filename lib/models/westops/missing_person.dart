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
  final String? status;

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
    this.status,
  });

  String get fullName => '$firstName $lastName';
}

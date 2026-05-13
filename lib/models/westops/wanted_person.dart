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
  final DateTime? dateOfBirth;
  final String? crimeDescription;
  final String? photoUrl;
  final double? rewardAmount;
  final String? contactPhoneNumber;
  final String? status;

  const WantedPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.alias,
    this.gender,
    this.dateOfBirth,
    this.crimeDescription,
    this.photoUrl,
    this.rewardAmount,
    this.contactPhoneNumber,
    this.status,
  });

  String get fullName => '$firstName $lastName';

  String get displayName {
    final knownAs = alias;
    if (knownAs == null || knownAs.isEmpty) return fullName;
    return '$fullName "$knownAs"';
  }
}

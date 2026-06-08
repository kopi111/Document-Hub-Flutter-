/// A JCF police formation — station, division HQ, specialised unit, or
/// emergency contact — reachable by one or more phone numbers.
///
/// A formation commonly has several lines, so [phones] is a mutable list that
/// officers can add to or trim in the field.
class PoliceFormation {
  PoliceFormation({
    required this.id,
    required this.name,
    required this.parish,
    required List<String> phones,
    required this.type,
  }) : phones = List<String>.of(phones);

  /// Stable identifier used to add or remove numbers.
  final String id;

  /// Display name of the formation (e.g. "Half-Way-Tree Police Station").
  final String name;

  /// Jamaican parish the formation serves (e.g. "St. Andrew").
  final String parish;

  /// One or more numbers as dialled (e.g. "876-926-8121" or "119").
  final List<String> phones;

  /// Broad category: 'Emergency', 'Station', 'Division HQ', or
  /// 'Specialised Unit'.
  final String type;

  static const String typeEmergency = 'Emergency';
  static const String typeStation = 'Station';
  static const String typeDivisionHq = 'Division HQ';
  static const String typeSpecialisedUnit = 'Specialised Unit';
}

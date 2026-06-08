/// A single "last seen" sighting logged against a wanted or missing person.
///
/// The sightings log is append-only: any officer can add an entry, and existing
/// entries are never edited or removed. Each entry records who logged it so the
/// trail of who-saw-what-when is preserved.
class Sighting {
  final String location;
  final DateTime seenAt;
  final String addedBy;
  final String? notes;

  const Sighting({
    required this.location,
    required this.seenAt,
    required this.addedBy,
    this.notes,
  });
}

import '../../models/westops/missing_person.dart';
import '../../models/westops/sighting.dart';

// TODO: Add `HttpMissingPersonsRepository` once the backend ships
// `/api/v1/westops/missing-persons`. It should reuse the existing
// `HttpDocumentHubApiClient` in `lib/services/api/` rather than rolling its
// own transport.
abstract class MissingPersonsRepository {
  Future<List<MissingPerson>> listAll();

  /// Files a new missing-person report and returns the stored record.
  Future<MissingPerson> create(MissingPerson person);

  /// Permanently removes the missing-person record with the given [id].
  Future<void> delete(String id);

  /// Records that a missing person has been located and flips their status to
  /// [MissingPerson.statusFound]. Returns the updated record.
  Future<MissingPerson> markFound({
    required String id,
    required DateTime foundDate,
    required String foundLocation,
    required String foundBy,
    String? foundNotes,
  });

  /// Appends a sighting to the person's last-seen log. Returns the updated
  /// record.
  Future<MissingPerson> addSighting(String id, Sighting sighting);
}

class InMemoryMissingPersonsRepository implements MissingPersonsRepository {
  const InMemoryMissingPersonsRepository();

  @override
  Future<List<MissingPerson>> listAll() async => _seedRecords;

  @override
  Future<MissingPerson> create(MissingPerson person) async {
    _seedRecords.insert(0, person);
    return person;
  }

  @override
  Future<void> delete(String id) async {
    _seedRecords.removeWhere((record) => record.id == id);
  }

  @override
  Future<MissingPerson> markFound({
    required String id,
    required DateTime foundDate,
    required String foundLocation,
    required String foundBy,
    String? foundNotes,
  }) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) {
      throw StateError('No missing person with id $id');
    }
    final updated = _seedRecords[index].copyWith(
      status: MissingPerson.statusFound,
      foundDate: foundDate,
      foundLocation: foundLocation,
      foundBy: foundBy,
      foundNotes: foundNotes,
    );
    _seedRecords[index] = updated;
    return updated;
  }

  @override
  Future<MissingPerson> addSighting(String id, Sighting sighting) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) {
      throw StateError('No missing person with id $id');
    }
    final record = _seedRecords[index];
    final updated = record.copyWith(
      sightings: [...record.sightings, sighting],
    );
    _seedRecords[index] = updated;
    return updated;
  }

  static final List<MissingPerson> _seedRecords = [
    MissingPerson(
      id: 'MP-2001',
      firstName: 'Shanique',
      lastName: 'Bailey',
      gender: 'Female',
      age: 15,
      dateOfBirth: DateTime(2010, 5, 12),
      reportedDate: DateTime(2026, 4, 28),
      occupation: 'Student — Trench Town High',
      address: '3 Collie Smith Drive, Kingston 12',
      lastSeenLocation: 'Trench Town, Kingston 12',
      description: 'Wearing a navy school uniform; last seen walking from school.',
      height: "5'4\"",
      weight: '52 kg',
      complexion: 'Dark',
      tattoos: 'None',
      physicalAbilities: 'No known impairments',
      contactPerson: 'Mrs Bailey (mother)',
      contactPhoneNumber: '876-555-0301',
      photoUrl: 'https://ui-avatars.com/api/?name=Shanique+Bailey&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Tameka Robinson #14237',
      investigatingOfficerSupervisor: 'D/Insp. Howard McKenzie #08891',
      stationContactNumber: '876-967-1561',
      stationName: 'Denham Town Police Station',
      stationNumber: 'STN-DT-014',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2002',
      firstName: 'Karlton',
      lastName: 'Reid',
      gender: 'Male',
      dateOfBirth: DateTime(1954, 2, 10),
      reportedDate: DateTime(2026, 5, 3),
      lastSeenLocation: 'University Hospital, Mona',
      description: 'Suffers from Alzheimer\'s; wandered from the geriatric ward.',
      contactPerson: 'Detective Cpl. Walker',
      contactPhoneNumber: '876-555-0302',
      photoUrl: 'https://ui-avatars.com/api/?name=Karlton+Reid&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Andrew Brown #11542',
      investigatingOfficerSupervisor: 'D/Sgt. Patricia Lyons #07209',
      stationContactNumber: '876-927-1640',
      stationName: 'Mona Police Post',
      stationNumber: 'STN-MN-006',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2003',
      firstName: 'Akeem',
      lastName: 'Grant',
      gender: 'Male',
      dateOfBirth: DateTime(2008, 11, 1),
      reportedDate: DateTime(2026, 5, 6),
      lastSeenLocation: 'Sam Sharpe Square, Montego Bay',
      description: 'Tall, slim build; last seen wearing a red Liverpool jersey.',
      contactPerson: 'Mr Grant (father)',
      contactPhoneNumber: '876-555-0303',
      photoUrl: 'https://ui-avatars.com/api/?name=Akeem+Grant&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Marcia Wright #13876',
      investigatingOfficerSupervisor: 'D/Insp. Garfield Salmon #09102',
      stationContactNumber: '876-952-1557',
      stationName: 'Barnett Street Police Station',
      stationNumber: 'STN-BS-021',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2004',
      firstName: 'Ann-Marie',
      lastName: 'Spence',
      gender: 'Female',
      dateOfBirth: DateTime(1988, 7, 19),
      reportedDate: DateTime(2026, 4, 14),
      lastSeenLocation: 'Negril Beach Road, Westmoreland',
      description: 'Tourist from Portmore; reported missing by travel companion.',
      contactPerson: 'Ms Stewart (friend)',
      contactPhoneNumber: '876-555-0304',
      photoUrl: 'https://ui-avatars.com/api/?name=Ann-Marie+Spence&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Latisha Powell #15011',
      investigatingOfficerSupervisor: 'D/Sgt. Owen Bennett #08456',
      stationContactNumber: '876-957-4267',
      stationName: 'Negril Police Station',
      stationNumber: 'STN-NG-038',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2005',
      firstName: 'Joel',
      lastName: 'Patterson',
      gender: 'Male',
      dateOfBirth: DateTime(2012, 1, 28),
      reportedDate: DateTime(2026, 5, 9),
      lastSeenLocation: 'Spanish Town Plaza, St Catherine',
      description: 'Special-needs child; non-verbal. Wearing yellow t-shirt.',
      contactPerson: 'Mrs Patterson (guardian)',
      contactPhoneNumber: '876-555-0305',
      photoUrl: 'https://ui-avatars.com/api/?name=Joel+Patterson&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Junior Henry #12903',
      investigatingOfficerSupervisor: 'D/Insp. Sandra Allen #07814',
      stationContactNumber: '876-984-2305',
      stationName: 'Spanish Town Police Station',
      stationNumber: 'STN-ST-019',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2006',
      firstName: 'Latoya',
      lastName: 'Brown',
      gender: 'Female',
      dateOfBirth: DateTime(1997, 9, 25),
      reportedDate: DateTime(2026, 3, 30),
      lastSeenLocation: 'Half-Way-Tree Transport Centre',
      description: 'Left work at MegaMart and did not return home.',
      contactPerson: 'Mr Brown (brother)',
      contactPhoneNumber: '876-555-0306',
      photoUrl: 'https://ui-avatars.com/api/?name=Latoya+Brown&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cpl. Devon Chambers #14502',
      investigatingOfficerSupervisor: 'D/Sgt. Carmen Wilson #08123',
      stationContactNumber: '876-926-8121',
      stationName: 'Half-Way-Tree Police Station',
      stationNumber: 'STN-HWT-001',
      status: 'Missing',
    ),
    MissingPerson(
      id: 'MP-2007',
      firstName: 'Devontae',
      lastName: 'Forbes',
      gender: 'Male',
      dateOfBirth: DateTime(2009, 3, 17),
      reportedDate: DateTime(2026, 5, 11),
      lastSeenLocation: 'Yallahs, St Thomas',
      description: 'Runaway from foster placement; may be heading to Kingston.',
      contactPerson: 'CPFSA caseworker',
      contactPhoneNumber: '876-555-0307',
      photoUrl: 'https://ui-avatars.com/api/?name=Devontae+Forbes&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cons. Roxanne Foster #16289',
      investigatingOfficerSupervisor: 'D/Cpl. Errol Thompson #11034',
      stationContactNumber: '876-982-2002',
      stationName: 'Yallahs Police Station',
      stationNumber: 'STN-YL-042',
      status: 'Missing',
    ),
  ];
}

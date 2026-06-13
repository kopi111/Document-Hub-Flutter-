import 'package:http/http.dart' as http;

import '../../models/westops/sighting.dart';
import '../../models/westops/wanted_person.dart';
import '../api/api_config.dart';
import '../api/document_hub_api_client.dart';
import '../api/http_document_hub_api_client.dart';
import '../api/token_provider.dart';
import 'westops_transport.dart';

/// Builds the repository the WestOps wanted screens use when no test double is
/// injected: the live HTTP client backed by [ApiConfig]'s configured base URL.
WantedPersonsRepository createWantedPersonsRepository() =>
    HttpWantedPersonsRepository(apiClient: HttpDocumentHubApiClient());

abstract class WantedPersonsRepository {
  Future<List<WantedPerson>> listAll();

  /// Returns the single record with the given [id]. Throws [StateError] when no
  /// such record exists.
  Future<WantedPerson> getById(String id);

  /// Files a new wanted-person record and returns the stored record.
  Future<WantedPerson> create(WantedPerson person);

  /// Permanently removes the wanted-person record with the given [id].
  Future<void> delete(String id);

  /// Records that a wanted person has been apprehended and flips their status
  /// to [WantedPerson.statusCaptured]. Returns the updated record.
  Future<WantedPerson> markCaptured({
    required String id,
    required DateTime capturedDate,
    required String capturedLocation,
    required String capturedBy,
    String? captureNotes,
  });

  /// Appends a sighting to the person's last-seen log. Returns the updated
  /// record.
  Future<WantedPerson> addSighting(String id, Sighting sighting);
}

class InMemoryWantedPersonsRepository implements WantedPersonsRepository {
  const InMemoryWantedPersonsRepository();

  @override
  Future<List<WantedPerson>> listAll() async => _seedRecords;

  @override
  Future<WantedPerson> getById(String id) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) throw StateError('No wanted person with id $id');
    return _seedRecords[index];
  }

  @override
  Future<WantedPerson> create(WantedPerson person) async {
    _seedRecords.insert(0, person);
    return person;
  }

  @override
  Future<void> delete(String id) async {
    _seedRecords.removeWhere((record) => record.id == id);
  }

  @override
  Future<WantedPerson> markCaptured({
    required String id,
    required DateTime capturedDate,
    required String capturedLocation,
    required String capturedBy,
    String? captureNotes,
  }) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) {
      throw StateError('No wanted person with id $id');
    }
    final updated = _seedRecords[index].copyWith(
      status: WantedPerson.statusCaptured,
      capturedDate: capturedDate,
      capturedLocation: capturedLocation,
      capturedBy: capturedBy,
      captureNotes: captureNotes,
    );
    _seedRecords[index] = updated;
    return updated;
  }

  @override
  Future<WantedPerson> addSighting(String id, Sighting sighting) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) {
      throw StateError('No wanted person with id $id');
    }
    final record = _seedRecords[index];
    final updated = record.copyWith(
      sightings: [...record.sightings, sighting],
    );
    _seedRecords[index] = updated;
    return updated;
  }

  static final List<WantedPerson> _seedRecords = [
    WantedPerson(
      id: 'WP-1001',
      firstName: 'Damion',
      lastName: 'Brown',
      alias: 'Shotta',
      gender: 'Male',
      age: 39,
      dateOfBirth: DateTime(1986, 3, 14),
      occupation: 'Mechanic',
      address: '14 Waltham Park Road, Kingston 11',
      placesFrequented: 'Three Mile, Tivoli Gardens, Spanish Town Road bars',
      crimeDescription: 'Armed robbery — Three Mile, Kingston (Feb 2026).',
      photoUrl: 'https://ui-avatars.com/api/?name=Damion+Brown&size=256&background=random&color=fff&bold=true',
      rewardAmount: 250000,
      investigatingOfficerPhone: '876-555-0142',
      investigatingOfficer: 'D/Sgt. Kemar Lawrence #09745',
      investigatingOfficerSupervisor: 'D/Supt. Mark Russell #04528',
      stationContactNumber: '876-923-7152',
      stationName: "Hunt's Bay Police Station",
      stationNumber: 'STN-HB-027',
      status: 'Wanted',
      sightings: [
        Sighting(
          location: 'Three Mile round-about, Kingston',
          seenAt: DateTime(2026, 5, 18),
          addedBy: 'D/Cons. P. Reid #16402',
          notes: 'Seen on foot heading west; wearing a black hoodie.',
        ),
      ],
    ),
    WantedPerson(
      id: 'WP-1002',
      firstName: 'Tashauna',
      lastName: 'Williams',
      alias: 'Tee',
      gender: 'Female',
      dateOfBirth: DateTime(1992, 9, 2),
      crimeDescription: 'Bank fraud — NCB Half-Way-Tree branch.',
      photoUrl: 'https://ui-avatars.com/api/?name=Tashauna+Williams&size=256&background=random&color=fff&bold=true',
      rewardAmount: 500000,
      investigatingOfficerPhone: '876-555-0177',
      investigatingOfficer: 'D/Cpl. Sherine Davis #13478',
      investigatingOfficerSupervisor: 'D/Insp. Roy Pinnock #08672',
      stationContactNumber: '876-926-8121',
      stationName: 'Half-Way-Tree Police Station',
      stationNumber: 'STN-HWT-001',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1003',
      firstName: 'Kemar',
      lastName: 'Henry',
      alias: 'Smiley',
      gender: 'Male',
      dateOfBirth: DateTime(1981, 11, 22),
      crimeDescription: 'Aggravated assault — Sam Sharpe Square, MoBay.',
      photoUrl: 'https://ui-avatars.com/api/?name=Kemar+Henry&size=256&background=random&color=fff&bold=true',
      rewardAmount: 150000,
      investigatingOfficerPhone: '876-555-0188',
      investigatingOfficer: 'D/Sgt. Tracy-Ann Brown #09921',
      investigatingOfficerSupervisor: 'D/Supt. Vernon Ellis #04201',
      stationContactNumber: '876-952-1557',
      stationName: 'Barnett Street Police Station',
      stationNumber: 'STN-BS-021',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1004',
      firstName: 'Andre',
      lastName: 'Campbell',
      alias: 'Capo',
      gender: 'Male',
      dateOfBirth: DateTime(1989, 6, 18),
      crimeDescription: 'Murder — Spanish Town, St Catherine.',
      photoUrl: 'https://ui-avatars.com/api/?name=Andre+Campbell&size=256&background=random&color=fff&bold=true',
      rewardAmount: 1000000,
      investigatingOfficerPhone: '119',
      investigatingOfficer: 'D/Insp. Wayne Morgan #07623',
      investigatingOfficerSupervisor: 'D/Supt. Lorna Christian #03812',
      stationContactNumber: '876-984-2305',
      stationName: 'Spanish Town Police Station',
      stationNumber: 'STN-ST-019',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1005',
      firstName: 'Marlon',
      lastName: 'Reid',
      gender: 'Male',
      dateOfBirth: DateTime(1994, 1, 5),
      crimeDescription: 'Larceny from dwelling — Mandeville, Manchester.',
      photoUrl: 'https://ui-avatars.com/api/?name=Marlon+Reid&size=256&background=random&color=fff&bold=true',
      rewardAmount: 75000,
      investigatingOfficerPhone: '876-555-0199',
      investigatingOfficer: 'D/Cpl. Sharon Walters #13251',
      investigatingOfficerSupervisor: 'D/Sgt. Howard Reid #08991',
      stationContactNumber: '876-962-2832',
      stationName: 'Mandeville Police Station',
      stationNumber: 'STN-MA-033',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1006',
      firstName: 'Jodian',
      lastName: 'Powell',
      alias: 'Jo',
      gender: 'Female',
      dateOfBirth: DateTime(1996, 4, 30),
      crimeDescription: 'Possession of illegal firearm — May Pen.',
      photoUrl: 'https://ui-avatars.com/api/?name=Jodian+Powell&size=256&background=random&color=fff&bold=true',
      rewardAmount: 200000,
      investigatingOfficerPhone: '876-555-0211',
      investigatingOfficer: 'D/Cpl. Andre Stewart #14087',
      investigatingOfficerSupervisor: 'D/Insp. Patrick Hines #08334',
      stationContactNumber: '876-986-2208',
      stationName: 'May Pen Police Station',
      stationNumber: 'STN-MP-029',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1007',
      firstName: 'Devon',
      lastName: 'Clarke',
      alias: 'Smoke',
      gender: 'Male',
      dateOfBirth: DateTime(1979, 8, 9),
      crimeDescription: 'Conspiracy to defraud — Ocho Rios tourism scheme.',
      photoUrl: 'https://ui-avatars.com/api/?name=Devon+Clarke&size=256&background=random&color=fff&bold=true',
      rewardAmount: 350000,
      investigatingOfficerPhone: '876-555-0223',
      investigatingOfficer: 'D/Sgt. Camille Roberts #09558',
      investigatingOfficerSupervisor: 'D/Insp. Garth Henry #07921',
      stationContactNumber: '876-974-2533',
      stationName: 'Ocho Rios Police Station',
      stationNumber: 'STN-OR-024',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1008',
      firstName: 'Shaneek',
      lastName: 'Morgan',
      gender: 'Female',
      dateOfBirth: DateTime(1990, 12, 14),
      crimeDescription: 'Wounding with intent — Savanna-la-Mar.',
      photoUrl: 'https://ui-avatars.com/api/?name=Shaneek+Morgan&size=256&background=random&color=fff&bold=true',
      rewardAmount: 100000,
      investigatingOfficerPhone: '876-555-0234',
      investigatingOfficer: 'D/Cpl. Nordia Brown #14689',
      investigatingOfficerSupervisor: 'D/Sgt. Trevor Campbell #08778',
      stationContactNumber: '876-955-2531',
      stationName: 'Savanna-la-Mar Police Station',
      stationNumber: 'STN-SV-040',
      status: 'Wanted',
    ),
  ];
}

// ---------------------------------------------------------------------------
// HTTP implementation — wanted persons
// ---------------------------------------------------------------------------

class HttpWantedPersonsRepository implements WantedPersonsRepository {
  static const String _resource = '/westops/wanted-persons';

  // ignore: unused_field — retained for future composition / DI by the coordinator
  final DocumentHubApiClient _apiClient;
  final WestopsTransport _transport;

  HttpWantedPersonsRepository({
    required DocumentHubApiClient apiClient,
    http.Client? httpClient,
    ApiConfig config = const ApiConfig(),
    TokenProvider tokenProvider = const NullTokenProvider(),
  })  : _apiClient = apiClient,
        _transport = WestopsTransport(
          config: config,
          tokenProvider: tokenProvider,
          httpClient: httpClient ?? http.Client(),
        );

  @override
  Future<List<WantedPerson>> listAll() async {
    final json = await _transport.getJson(
      _resource,
      const {'page': '1', 'page_size': '50'},
    );
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((e) => WantedPerson.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<WantedPerson> getById(String id) async {
    final json = await _transport.getJson('$_resource/$id');
    return WantedPerson.fromJson(json);
  }

  @override
  Future<WantedPerson> create(WantedPerson person) async {
    final json = await _transport.postJson(_resource, person.toJson());
    return WantedPerson.fromJson(json);
  }

  @override
  Future<void> delete(String id) async {
    await _transport.deleteResource('$_resource/$id');
  }

  @override
  Future<WantedPerson> markCaptured({
    required String id,
    required DateTime capturedDate,
    required String capturedLocation,
    required String capturedBy,
    String? captureNotes,
  }) async {
    final existing = await getById(id);
    if (existing.isCaptured) {
      throw StateError('Wanted person with id $id is already marked as captured');
    }
    final updated = existing.copyWith(
      status: WantedPerson.statusCaptured,
      capturedDate: capturedDate,
      capturedLocation: capturedLocation,
      capturedBy: capturedBy,
      captureNotes: captureNotes,
    );
    final json = await _transport.putJson('$_resource/$id', updated.toJson());
    return WantedPerson.fromJson(json);
  }

  @override
  Future<WantedPerson> addSighting(String id, Sighting sighting) async {
    await _transport.postJson('/westops/sightings', {
      'person_id': id,
      'location': sighting.location,
      'seen_at': sighting.seenAt.toUtc().toIso8601String(),
      'added_by': sighting.addedBy,
      if (sighting.notes != null) 'notes': sighting.notes,
    });
    return getById(id);
  }
}

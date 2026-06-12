import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/westops/missing_person.dart';
import '../../models/westops/sighting.dart';
import '../api/api_config.dart';
import '../api/api_exception.dart';
import '../api/document_hub_api_client.dart';
import '../api/token_provider.dart';

/// Paged result wrapper returned by [MissingPersonsRepository.listPaged].
class PagedResult<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool hasMore;

  const PagedResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.hasMore,
  });
}

abstract class MissingPersonsRepository {
  /// Returns all records. Prefer [listPaged] for paginated/filtered access.
  Future<List<MissingPerson>> listAll();

  /// Returns a filtered, paginated slice of missing-person records.
  Future<PagedResult<MissingPerson>> listPaged({
    int page = 1,
    int pageSize = 20,
    String? parish,
    String? query,
  });

  /// Files a new missing-person report and returns the stored record.
  Future<MissingPerson> create(MissingPerson person);

  /// Permanently removes the missing-person record with the given [id].
  Future<void> delete(String id);

  /// Records that a missing person has been located and flips their status to
  /// [MissingPerson.statusFound]. Returns the updated record.
  ///
  /// Throws [StateError] if the record is already marked as found.
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

// ---------------------------------------------------------------------------
// In-memory implementation (seed data; used as the app default)
// ---------------------------------------------------------------------------

class InMemoryMissingPersonsRepository implements MissingPersonsRepository {
  const InMemoryMissingPersonsRepository();

  @override
  Future<List<MissingPerson>> listAll() async => List.unmodifiable(_seedRecords);

  @override
  Future<PagedResult<MissingPerson>> listPaged({
    int page = 1,
    int pageSize = 20,
    String? parish,
    String? query,
  }) async {
    final filtered = _seedRecords.where((p) {
      if (parish != null && p.parish != parish) return false;
      if (query != null) {
        final q = query.toLowerCase();
        if (!p.fullName.toLowerCase().contains(q) &&
            !(p.description?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);

    final total = filtered.length;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, total);
    final pageItems =
        start >= total ? <MissingPerson>[] : filtered.sublist(start, end);

    return PagedResult(
      items: pageItems,
      page: page,
      pageSize: pageSize,
      totalItems: total,
      hasMore: end < total,
    );
  }

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
    if (index == -1) throw StateError('No missing person with id $id');
    if (_seedRecords[index].isFound) {
      throw StateError('Missing person with id $id is already marked as found');
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
    if (index == -1) throw StateError('No missing person with id $id');
    final updated = _seedRecords[index].copyWith(
      sightings: [..._seedRecords[index].sightings, sighting],
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Shanique+Bailey&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Karlton+Reid&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Akeem+Grant&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Ann-Marie+Spence&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Joel+Patterson&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Latoya+Brown&size=256&background=random&color=fff&bold=true',
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
      photoUrl:
          'https://ui-avatars.com/api/?name=Devontae+Forbes&size=256&background=random&color=fff&bold=true',
      investigatingOfficer: 'D/Cons. Roxanne Foster #16289',
      investigatingOfficerSupervisor: 'D/Cpl. Errol Thompson #11034',
      stationContactNumber: '876-982-2002',
      stationName: 'Yallahs Police Station',
      stationNumber: 'STN-YL-042',
      status: 'Missing',
    ),
  ];
}

// ---------------------------------------------------------------------------
// Shared HTTP transport helper (private to this file)
// ---------------------------------------------------------------------------

class _WestopsTransport {
  final http.Client _httpClient;
  final ApiConfig _config;
  final TokenProvider _tokenProvider;

  _WestopsTransport({
    required ApiConfig config,
    required TokenProvider tokenProvider,
    required http.Client httpClient,
  })  : _config = config,
        _tokenProvider = tokenProvider,
        _httpClient = httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, [
    Map<String, String>? params,
  ]) async {
    final uri = _resolve(path, params);
    final response = await _httpClient.get(uri, headers: await _headers());
    _throwIfError(response);
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _resolve(path);
    final response = await _httpClient.post(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(body),
    );
    _throwIfError(response);
    if (response.bodyBytes.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = _resolve(path);
    final response = await _httpClient.put(
      uri,
      headers: await _headers(withContentType: true),
      body: jsonEncode(body),
    );
    _throwIfError(response);
    if (response.bodyBytes.isEmpty) return {};
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> deleteResource(String path) async {
    final uri = _resolve(path);
    final response =
        await _httpClient.delete(uri, headers: await _headers());
    _throwIfError(response);
  }

  Uri _resolve(String path, [Map<String, String>? query]) {
    final base = Uri.parse(_config.baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: query,
    );
  }

  Future<Map<String, String>> _headers({bool withContentType = false}) async {
    final token = await _tokenProvider.currentAccessToken();
    return {
      'Accept': 'application/json',
      if (withContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message;
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      message = (body['message'] as String?) ?? 'HTTP ${response.statusCode}';
    } catch (_) {
      message = 'HTTP ${response.statusCode}';
    }
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      default:
        if (response.statusCode >= 500) throw ServerException(message);
        throw ApiException(message);
    }
  }
}

// ---------------------------------------------------------------------------
// HTTP implementation — missing persons
// ---------------------------------------------------------------------------

class HttpMissingPersonsRepository implements MissingPersonsRepository {
  // ignore: unused_field — retained for future composition / DI by the coordinator
  final DocumentHubApiClient _apiClient;
  final _WestopsTransport _transport;

  HttpMissingPersonsRepository({
    required DocumentHubApiClient apiClient,
    http.Client? httpClient,
    ApiConfig config = const ApiConfig(),
    TokenProvider tokenProvider = const NullTokenProvider(),
  })  : _apiClient = apiClient,
        _transport = _WestopsTransport(
          config: config,
          tokenProvider: tokenProvider,
          httpClient: httpClient ?? http.Client(),
        );

  @override
  Future<List<MissingPerson>> listAll() async {
    final result = await listPaged(page: 1, pageSize: 50);
    return result.items;
  }

  @override
  Future<PagedResult<MissingPerson>> listPaged({
    int page = 1,
    int pageSize = 20,
    String? parish,
    String? query,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (parish != null) 'parish': parish,
      if (query != null) 'q': query,
    };
    final json =
        await _transport.getJson('/westops/missing-persons', params);
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedResult(
      items: rawItems
          .map((e) => MissingPerson.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      page: json['page'] as int? ?? page,
      pageSize: json['page_size'] as int? ?? pageSize,
      totalItems: json['total_items'] as int? ?? rawItems.length,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  @override
  Future<MissingPerson> create(MissingPerson person) async {
    final json = await _transport.postJson(
      '/westops/missing-persons',
      person.toJson(),
    );
    return MissingPerson.fromJson(json);
  }

  @override
  Future<void> delete(String id) async {
    await _transport.deleteResource('/westops/missing-persons/$id');
  }

  @override
  Future<MissingPerson> markFound({
    required String id,
    required DateTime foundDate,
    required String foundLocation,
    required String foundBy,
    String? foundNotes,
  }) async {
    final existing = await _fetchById(id);
    if (existing.isFound) {
      throw StateError('Missing person with id $id is already marked as found');
    }
    final updated = existing.copyWith(
      status: MissingPerson.statusFound,
      foundDate: foundDate,
      foundLocation: foundLocation,
      foundBy: foundBy,
      foundNotes: foundNotes,
    );
    final json = await _transport.putJson(
      '/westops/missing-persons/$id',
      updated.toJson(),
    );
    return MissingPerson.fromJson(json);
  }

  @override
  Future<MissingPerson> addSighting(String id, Sighting sighting) async {
    await _transport.postJson('/westops/sightings', {
      'person_id': id,
      'location': sighting.location,
      'seen_at': sighting.seenAt.toUtc().toIso8601String(),
      'added_by': sighting.addedBy,
      if (sighting.notes != null) 'notes': sighting.notes,
    });
    return _fetchById(id);
  }

  Future<MissingPerson> _fetchById(String id) async {
    final json =
        await _transport.getJson('/westops/missing-persons/$id');
    return MissingPerson.fromJson(json);
  }
}

// ---------------------------------------------------------------------------
// HTTP implementation — sightings
// ---------------------------------------------------------------------------

class HttpSightingsRepository {
  // ignore: unused_field — retained for future composition / DI by the coordinator
  final DocumentHubApiClient _apiClient;
  final _WestopsTransport _transport;

  HttpSightingsRepository({
    required DocumentHubApiClient apiClient,
    http.Client? httpClient,
    ApiConfig config = const ApiConfig(),
    TokenProvider tokenProvider = const NullTokenProvider(),
  })  : _apiClient = apiClient,
        _transport = _WestopsTransport(
          config: config,
          tokenProvider: tokenProvider,
          httpClient: httpClient ?? http.Client(),
        );

  Future<void> createSighting({
    required String personId,
    required String location,
    required DateTime seenAt,
    required String addedBy,
    String? notes,
  }) async {
    await _transport.postJson('/westops/sightings', {
      'person_id': personId,
      'location': location,
      'seen_at': seenAt.toUtc().toIso8601String(),
      'added_by': addedBy,
      if (notes != null) 'notes': notes,
    });
  }
}

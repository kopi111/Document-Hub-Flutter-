import 'package:http/http.dart' as http;

import '../../models/westops/stolen_vehicle.dart';
import '../api/api_config.dart';
import '../api/document_hub_api_client.dart';
import '../api/http_document_hub_api_client.dart';
import '../api/token_provider.dart';
import 'westops_transport.dart';

/// Builds the repository the stolen-vehicle screens use when none is injected:
/// the live HTTP client backed by [ApiConfig]'s configured base URL.
StolenVehiclesRepository createStolenVehiclesRepository() =>
    HttpStolenVehiclesRepository(apiClient: HttpDocumentHubApiClient());

abstract class StolenVehiclesRepository {
  Future<List<StolenVehicle>> listAll();

  /// Returns the single record with the given [id]. Throws [StateError] when no
  /// such record exists.
  Future<StolenVehicle> getById(String id);

  /// Files a new stolen-vehicle report and returns the stored record.
  Future<StolenVehicle> create(StolenVehicle vehicle);

  /// Permanently removes the stolen-vehicle record with the given [id].
  Future<void> delete(String id);
}

class InMemoryStolenVehiclesRepository implements StolenVehiclesRepository {
  const InMemoryStolenVehiclesRepository();

  @override
  Future<List<StolenVehicle>> listAll() async => _seedRecords;

  @override
  Future<StolenVehicle> getById(String id) async {
    final index = _seedRecords.indexWhere((record) => record.id == id);
    if (index == -1) throw StateError('No stolen vehicle with id $id');
    return _seedRecords[index];
  }

  @override
  Future<StolenVehicle> create(StolenVehicle vehicle) async {
    _seedRecords.insert(0, vehicle);
    return vehicle;
  }

  @override
  Future<void> delete(String id) async {
    _seedRecords.removeWhere((record) => record.id == id);
  }

  static final List<StolenVehicle> _seedRecords = [
    StolenVehicle(
      id: 'SV-3001',
      make: 'Toyota',
      model: 'Corolla',
      year: 2018,
      color: 'White',
      licensePlate: '1234 AB',
      description: 'Tinted windows, small dent on rear bumper.',
      dateStolen: DateTime(2026, 5, 1),
      lastKnownLocation: 'Liguanea, St Andrew',
      ownerName: 'Mr Anthony Chin',
      ownerContact: '876-555-0401',
      rewardAmount: 100000,
      status: 'Stolen',
      investigatingOfficer: 'D/Cpl. Sanjay Walters #13902',
      investigatingOfficerPhone: '876-555-0451',
      investigatingOfficerSupervisor: 'D/Sgt. Marlon Foster #08221',
      stationName: 'Liguanea Police Station',
      stationContactNumber: '876-927-7493',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Toyota+Corolla+2018',
    ),
    StolenVehicle(
      id: 'SV-3002',
      make: 'Honda',
      model: 'CR-V',
      year: 2020,
      color: 'Silver',
      licensePlate: '5678 CD',
      description: 'Roof rack fitted, custom alloy rims.',
      dateStolen: DateTime(2026, 4, 22),
      lastKnownLocation: 'Sunshine Plaza, Portmore',
      ownerName: 'Mrs Camille Henry',
      ownerContact: '876-555-0402',
      rewardAmount: 150000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Honda+CR-V+2020',
    ),
    StolenVehicle(
      id: 'SV-3003',
      make: 'Nissan',
      model: 'Tiida',
      year: 2015,
      color: 'Black',
      licensePlate: '9012 EF',
      description: 'After-market exhaust, JBL subwoofer in trunk.',
      dateStolen: DateTime(2026, 5, 7),
      lastKnownLocation: 'Sam Sharpe Square, Montego Bay',
      ownerName: 'Mr Roger Mills',
      ownerContact: '876-555-0403',
      rewardAmount: 75000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Nissan+Tiida+2015',
    ),
    StolenVehicle(
      id: 'SV-3004',
      make: 'Toyota',
      model: 'Hilux',
      year: 2022,
      color: 'Dark Grey',
      licensePlate: '3456 GH',
      description: 'JCF DriveCheck sticker on windshield; tray-bed cover.',
      dateStolen: DateTime(2026, 3, 18),
      lastKnownLocation: 'Constant Spring Road, Kingston 8',
      ownerName: 'Ms Tiffany Walters',
      ownerContact: '876-555-0404',
      rewardAmount: 250000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Toyota+Hilux+2022',
    ),
    StolenVehicle(
      id: 'SV-3005',
      make: 'Suzuki',
      model: 'Swift',
      year: 2017,
      color: 'Red',
      licensePlate: '7890 IJ',
      description: 'Slight scratch on driver-side door.',
      dateStolen: DateTime(2026, 5, 4),
      lastKnownLocation: 'Mandeville Town Centre',
      ownerName: 'Mr Garfield Hines',
      ownerContact: '876-555-0405',
      rewardAmount: 60000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Suzuki+Swift+2017',
    ),
    StolenVehicle(
      id: 'SV-3006',
      make: 'Mazda',
      model: 'Demio',
      year: 2019,
      color: 'Blue',
      licensePlate: '2468 KL',
      description: 'TT Riders sticker on rear window.',
      dateStolen: DateTime(2026, 4, 30),
      lastKnownLocation: 'Ocho Rios Bay Beach car park',
      ownerName: 'Mrs Sandra Lewis',
      ownerContact: '876-555-0406',
      rewardAmount: 80000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Mazda+Demio+2019',
    ),
    StolenVehicle(
      id: 'SV-3007',
      make: 'Mitsubishi',
      model: 'Lancer',
      year: 2014,
      color: 'White',
      licensePlate: '1357 MN',
      description: 'Body kit, after-market spoiler.',
      dateStolen: DateTime(2026, 5, 10),
      lastKnownLocation: 'Spanish Town Bypass',
      ownerName: 'Mr Junior Wilson',
      ownerContact: '876-555-0407',
      rewardAmount: 50000,
      status: 'Stolen',
      photoUrl: 'https://placehold.co/600x400/1a1a1a/f5d97b?text=Mitsubishi+Lancer+2014',
    ),
  ];
}

// ---------------------------------------------------------------------------
// HTTP implementation — stolen vehicles
// ---------------------------------------------------------------------------

class HttpStolenVehiclesRepository implements StolenVehiclesRepository {
  static const String _resource = '/westops/stolen-vehicles';

  // ignore: unused_field — retained for future composition / DI by the coordinator
  final DocumentHubApiClient _apiClient;
  final WestopsTransport _transport;

  HttpStolenVehiclesRepository({
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
  Future<List<StolenVehicle>> listAll() async {
    final json = await _transport.getJson(
      _resource,
      const {'page': '1', 'page_size': '50'},
    );
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((e) => StolenVehicle.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<StolenVehicle> getById(String id) async {
    final json = await _transport.getJson('$_resource/$id');
    return StolenVehicle.fromJson(json);
  }

  @override
  Future<StolenVehicle> create(StolenVehicle vehicle) async {
    final json = await _transport.postJson(_resource, vehicle.toJson());
    return StolenVehicle.fromJson(json);
  }

  @override
  Future<void> delete(String id) async {
    await _transport.deleteResource('$_resource/$id');
  }
}

import '../../models/westops/traffic_code.dart';

// TODO: Add `HttpTrafficCodesRepository` once the backend ships
// `/api/v1/westops/traffic-codes`. It should reuse the existing
// `HttpDocumentHubApiClient` in `lib/services/api/` rather than rolling its
// own transport.
abstract class TrafficCodesRepository {
  Future<List<TrafficCode>> listAll();
}

/// Seeded sample drawn from the Road Traffic Act offence schedule that the
/// WestOps app ships in `lib/modles/trafficCode.dart`. The full catalogue
/// holds 147 entries; this in-memory stub keeps a representative slice so
/// screens render usefully before the backend exposes the full list.
class InMemoryTrafficCodesRepository implements TrafficCodesRepository {
  const InMemoryTrafficCodesRepository();

  @override
  Future<List<TrafficCode>> listAll() async => _seedRecords;

  static const List<TrafficCode> _seedRecords = [
    TrafficCode(
      code: 'D005',
      offenceDescription: 'Careless Driving Causing Collision',
      fineAmount: 25000,
      demeritPoints: 10,
      legalSection: 'Section 59(1)',
    ),
    TrafficCode(
      code: 'D006',
      offenceDescription: 'Careless Driving Where No Collision Occurs',
      fineAmount: 11000,
      demeritPoints: 4,
      legalSection: 'Section 59(1)',
    ),
    TrafficCode(
      code: 'D015',
      offenceDescription: 'Disobeying Traffic Light Or Stop Sign',
      fineAmount: 10000,
      demeritPoints: 6,
      legalSection: 'Section 52(2)(a)',
    ),
    TrafficCode(
      code: 'D018',
      offenceDescription: 'Driver Failing to Cause Passenger To Wear Seatbelt',
      fineAmount: 2000,
      demeritPoints: 2,
      legalSection: 'Section 72(4)',
    ),
    TrafficCode(
      code: 'D030',
      offenceDescription: 'Driving/Riding in a Motor Vehicle Without Seatbelt On',
      fineAmount: 2000,
      demeritPoints: 2,
      legalSection: 'Section 72(4)',
    ),
    TrafficCode(
      code: 'D033',
      offenceDescription: 'Exceeding Speed Limit In Construction Zone; 50 Or More Kilometers Per Hour',
      fineAmount: 30000,
      demeritPoints: 10,
      legalSection: 'Section 77(3)',
    ),
    TrafficCode(
      code: 'D036',
      offenceDescription: 'Exceeding Speed Limit In School Safety Zone; 50 or More Kilometres Per Hour',
      fineAmount: 30000,
      demeritPoints: 10,
      legalSection: 'Section 76(4)',
    ),
    TrafficCode(
      code: 'D039',
      offenceDescription: 'Exceeding Speed Limit; 50 Or More Kilometers Per Hour',
      fineAmount: 15000,
      demeritPoints: 6,
      legalSection: 'Section 55(3)',
    ),
    TrafficCode(
      code: 'D080',
      offenceDescription: 'No Motor Vehicle Insurance',
      fineAmount: 20000,
      demeritPoints: 0,
      legalSection: 'Section 7(3)',
    ),
    TrafficCode(
      code: 'D110',
      offenceDescription: 'Smoking Ganja While Driving Or Attempting To Drive Or While Being In Charge Of A Vehicle On A Road',
      fineAmount: 500000,
      demeritPoints: 14,
      legalSection: 'Section 20(4)',
    ),
  ];
}

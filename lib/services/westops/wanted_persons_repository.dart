import '../../models/westops/wanted_person.dart';

// TODO: Add `HttpWantedPersonsRepository` once the backend ships
// `/api/v1/westops/wanted-persons`. It should reuse the existing
// `HttpDocumentHubApiClient` in `lib/services/api/` rather than rolling its
// own transport.
abstract class WantedPersonsRepository {
  Future<List<WantedPerson>> listAll();
}

class InMemoryWantedPersonsRepository implements WantedPersonsRepository {
  const InMemoryWantedPersonsRepository();

  @override
  Future<List<WantedPerson>> listAll() async => _seedRecords;

  static final List<WantedPerson> _seedRecords = [
    WantedPerson(
      id: 'WP-1001',
      firstName: 'Damion',
      lastName: 'Brown',
      alias: 'Shotta',
      gender: 'Male',
      dateOfBirth: DateTime(1986, 3, 14),
      crimeDescription: 'Armed robbery — Three Mile, Kingston (Feb 2026).',
      rewardAmount: 250000,
      contactPhoneNumber: '876-555-0142',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1002',
      firstName: 'Tashauna',
      lastName: 'Williams',
      alias: 'Tee',
      gender: 'Female',
      dateOfBirth: DateTime(1992, 9, 2),
      crimeDescription: 'Bank fraud — NCB Half-Way-Tree branch.',
      rewardAmount: 500000,
      contactPhoneNumber: '876-555-0177',
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
      rewardAmount: 150000,
      contactPhoneNumber: '876-555-0188',
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
      rewardAmount: 1000000,
      contactPhoneNumber: '119',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1005',
      firstName: 'Marlon',
      lastName: 'Reid',
      gender: 'Male',
      dateOfBirth: DateTime(1994, 1, 5),
      crimeDescription: 'Larceny from dwelling — Mandeville, Manchester.',
      rewardAmount: 75000,
      contactPhoneNumber: '876-555-0199',
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
      rewardAmount: 200000,
      contactPhoneNumber: '876-555-0211',
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
      rewardAmount: 350000,
      contactPhoneNumber: '876-555-0223',
      status: 'Wanted',
    ),
    WantedPerson(
      id: 'WP-1008',
      firstName: 'Shaneek',
      lastName: 'Morgan',
      gender: 'Female',
      dateOfBirth: DateTime(1990, 12, 14),
      crimeDescription: 'Wounding with intent — Savanna-la-Mar.',
      rewardAmount: 100000,
      contactPhoneNumber: '876-555-0234',
      status: 'Wanted',
    ),
  ];
}

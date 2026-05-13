import '../../models/westops/missing_person.dart';

// TODO: Add `HttpMissingPersonsRepository` once the backend ships
// `/api/v1/westops/missing-persons`. It should reuse the existing
// `HttpDocumentHubApiClient` in `lib/services/api/` rather than rolling its
// own transport.
abstract class MissingPersonsRepository {
  Future<List<MissingPerson>> listAll();
}

class InMemoryMissingPersonsRepository implements MissingPersonsRepository {
  const InMemoryMissingPersonsRepository();

  @override
  Future<List<MissingPerson>> listAll() async => _seedRecords;

  static final List<MissingPerson> _seedRecords = [
    MissingPerson(
      id: 'MP-2001',
      firstName: 'Shanique',
      lastName: 'Bailey',
      gender: 'Female',
      dateOfBirth: DateTime(2010, 5, 12),
      reportedDate: DateTime(2026, 4, 28),
      lastSeenLocation: 'Trench Town, Kingston 12',
      description: 'Wearing a navy school uniform; last seen walking from school.',
      contactPerson: 'Mrs Bailey (mother)',
      contactPhoneNumber: '876-555-0301',
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
      status: 'Missing',
    ),
  ];
}

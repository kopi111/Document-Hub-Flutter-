import '../../models/directory/police_formation.dart';

abstract class PoliceFormationsRepository {
  Future<List<PoliceFormation>> listAll();

  /// Adds [number] to the formation's line-up. No-op for blanks or duplicates.
  Future<void> addNumber(String formationId, String number);

  /// Removes [number] from the formation's line-up.
  Future<void> removeNumber(String formationId, String number);
}

class InMemoryPoliceFormationsRepository implements PoliceFormationsRepository {
  InMemoryPoliceFormationsRepository();

  @override
  Future<List<PoliceFormation>> listAll() async => _formations;

  @override
  Future<void> addNumber(String formationId, String number) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return;
    final phones = _formationFor(formationId).phones;
    if (phones.contains(trimmed)) return;
    phones.add(trimmed);
  }

  @override
  Future<void> removeNumber(String formationId, String number) async {
    _formationFor(formationId).phones.remove(number);
  }

  PoliceFormation _formationFor(String id) =>
      _formations.firstWhere((formation) => formation.id == id);

  static final List<PoliceFormation> _formations = [
    // ── Emergency ────────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-emergency',
      name: 'Police Emergency',
      parish: 'Island-Wide',
      phones: ['119', '112'],
      type: PoliceFormation.typeEmergency,
    ),
    PoliceFormation(
      id: 'f-control-room',
      name: 'Police Control Room',
      parish: 'Island-Wide',
      phones: ['876-922-0000'],
      type: PoliceFormation.typeEmergency,
    ),

    // ── Kingston & St. Andrew — Division HQ ─────────────────────────────────
    PoliceFormation(
      id: 'f-ksa-west-hq',
      name: 'Kingston Western Division HQ',
      parish: 'Kingston',
      phones: ['876-967-1635'],
      type: PoliceFormation.typeDivisionHq,
    ),
    PoliceFormation(
      id: 'f-ksa-east-hq',
      name: 'Kingston Eastern Division HQ',
      parish: 'Kingston',
      phones: ['876-938-0050'],
      type: PoliceFormation.typeDivisionHq,
    ),

    // ── Kingston & St. Andrew — Stations ─────────────────────────────────────
    PoliceFormation(
      id: 'f-central',
      name: 'Central Police Station',
      parish: 'Kingston',
      phones: ['876-922-6616'],
      type: PoliceFormation.typeStation,
    ),
    PoliceFormation(
      id: 'f-denham-town',
      name: 'Denham Town Police Station',
      parish: 'Kingston',
      phones: ['876-937-1437'],
      type: PoliceFormation.typeStation,
    ),
    PoliceFormation(
      id: 'f-hunts-bay',
      name: 'Hunt\'s Bay Police Station',
      parish: 'Kingston',
      phones: ['876-923-7111'],
      type: PoliceFormation.typeStation,
    ),
    PoliceFormation(
      id: 'f-half-way-tree',
      name: 'Half-Way-Tree Police Station',
      parish: 'St. Andrew',
      phones: ['876-926-8121', '876-926-8123', '876-754-0357'],
      type: PoliceFormation.typeStation,
    ),

    // ── St. Catherine ─────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-stc-north-hq',
      name: 'St. Catherine North Division HQ',
      parish: 'St. Catherine',
      phones: ['876-984-2305'],
      type: PoliceFormation.typeDivisionHq,
    ),
    PoliceFormation(
      id: 'f-spanish-town',
      name: 'Spanish Town Police Station',
      parish: 'St. Catherine',
      phones: ['876-984-2305', '876-984-3162'],
      type: PoliceFormation.typeStation,
    ),
    PoliceFormation(
      id: 'f-portmore',
      name: 'Portmore Police Station',
      parish: 'St. Catherine',
      phones: ['876-939-8101'],
      type: PoliceFormation.typeStation,
    ),

    // ── St. James ─────────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-stj-hq',
      name: 'St. James Division HQ',
      parish: 'St. James',
      phones: ['876-952-1991'],
      type: PoliceFormation.typeDivisionHq,
    ),
    PoliceFormation(
      id: 'f-barnett-street',
      name: 'Barnett Street Police Station',
      parish: 'St. James',
      phones: ['876-952-1991', '876-971-9388'],
      type: PoliceFormation.typeStation,
    ),

    // ── Manchester ───────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-mandeville',
      name: 'Mandeville Police Station',
      parish: 'Manchester',
      phones: ['876-962-2250'],
      type: PoliceFormation.typeStation,
    ),

    // ── Clarendon ─────────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-may-pen',
      name: 'May Pen Police Station',
      parish: 'Clarendon',
      phones: ['876-986-2208'],
      type: PoliceFormation.typeStation,
    ),

    // ── St. Ann ───────────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-ocho-rios',
      name: 'Ocho Rios Police Station',
      parish: 'St. Ann',
      phones: ['876-974-2533'],
      type: PoliceFormation.typeStation,
    ),

    // ── Westmoreland ─────────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-negril',
      name: 'Negril Police Station',
      parish: 'Westmoreland',
      phones: ['876-957-4268'],
      type: PoliceFormation.typeStation,
    ),

    // ── Specialised Units ─────────────────────────────────────────────────────
    PoliceFormation(
      id: 'f-ctoc',
      name: 'Counter-Terrorism and Organised Crime (CTOC)',
      parish: 'Kingston',
      phones: ['876-630-3800', '876-630-3801'],
      type: PoliceFormation.typeSpecialisedUnit,
    ),
    PoliceFormation(
      id: 'f-ctu',
      name: 'Counter-Terrorism Unit',
      parish: 'Kingston',
      phones: ['876-630-3820'],
      type: PoliceFormation.typeSpecialisedUnit,
    ),
    PoliceFormation(
      id: 'f-moca',
      name: 'Major Organised Crime & Anti-Corruption Agency (MOCA)',
      parish: 'Kingston',
      phones: ['876-754-3700'],
      type: PoliceFormation.typeSpecialisedUnit,
    ),
  ];
}

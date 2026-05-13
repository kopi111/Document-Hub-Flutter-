/// A Road Traffic Act offence entry.
///
/// WestOps stores these as four parallel arrays in
/// `lib/modles/trafficCode.dart`; here they are joined into a single
/// immutable record because every consumer needs all four fields together.
class TrafficCode {
  final String code;
  final String offenceDescription;
  final double fineAmount;
  final int demeritPoints;
  final String legalSection;

  const TrafficCode({
    required this.code,
    required this.offenceDescription,
    required this.fineAmount,
    required this.demeritPoints,
    required this.legalSection,
  });
}

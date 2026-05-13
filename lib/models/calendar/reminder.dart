class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime scheduledFor;

  const Reminder({
    required this.id,
    required this.title,
    required this.scheduledFor,
    this.description,
  });

  DateTime get day =>
      DateTime(scheduledFor.year, scheduledFor.month, scheduledFor.day);
}

import '../../models/calendar/reminder.dart';

abstract class ReminderRepository {
  List<Reminder> remindersOn(DateTime day);
  List<DateTime> daysWithReminders();
  void add(Reminder reminder);
  void remove(String reminderId);
}

class InMemoryReminderRepository implements ReminderRepository {
  final Map<String, Reminder> _byId = {};

  @override
  List<Reminder> remindersOn(DateTime day) {
    final target = _startOfDay(day);
    return _byId.values
        .where((reminder) => _startOfDay(reminder.scheduledFor) == target)
        .toList(growable: false)
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  @override
  List<DateTime> daysWithReminders() {
    final unique = <DateTime>{
      for (final reminder in _byId.values) _startOfDay(reminder.scheduledFor),
    };
    return unique.toList(growable: false);
  }

  @override
  void add(Reminder reminder) {
    _byId[reminder.id] = reminder;
  }

  @override
  void remove(String reminderId) {
    _byId.remove(reminderId);
  }

  DateTime _startOfDay(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);
}

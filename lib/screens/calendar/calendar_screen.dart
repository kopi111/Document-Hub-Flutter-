import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar/reminder.dart';
import '../../services/calendar/reminder_repository.dart';
import '../../widgets/breadcrumb_trail.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ReminderRepository _repository = InMemoryReminderRepository();
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remindersForDay = _repository.remindersOn(_selectedDay);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        bottom: BreadcrumbTrail(segments: _breadcrumbSegments()),
      ),
      body: Column(
        children: [
          TableCalendar<Reminder>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _repository.remindersOn,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.twoWeeks: '2 weeks',
              CalendarFormat.week: 'Week',
            },
            onDaySelected: _selectDay,
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: colors.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildRemindersList(remindersForDay)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add reminder'),
      ),
    );
  }

  List<BreadcrumbSegment> _breadcrumbSegments() {
    return [
      BreadcrumbSegment(
        label: 'Home',
        onTap: Navigator.canPop(context)
            ? () => Navigator.popUntil(context, (route) => route.isFirst)
            : null,
      ),
      const BreadcrumbSegment(label: 'Calendar'),
    ];
  }

  Widget _buildRemindersList(List<Reminder> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No reminders for ${_formatDayLabel(_selectedDay)}.\nTap “Add reminder” to create one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: reminders.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return ListTile(
          leading: const Icon(Icons.alarm),
          title: Text(reminder.title),
          subtitle: Text(_formatTime(reminder.scheduledFor) +
              (reminder.description != null
                  ? '  ·  ${reminder.description}'
                  : '')),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete reminder',
            onPressed: () => _deleteReminder(reminder.id),
          ),
        );
      },
    );
  }

  void _selectDay(DateTime day, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _focusedDay = focused;
    });
  }

  Future<void> _showAddReminderDialog() async {
    final reminder = await showDialog<Reminder>(
      context: context,
      builder: (context) => _AddReminderDialog(initialDay: _selectedDay),
    );
    if (reminder == null) return;
    setState(() => _repository.add(reminder));
  }

  void _deleteReminder(String id) {
    setState(() => _repository.remove(id));
  }

  String _formatDayLabel(DateTime day) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[day.month - 1]} ${day.day}';
  }

  String _formatTime(DateTime moment) {
    final hour = moment.hour == 0
        ? 12
        : (moment.hour > 12 ? moment.hour - 12 : moment.hour);
    final suffix = moment.hour >= 12 ? 'PM' : 'AM';
    final minute = moment.minute.toString().padLeft(2, '0');
    return '$hour:$minute $suffix';
  }
}

class _AddReminderDialog extends StatefulWidget {
  const _AddReminderDialog({required this.initialDay});

  final DateTime initialDay;

  @override
  State<_AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<_AddReminderDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New reminder'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Shift briefing',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _pickTime,
                  child: Text(_time.format(context)),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final scheduled = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
      _time.hour,
      _time.minute,
    );
    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      scheduledFor: scheduled,
    );
    Navigator.of(context).pop(reminder);
  }
}

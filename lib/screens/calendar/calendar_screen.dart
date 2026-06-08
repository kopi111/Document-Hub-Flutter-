import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/calendar/reminder.dart';
import '../../services/calendar/reminder_repository.dart';
import '../../theme/hub_style.dart';
import '../../widgets/hub/hub_gradient_header.dart';
import '../../widgets/hub/hub_section_heading.dart';
import '../../widgets/hub/hub_stat_banner.dart';

const Color _accentBlue = Color(0xFF2D6CDF);

const List<String> _monthNames = [
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

const List<HubTint> _eventTints = [
  HubTint.blue,
  HubTint.green,
  HubTint.orange,
  HubTint.purple,
  HubTint.teal,
  HubTint.red,
];

/// A stable colour tint for a reminder, derived from its identifier so each
/// event keeps a consistent accent without a category field in the model.
HubTint _tintFor(Reminder reminder) =>
    _eventTints[reminder.id.hashCode.abs() % _eventTints.length];

String _monthLabel(DateTime day) => '${_monthNames[day.month - 1]} ${day.year}';

String _dayLabel(DateTime day) => '${_monthNames[day.month - 1]} ${day.day}';

String _timeLabel(DateTime moment) {
  final rawHour = moment.hour % 12;
  final hour = rawHour == 0 ? 12 : rawHour;
  final minute = moment.minute.toString().padLeft(2, '0');
  final suffix = moment.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ReminderRepository _repository = InMemoryReminderRepository();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _upcomingKey = GlobalKey();

  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _countInMonth(DateTime month) {
    return _repository.daysWithReminders().where((day) {
      return day.year == month.year && day.month == month.month;
    }).fold(0, (total, day) => total + _repository.remindersOn(day).length);
  }

  List<Reminder> get _upcomingEvents {
    final now = DateTime.now();
    final events = <Reminder>[
      for (final day in _repository.daysWithReminders())
        ..._repository.remindersOn(day),
    ]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    return events
        .where((event) => !event.scheduledFor.isBefore(now))
        .toList(growable: false);
  }

  void _selectDay(DateTime day, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _focusedDay = focused;
    });
  }

  void _changeMonth(DateTime focused) {
    setState(() => _focusedDay = focused);
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

  void _scrollToUpcoming() {
    final target = _upcomingKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _manageReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder settings are coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HubStyle.pageBackground,
      body: Column(
        children: [
          HubGradientHeader(
            title: 'Calendar',
            showBack: true,
            actions: [
              HubHeaderIconButton(
                icon: Icons.add,
                tooltip: 'Add Event',
                onPressed: _showAddReminderDialog,
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final upcoming = _upcomingEvents;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: HubStatBanner(
            icon: Icons.event_available,
            count: _countInMonth(_focusedDay).toString(),
            label: 'Events This Month',
            caption: _monthLabel(_focusedDay),
            actionLabel: 'My Schedule',
            onAction: _scrollToUpcoming,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CalendarCard(
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            eventLoader: _repository.remindersOn,
            onDaySelected: _selectDay,
            onPageChanged: _changeMonth,
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          key: _upcomingKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const HubSectionHeading(title: 'Upcoming Events'),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const _EmptyUpcoming()
        else
          ...upcoming.map(
            (event) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _EventCard(
                event: event,
                onDelete: () => _deleteReminder(event.id),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ReminderBanner(onManage: _manageReminders),
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventLoader,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<Reminder> Function(DateTime) eventLoader;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: TableCalendar<Reminder>(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: eventLoader,
        startingDayOfWeek: StartingDayOfWeek.monday,
        availableGestures: AvailableGestures.horizontalSwipe,
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: HubStyle.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: HubStyle.textSecondary),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: HubStyle.textSecondary),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: HubStyle.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: HubStyle.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: const TextStyle(color: HubStyle.textPrimary),
          weekendTextStyle: const TextStyle(color: HubStyle.textPrimary),
          todayDecoration: BoxDecoration(
            color: _accentBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: _accentBlue,
            fontWeight: FontWeight.w700,
          ),
          selectedDecoration: const BoxDecoration(
            color: _accentBlue,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: HubStyle.onGradient,
            fontWeight: FontWeight.w700,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF3FB95A),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 6,
          markerMargin: const EdgeInsets.only(top: 1),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onDelete});

  final Reminder event;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tint = _tintFor(event);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tint.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_note, color: tint.foreground, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HubStyle.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: HubStyle.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: HubStyle.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _dayLabel(event.scheduledFor),
                  style: const TextStyle(
                    color: HubStyle.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeLabel(event.scheduledFor),
                  style: const TextStyle(
                    color: _accentBlue,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: HubStyle.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Center(
        child: Text(
          'No upcoming events. Tap + to add one.',
          style: TextStyle(color: HubStyle.textSecondary),
        ),
      ),
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    const tint = HubTint.orange;
    return Container(
      decoration: BoxDecoration(
        color: HubStyle.cardSurface,
        borderRadius: BorderRadius.circular(HubStyle.cardRadius),
        boxShadow: HubStyle.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.notifications_active_outlined,
                color: tint.foreground, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Never Miss an Event',
                  style: TextStyle(
                    color: HubStyle.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Stay on top of your schedule with reminders.',
                  style: TextStyle(
                    color: HubStyle.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onManage,
            style: TextButton.styleFrom(foregroundColor: _accentBlue),
            child: const Text(
              'Manage',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
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
      title: const Text('New event'),
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
    final description = _descriptionController.text.trim();
    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      description: description.isEmpty ? null : description,
      scheduledFor: scheduled,
    );
    Navigator.of(context).pop(reminder);
  }
}

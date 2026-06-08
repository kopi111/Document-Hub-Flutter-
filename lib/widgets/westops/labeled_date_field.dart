import 'package:flutter/material.dart';

/// Tappable, read-only field that opens a date picker and shows the chosen date.
///
/// Shared by the West-Ops "add" forms so date entry looks and behaves the same
/// across missing-person, wanted-person, and stolen-vehicle reports.
class LabeledDateField extends StatelessWidget {
  const LabeledDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? now,
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? now,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final value = date;
    return InkWell(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(value == null ? 'Select date' : _formatDate(value)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

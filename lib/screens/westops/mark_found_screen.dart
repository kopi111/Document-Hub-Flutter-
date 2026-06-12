import 'package:flutter/material.dart';

import '../../models/westops/missing_person.dart';
import '../../theme/nam_style.dart';

/// Details an officer records when a missing person is located.
class MarkFoundResult {
  const MarkFoundResult({
    required this.foundDate,
    required this.foundLocation,
    required this.foundBy,
    this.foundNotes,
  });

  final DateTime foundDate;
  final String foundLocation;
  final String foundBy;
  final String? foundNotes;
}

/// Form an officer completes to resolve a missing-person case.
class MarkFoundScreen extends StatefulWidget {
  const MarkFoundScreen({super.key, required this.person});

  final MissingPerson person;

  @override
  State<MarkFoundScreen> createState() => _MarkFoundScreenState();
}

class _MarkFoundScreenState extends State<MarkFoundScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _officerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _foundDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _officerController.text = widget.person.investigatingOfficer ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _officerController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFoundDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _foundDate,
      firstDate: widget.person.reportedDate,
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _foundDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      MarkFoundResult(
        foundDate: _foundDate,
        foundLocation: _locationController.text.trim(),
        foundBy: _officerController.text.trim(),
        foundNotes: notes.isEmpty ? null : notes,
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mark Found · ${widget.person.fullName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FoundDatePicker(date: _foundDate, onTap: _pickFoundDate),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location found',
                hintText: 'Where the person was located',
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _officerController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Recovered by',
                hintText: 'Officer name and number',
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Condition, circumstances, follow-up',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Found'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoundDatePicker extends StatelessWidget {
  const _FoundDatePicker({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date found',
          suffixIcon: Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(_formatDate(date)),
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

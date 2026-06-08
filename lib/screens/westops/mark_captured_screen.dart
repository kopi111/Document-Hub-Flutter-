import 'package:flutter/material.dart';

import '../../models/westops/wanted_person.dart';
import '../../theme/nam_style.dart';

/// Details an officer records when a wanted person is apprehended.
class MarkCapturedResult {
  const MarkCapturedResult({
    required this.capturedDate,
    required this.capturedLocation,
    required this.capturedBy,
    this.captureNotes,
  });

  final DateTime capturedDate;
  final String capturedLocation;
  final String capturedBy;
  final String? captureNotes;
}

/// Form an officer completes to resolve a wanted-person case as captured.
class MarkCapturedScreen extends StatefulWidget {
  const MarkCapturedScreen({super.key, required this.person});

  final WantedPerson person;

  @override
  State<MarkCapturedScreen> createState() => _MarkCapturedScreenState();
}

class _MarkCapturedScreenState extends State<MarkCapturedScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _officerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _capturedDate = DateTime.now();

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

  Future<void> _pickCapturedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _capturedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _capturedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      MarkCapturedResult(
        capturedDate: _capturedDate,
        capturedLocation: _locationController.text.trim(),
        capturedBy: _officerController.text.trim(),
        captureNotes: notes.isEmpty ? null : notes,
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
      appBar: AppBar(title: Text('Mark Captured · ${widget.person.fullName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CapturedDatePicker(date: _capturedDate, onTap: _pickCapturedDate),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location captured',
                hintText: 'Where the person was apprehended',
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _officerController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Captured by',
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
                hintText: 'Circumstances, charges, custody location',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Confirm Captured'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedDatePicker extends StatelessWidget {
  const _CapturedDatePicker({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date captured',
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

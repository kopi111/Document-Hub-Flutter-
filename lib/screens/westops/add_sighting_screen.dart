import 'package:flutter/material.dart';

import '../../models/westops/sighting.dart';
import '../../theme/nam_style.dart';
import '../../widgets/westops/labeled_date_field.dart';

/// Form any officer completes to log a fresh sighting. Pops a [Sighting] on
/// submit, or null if cancelled.
class AddSightingScreen extends StatefulWidget {
  const AddSightingScreen({super.key, required this.personName});

  final String personName;

  @override
  State<AddSightingScreen> createState() => _AddSightingScreenState();
}

class _AddSightingScreenState extends State<AddSightingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _officer = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  DateTime _seenAt = DateTime.now();

  @override
  void dispose() {
    _location.dispose();
    _officer.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      Sighting(
        location: _location.text.trim(),
        seenAt: _seenAt,
        addedBy: _officer.text.trim(),
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: AppBar(title: Text('Add Sighting · ${widget.personName}')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Location seen',
                  hintText: 'Where the person was sighted',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              LabeledDateField(
                label: 'Date seen',
                date: _seenAt,
                onChanged: (value) => setState(() => _seenAt = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officer,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Logged by',
                  hintText: 'Officer name and number',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Appearance, direction of travel, company',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Log Sighting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

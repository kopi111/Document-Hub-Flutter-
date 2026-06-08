import 'package:flutter/material.dart';

import '../../models/notifications/app_notification.dart';
import '../../models/westops/missing_person.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/westops/labeled_date_field.dart';

/// Form an officer completes to file a new missing-person report.
class AddMissingPersonScreen extends StatefulWidget {
  const AddMissingPersonScreen({super.key, required this.repository});

  final MissingPersonsRepository repository;

  @override
  State<AddMissingPersonScreen> createState() => _AddMissingPersonScreenState();
}

class _AddMissingPersonScreenState extends State<AddMissingPersonScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _occupation = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _lastSeen = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _contactPerson = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _officer = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _complexion = TextEditingController();
  final TextEditingController _tattoos = TextEditingController();
  final TextEditingController _physicalAbilities = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;
  DateTime _reportedDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _age.dispose();
    _occupation.dispose();
    _address.dispose();
    _lastSeen.dispose();
    _description.dispose();
    _contactPerson.dispose();
    _contactPhone.dispose();
    _officer.dispose();
    _height.dispose();
    _weight.dispose();
    _complexion.dispose();
    _tattoos.dispose();
    _physicalAbilities.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Required' : null;

  String? _trimToNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth is required')),
      );
      return;
    }
    setState(() => _saving = true);
    final person = MissingPerson(
      id: 'MP-${DateTime.now().millisecondsSinceEpoch}',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      reportedDate: _reportedDate,
      gender: _gender,
      age: int.tryParse(_age.text.trim()),
      dateOfBirth: _dateOfBirth,
      occupation: _trimToNull(_occupation),
      address: _trimToNull(_address),
      lastSeenLocation: _trimToNull(_lastSeen),
      description: _trimToNull(_description),
      height: _trimToNull(_height),
      weight: _trimToNull(_weight),
      complexion: _trimToNull(_complexion),
      tattoos: _trimToNull(_tattoos),
      physicalAbilities: _trimToNull(_physicalAbilities),
      contactPerson: _trimToNull(_contactPerson),
      contactPhoneNumber: _trimToNull(_contactPhone),
      investigatingOfficer: _trimToNull(_officer),
      status: MissingPerson.statusMissing,
    );
    try {
      await widget.repository.create(person);
      AppNotificationsStore.instance.recordEvent(
        kind: NotificationKind.missing,
        title: 'New missing person reported',
        body: person.fullName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Report Missing Person')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _firstName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              LabeledDateField(
                label: 'Date of birth',
                date: _dateOfBirth,
                onChanged: (value) => setState(() => _dateOfBirth = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _occupation,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Occupation'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: _required,
              ),
              const SizedBox(height: 16),
              LabeledDateField(
                label: 'Reported date',
                date: _reportedDate,
                onChanged: (value) => setState(() => _reportedDate = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastSeen,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Last seen location',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _height,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Height (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weight,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Weight (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complexion,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Complexion (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tattoos,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tattoos (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _physicalAbilities,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Physical abilities (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPerson,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Contact person',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact phone (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officer,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Investigating officer',
                ),
                validator: _required,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

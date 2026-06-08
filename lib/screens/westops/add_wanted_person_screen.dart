import 'package:flutter/material.dart';

import '../../models/notifications/app_notification.dart';
import '../../models/westops/wanted_person.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/westops/labeled_date_field.dart';

/// Form an officer completes to add a new wanted-person record.
class AddWantedPersonScreen extends StatefulWidget {
  const AddWantedPersonScreen({super.key, required this.repository});

  final WantedPersonsRepository repository;

  @override
  State<AddWantedPersonScreen> createState() => _AddWantedPersonScreenState();
}

class _AddWantedPersonScreenState extends State<AddWantedPersonScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _alias = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _occupation = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _placesFrequented = TextEditingController();
  final TextEditingController _crime = TextEditingController();
  final TextEditingController _reward = TextEditingController();
  final TextEditingController _contactPhone = TextEditingController();
  final TextEditingController _officer = TextEditingController();
  final TextEditingController _station = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _alias.dispose();
    _age.dispose();
    _occupation.dispose();
    _address.dispose();
    _placesFrequented.dispose();
    _crime.dispose();
    _reward.dispose();
    _contactPhone.dispose();
    _officer.dispose();
    _station.dispose();
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
    setState(() => _saving = true);
    final person = WantedPerson(
      id: 'WP-${DateTime.now().millisecondsSinceEpoch}',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      alias: _trimToNull(_alias),
      gender: _gender,
      age: int.tryParse(_age.text.trim()),
      dateOfBirth: _dateOfBirth,
      occupation: _trimToNull(_occupation),
      address: _trimToNull(_address),
      placesFrequented: _trimToNull(_placesFrequented),
      crimeDescription: _trimToNull(_crime),
      rewardAmount: double.tryParse(_reward.text.trim()),
      investigatingOfficerPhone: _trimToNull(_contactPhone),
      investigatingOfficer: _trimToNull(_officer),
      stationName: _trimToNull(_station),
      status: 'Wanted',
    );
    try {
      await widget.repository.create(person);
      AppNotificationsStore.instance.recordEvent(
        kind: NotificationKind.wanted,
        title: 'New wanted person filed',
        body: person.fullName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save record: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NamStyle.theme(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Wanted Person')),
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
              TextFormField(
                controller: _alias,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Alias (optional)'),
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
                decoration: const InputDecoration(labelText: 'Age (optional)'),
              ),
              const SizedBox(height: 16),
              LabeledDateField(
                label: 'Date of birth (optional)',
                date: _dateOfBirth,
                onChanged: (value) => setState(() => _dateOfBirth = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _occupation,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Occupation (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placesFrequented,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Places frequented (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _crime,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Offence / crime description',
                  alignLabelWithHint: true,
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reward,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reward amount (optional)',
                  prefixText: r'$ ',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Investigating officer contact number (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _officer,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Investigating officer (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _station,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Station (optional)',
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/notifications/app_notification.dart';
import '../../models/westops/stolen_vehicle.dart';
import '../../services/notifications/app_notifications_store.dart';
import '../../services/westops/stolen_vehicles_repository.dart';
import '../../theme/nam_style.dart';
import '../../widgets/westops/labeled_date_field.dart';

/// Form an officer completes to file a new stolen-vehicle report.
class AddStolenVehicleScreen extends StatefulWidget {
  const AddStolenVehicleScreen({super.key, required this.repository});

  final StolenVehiclesRepository repository;

  @override
  State<AddStolenVehicleScreen> createState() => _AddStolenVehicleScreenState();
}

class _AddStolenVehicleScreenState extends State<AddStolenVehicleScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _make = TextEditingController();
  final TextEditingController _model = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _plate = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _lastKnown = TextEditingController();
  final TextEditingController _ownerName = TextEditingController();
  final TextEditingController _ownerContact = TextEditingController();
  final TextEditingController _reward = TextEditingController();
  final TextEditingController _officer = TextEditingController();
  final TextEditingController _officerPhone = TextEditingController();
  final TextEditingController _supervisor = TextEditingController();

  DateTime _dateStolen = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _plate.dispose();
    _description.dispose();
    _lastKnown.dispose();
    _ownerName.dispose();
    _ownerContact.dispose();
    _reward.dispose();
    _officer.dispose();
    _officerPhone.dispose();
    _supervisor.dispose();
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
    final vehicle = StolenVehicle(
      id: 'SV-${DateTime.now().millisecondsSinceEpoch}',
      make: _make.text.trim(),
      model: _model.text.trim(),
      dateStolen: _dateStolen,
      year: int.tryParse(_year.text.trim()),
      color: _trimToNull(_color),
      licensePlate: _trimToNull(_plate),
      description: _trimToNull(_description),
      lastKnownLocation: _trimToNull(_lastKnown),
      ownerName: _trimToNull(_ownerName),
      ownerContact: _trimToNull(_ownerContact),
      rewardAmount: double.tryParse(_reward.text.trim()),
      investigatingOfficer: _trimToNull(_officer),
      investigatingOfficerPhone: _trimToNull(_officerPhone),
      investigatingOfficerSupervisor: _trimToNull(_supervisor),
      status: 'Stolen',
    );
    try {
      await widget.repository.create(vehicle);
      AppNotificationsStore.instance.recordEvent(
        kind: NotificationKind.stolen,
        title: 'New stolen vehicle reported',
        body: vehicle.displayName,
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
      child: _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Stolen Vehicle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _make,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Make'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _model,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Model'),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _color,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Colour (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plate,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'License plate (optional)',
              ),
            ),
            const SizedBox(height: 16),
            LabeledDateField(
              label: 'Date stolen',
              date: _dateStolen,
              onChanged: (value) => setState(() => _dateStolen = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastKnown,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Last known location (optional)',
              ),
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
              controller: _ownerName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Owner name (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerContact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Owner contact (optional)',
              ),
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
              controller: _officer,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Investigating officer (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _officerPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Officer contact number (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _supervisor,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Supervisor (optional)',
              ),
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
    );
  }
}

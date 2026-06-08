import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/westops/missing_person.dart';
import '../../models/westops/sighting.dart';
import '../../services/phone_dialer.dart';
import '../../services/westops/missing_persons_repository.dart';
import '../../widgets/westops/regulation_delete_dialog.dart';
import '../../widgets/westops/wanted_widgets.dart';
import 'add_sighting_screen.dart';
import 'mark_found_screen.dart';
import 'wanted_style.dart';

class MissingDetailScreen extends StatefulWidget {
  const MissingDetailScreen({
    super.key,
    required this.person,
    this.repository,
  });

  final MissingPerson person;
  final MissingPersonsRepository? repository;

  @override
  State<MissingDetailScreen> createState() => _MissingDetailScreenState();
}

class _MissingDetailScreenState extends State<MissingDetailScreen> {
  late final MissingPersonsRepository _repository =
      widget.repository ?? const InMemoryMissingPersonsRepository();
  late MissingPerson _person = widget.person;

  Future<void> _addSighting() async {
    final sighting = await Navigator.push<Sighting>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSightingScreen(personName: _person.fullName),
      ),
    );
    if (sighting == null) return;
    final updated = await _repository.addSighting(_person.id, sighting);
    if (!mounted) return;
    setState(() => _person = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tip logged to the sightings trail')),
    );
  }

  Future<void> _markFound() async {
    final result = await Navigator.push<MarkFoundResult>(
      context,
      MaterialPageRoute(builder: (_) => MarkFoundScreen(person: _person)),
    );
    if (result == null) return;
    final updated = await _repository.markFound(
      id: _person.id,
      foundDate: result.foundDate,
      foundLocation: result.foundLocation,
      foundBy: result.foundBy,
      foundNotes: result.foundNotes,
    );
    if (!mounted) return;
    setState(() => _person = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_person.fullName} marked as found')),
    );
  }

  Future<void> _call() async {
    final number = _person.contactPhoneNumber ?? _person.stationContactNumber;
    final messenger = ScaffoldMessenger.of(context);
    if (number == null || number.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No contact number on file')));
      return;
    }
    try {
      await dialNumber(number);
    } on DialFailure catch (failure) {
      messenger.showSnackBar(SnackBar(content: Text('$failure')));
    }
  }

  void _share() {
    Clipboard.setData(ClipboardData(text: _bulletinText(_person)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing-person bulletin copied to clipboard')),
    );
  }

  Future<void> _confirmDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final regulation = await confirmDeletionWithRegulation(
      context,
      itemLabel: _person.fullName,
    );
    if (regulation == null) return;
    await _repository.delete(_person.id);
    navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(content: Text('Record deleted · confirmed by reg #$regulation')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final person = _person;
    return Theme(
      data: WantedStyle.theme(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const JcfCrest(size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(person.fullName,
                    style: WantedStyle.title(
                        size: 17, weight: FontWeight.w800, color: WantedStyle.navy),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Delete record',
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline, color: WantedStyle.red),
            ),
          ],
        ),
        floatingActionButton: person.isFound
            ? null
            : FloatingActionButton.extended(
                onPressed: _markFound,
                backgroundColor: WantedStyle.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.check_circle_outline),
                label: Text('Mark Found',
                    style: WantedStyle.title(
                        size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _PhotoHeader(person: person),
            _Identity(person: person),
            FbiActionBar(
              onShare: _share,
              onTip: _addSighting,
              onCall: _call,
              callLabel: 'Call Contact',
            ),
            FbiFieldsCard(rows: _buildRows(person)),
            FbiSightingsCard(sightings: person.sightings, onAdd: _addSighting),
          ],
        ),
      ),
    );
  }

  List<FbiField> _buildRows(MissingPerson person) {
    final rows = <FbiField>[];
    void add(String label, String? value, {bool callable = false}) {
      if (value != null && value.isNotEmpty) {
        rows.add(FbiField(label: label, value: value, callable: callable));
      }
    }

    add('Gender', person.gender);
    add('Age', person.age?.toString());
    add('Date of birth', _formatDate(person.dateOfBirth));
    add('Occupation', person.occupation);
    add('Address', person.address);
    add('Reported', _formatDate(person.reportedDate));
    add('Last seen', person.lastSeenLocation);
    add('Description', person.description);
    add('Height', person.height);
    add('Weight', person.weight);
    add('Complexion', person.complexion);
    add('Tattoos', person.tattoos);
    add('Physical abilities', person.physicalAbilities);
    add('Contact person', person.contactPerson);
    add('Contact phone', person.contactPhoneNumber, callable: true);
    add('Investigating officer', person.investigatingOfficer);
    add('Supervisor', person.investigatingOfficerSupervisor);
    add('Station', person.stationName);
    add('Station number', person.stationNumber);
    add('Station phone', person.stationContactNumber, callable: true);
    add('Status', person.status);
    add('Reference ID', person.id);
    if (person.isFound) {
      add('Found on', _formatDate(person.foundDate));
      add('Found location', person.foundLocation);
      add('Recovered by', person.foundBy);
      add('Found notes', person.foundNotes);
    }
    return rows;
  }

  String _bulletinText(MissingPerson person) {
    final buffer = StringBuffer()
      ..writeln('JCF MISSING PERSON')
      ..writeln(person.fullName)
      ..writeln('Case ${person.id}');
    if (person.age != null) buffer.writeln('Age: ${person.age}');
    if (person.lastSeenLocation != null) {
      buffer.writeln('Last seen: ${person.lastSeenLocation}');
    }
    final phone = person.contactPhoneNumber ?? person.stationContactNumber;
    if (phone != null) buffer.writeln('Tips: $phone');
    return buffer.toString();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.person});

  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.of(context).size.width - WantedStyle.pageInset * 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 16, WantedStyle.pageInset, 0),
      child: Hero(
        tag: 'missing:${person.id}',
        child: WantedPhoto(
          initials: _initials(person),
          photoUrl: person.photoUrl,
          photoBytes: person.photoBytes,
          size: side.clamp(0, 360),
          radius: 18,
        ),
      ),
    );
  }

  String _initials(MissingPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.person});

  final MissingPerson person;

  @override
  Widget build(BuildContext context) {
    final isMinor = (person.age ?? 99) < 18;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (person.isFound)
                const StatusPill(label: 'Found', color: WantedStyle.green)
              else
                const CrimeTag(label: 'Missing'),
              if (isMinor) ...[
                const SizedBox(width: 8),
                const CrimeTag(label: 'Minor', color: WantedStyle.gold),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(person.fullName,
              style: WantedStyle.title(
                  size: 24, weight: FontWeight.w800, color: WantedStyle.textPrimary)),
          if (person.lastSeenLocation != null &&
              person.lastSeenLocation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Last seen at ${person.lastSeenLocation}',
                style: WantedStyle.body(size: 14)),
          ],
        ],
      ),
    );
  }
}

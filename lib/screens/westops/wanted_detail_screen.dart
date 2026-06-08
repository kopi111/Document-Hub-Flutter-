import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/westops/sighting.dart';
import '../../models/westops/wanted_person.dart';
import '../../services/phone_dialer.dart';
import '../../services/westops/wanted_persons_repository.dart';
import '../../widgets/westops/regulation_delete_dialog.dart';
import '../../widgets/westops/wanted_widgets.dart';
import 'add_sighting_screen.dart';
import 'mark_captured_screen.dart';
import 'wanted_style.dart';

class WantedDetailScreen extends StatefulWidget {
  const WantedDetailScreen({
    super.key,
    required this.person,
    this.repository,
  });

  final WantedPerson person;
  final WantedPersonsRepository? repository;

  @override
  State<WantedDetailScreen> createState() => _WantedDetailScreenState();
}

class _WantedDetailScreenState extends State<WantedDetailScreen> {
  late final WantedPersonsRepository _repository =
      widget.repository ?? const InMemoryWantedPersonsRepository();
  late WantedPerson _person = widget.person;

  Future<void> _markCaptured() async {
    final result = await Navigator.push<MarkCapturedResult>(
      context,
      MaterialPageRoute(builder: (_) => MarkCapturedScreen(person: _person)),
    );
    if (result == null) return;
    final updated = await _repository.markCaptured(
      id: _person.id,
      capturedDate: result.capturedDate,
      capturedLocation: result.capturedLocation,
      capturedBy: result.capturedBy,
      captureNotes: result.captureNotes,
    );
    if (!mounted) return;
    setState(() => _person = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_person.fullName} marked as captured')),
    );
  }

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

  Future<void> _call() async {
    final number = _person.investigatingOfficerPhone ?? _person.stationContactNumber;
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
      const SnackBar(content: Text('Wanted bulletin copied to clipboard')),
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
        floatingActionButton: person.isCaptured
            ? null
            : FloatingActionButton.extended(
                onPressed: _markCaptured,
                backgroundColor: WantedStyle.green,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.gavel_outlined),
                label: Text('Mark Captured',
                    style: WantedStyle.title(
                        size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _PhotoHeader(person: person),
            _Identity(person: person),
            if (person.rewardAmount != null) _RewardBanner(amount: person.rewardAmount!),
            FbiActionBar(onShare: _share, onTip: _addSighting, onCall: _call),
            FbiFieldsCard(rows: _buildRows(person)),
            FbiSightingsCard(sightings: person.sightings, onAdd: _addSighting),
          ],
        ),
      ),
    );
  }

  List<FbiField> _buildRows(WantedPerson person) {
    final rows = <FbiField>[];
    void add(String label, String? value, {bool callable = false}) {
      if (value != null && value.isNotEmpty) {
        rows.add(FbiField(label: label, value: value, callable: callable));
      }
    }

    add('Alias', person.alias);
    add('Gender', person.gender);
    add('Age', person.age?.toString());
    add('Date of birth', _formatDate(person.dateOfBirth));
    add('Occupation', person.occupation);
    add('Address', person.address);
    add('Places frequented', person.placesFrequented);
    add('Offence', person.crimeDescription);
    add('Investigating officer', person.investigatingOfficer);
    add('Officer contact', person.investigatingOfficerPhone, callable: true);
    add('Supervisor', person.investigatingOfficerSupervisor);
    add('Station', person.stationName);
    add('Station number', person.stationNumber);
    add('Station phone', person.stationContactNumber, callable: true);
    add('Status', person.status);
    add('Reference ID', person.id);
    if (person.isCaptured) {
      add('Captured on', _formatDate(person.capturedDate));
      add('Captured location', person.capturedLocation);
      add('Captured by', person.capturedBy);
      add('Capture notes', person.captureNotes);
    }
    return rows;
  }

  String _bulletinText(WantedPerson person) {
    final buffer = StringBuffer()
      ..writeln('JCF WANTED BULLETIN')
      ..writeln(person.displayName)
      ..writeln('Case ${person.id}');
    if (person.crimeDescription != null) {
      buffer.writeln('Offence: ${person.crimeDescription}');
    }
    if (person.rewardAmount != null) {
      buffer.writeln('Reward: JMD \$${person.rewardAmount!.toStringAsFixed(0)}');
    }
    final phone = person.investigatingOfficerPhone ?? person.stationContactNumber;
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

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    final side = MediaQuery.of(context).size.width - WantedStyle.pageInset * 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 16, WantedStyle.pageInset, 0),
      child: Hero(
        tag: 'wanted:${person.id}',
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

  String _initials(WantedPerson person) {
    final first = person.firstName.isNotEmpty ? person.firstName[0] : '?';
    final last = person.lastName.isNotEmpty ? person.lastName[0] : '';
    return '$first$last';
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.person});

  final WantedPerson person;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CrimeTag(label: _primaryOffence(person)),
              const SizedBox(width: 8),
              if (person.isCaptured)
                Text('CAPTURED',
                    style: WantedStyle.label(size: 11, color: WantedStyle.green)),
            ],
          ),
          const SizedBox(height: 10),
          Text(person.fullName,
              style: WantedStyle.title(
                  size: 24, weight: FontWeight.w800, color: WantedStyle.textPrimary)),
          if (person.alias != null && person.alias!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text('a.k.a. "${person.alias}"', style: WantedStyle.body(size: 14)),
          ],
        ],
      ),
    );
  }

  String _primaryOffence(WantedPerson person) {
    final crime = person.crimeDescription;
    if (crime == null || crime.isEmpty) return 'Wanted';
    final firstClause = crime.split(RegExp(r'[—\-,(]')).first.trim();
    return firstClause.isEmpty ? 'Wanted' : firstClause;
  }
}

class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          WantedStyle.pageInset, 14, WantedStyle.pageInset, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: WantedStyle.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(WantedStyle.cardRadius),
        border: Border.all(color: WantedStyle.gold),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_outlined,
              size: 24, color: Color(0xFF9A7200)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REWARD FOR INFORMATION',
                  style: WantedStyle.label(size: 10, color: Color(0xFF9A7200))),
              const SizedBox(height: 2),
              Text('JMD \$${amount.toStringAsFixed(0)}',
                  style: WantedStyle.title(
                      size: 22, weight: FontWeight.w800, color: Color(0xFF8A6600))),
            ],
          ),
        ],
      ),
    );
  }
}

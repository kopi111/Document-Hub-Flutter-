import 'package:flutter/material.dart';

import '../../theme/jcf_palette.dart';

/// Confirms a destructive delete by requiring the acting officer to enter their
/// regulation number. Returns the entered regulation number when confirmed, or
/// `null` if the officer cancels.
Future<String?> confirmDeletionWithRegulation(
  BuildContext context, {
  required String itemLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RegulationDeleteDialog(itemLabel: itemLabel),
  );
}

class _RegulationDeleteDialog extends StatefulWidget {
  const _RegulationDeleteDialog({required this.itemLabel});

  final String itemLabel;

  @override
  State<_RegulationDeleteDialog> createState() =>
      _RegulationDeleteDialogState();
}

class _RegulationDeleteDialogState extends State<_RegulationDeleteDialog> {
  final TextEditingController _regulation = TextEditingController();

  static const int _minLength = 3;

  @override
  void dispose() {
    _regulation.dispose();
    super.dispose();
  }

  bool get _canDelete => _regulation.text.trim().length >= _minLength;

  void _confirm() {
    if (!_canDelete) return;
    Navigator.of(context).pop(_regulation.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Delete ${widget.itemLabel}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently removes the record. Enter your regulation '
            'number to confirm the deletion.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regulation,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirm(),
            decoration: const InputDecoration(
              labelText: 'Regulation number',
              hintText: 'e.g. 09745',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canDelete ? _confirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: JcfPalette.danger,
            foregroundColor: JcfPalette.onDanger,
          ),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

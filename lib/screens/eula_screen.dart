import 'package:flutter/material.dart';

class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _termsConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('End User Licence Agreement'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: SingleChildScrollView(child: EulaBody()),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _termsConfirmed,
                onChanged: (value) => setState(() => _termsConfirmed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('I have read and accept these terms.'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _termsConfirmed ? widget.onAccepted : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EulaViewScreen extends StatelessWidget {
  const EulaViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('End User Licence Agreement')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: EulaBody(),
        ),
      ),
    );
  }
}

class EulaBody extends StatelessWidget {
  const EulaBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('JCF Document Hub EULA', style: textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Version 2.0 · 13 May 2026',
          style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        const Text(
          'By using this application you agree to the following terms. Please read '
          'them carefully before continuing.',
        ),
        const SizedBox(height: 16),
        const _Clause(
          text: 'This application is provided by the Jamaica Constabulary Force for '
              'official use only.',
        ),
        const _Clause(
          text: 'Document content accessed via this application is classified and '
              'must not be reproduced, photographed, or shared outside of authorised '
              'JCF channels.',
        ),
        const _Clause(
          text: 'You consent to audit logging of your document access activity, as '
              'described in the Privacy Notice and Section 6.5 of the JCF Document '
              'Hub Proposal (v2.0).',
        ),
        const _Clause(
          text: 'The Force reserves the right to remotely wipe application data '
              'from your device.',
        ),
        const _Clause(
          text: 'Violation of these terms may constitute a disciplinary or criminal '
              'offence.',
        ),
      ],
    );
  }
}

class _Clause extends StatelessWidget {
  const _Clause({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 6, color: colors.primary),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

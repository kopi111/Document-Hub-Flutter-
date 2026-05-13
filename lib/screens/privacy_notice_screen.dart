import 'package:flutter/material.dart';

class PrivacyNoticeScreen extends StatelessWidget {
  const PrivacyNoticeScreen({super.key, required this.onAcknowledged});

  final VoidCallback onAcknowledged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Notice'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('JCF Document Hub — Privacy Notice', style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Version 2.0 · Effective 13 May 2026 · Issued by JCF ICTD',
                        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'What this application does'),
                      const Text(
                        'The JCF Document Hub provides serving officers with secure access to Force '
                        'policies, Force Orders, and Standard Operating Procedures on their personal '
                        'smartphones. It is operated by the Jamaica Constabulary Force, Information '
                        'and Communications Technology Division.',
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'Data we collect and why'),
                      const _DataItem(
                        what: 'Your @jcf.gov.jm email address',
                        why: 'To identify you and control your access to authorised documents.',
                        where: 'On your device during the session only. In server-side audit logs for 2 years.',
                      ),
                      const _DataItem(
                        what: 'Authentication tokens (issued by Microsoft 365)',
                        why: 'To verify your identity on each request to our servers.',
                        where: 'On your device in Android Keystore-protected storage. Deleted on logout.',
                      ),
                      const _DataItem(
                        what: 'Records of which documents you open or download',
                        why: 'For security monitoring and compliance with JCF data governance requirements.',
                        where: 'On our servers only. Not on your device. Retained for 2 years.',
                      ),
                      const _DataItem(
                        what: 'Crash reports (if a crash occurs)',
                        why: 'To identify and fix application defects.',
                        where: 'On Google Firebase servers for 90 days. No personal information is included.',
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'Data we do not collect'),
                      const Text(
                        'We do not collect your GPS location, contacts, call logs, SMS messages, '
                        'photos, biometric data, browsing history, or any other data from your device.',
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'Your rights'),
                      const Text(
                        'Under the Data Protection Act 2020 (Jamaica) you have the right to access '
                        'the personal data we hold about you and to request correction of inaccurate '
                        'data. To exercise these rights, contact the JCF Data Protection Officer at '
                        'dpo@jcf.gov.jm.',
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'Remote wipe'),
                      const Text(
                        'By installing and using this application, you acknowledge that the Jamaica '
                        'Constabulary Force may remotely delete application data (documents and '
                        'tokens) from your device in the event of loss, theft, or separation from '
                        'the Force. This action does not affect your personal data outside the '
                        'application.',
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(label: 'Contact'),
                      const Text(
                        'ICTD Help Desk: ictd@jcf.gov.jm\n'
                        'JCF Data Protection Officer: dpo@jcf.gov.jm',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAcknowledged,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('I have read this notice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: textTheme.titleMedium),
    );
  }
}

class _DataItem extends StatelessWidget {
  const _DataItem({required this.what, required this.why, required this.where});

  final String what;
  final String why;
  final String where;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(what, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(why, style: textTheme.bodySmall),
          Text(where, style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

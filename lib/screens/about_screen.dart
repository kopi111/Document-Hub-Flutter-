import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'eula_screen.dart';
import 'privacy_notice_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _proposalVersion = '2.0';
  static const _proposalDate = '13 May 2026';
  static const _helpDeskEmail = 'ictd@jcf.gov.jm';
  static const _dataProtectionEmail = 'dpo@jcf.gov.jm';
  static const _legalese =
      'Issued by the Jamaica Constabulary Force, Information and Communications '
      'Technology Division. Confidential — for JCF internal use only.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const _AppHeader(),
            const SizedBox(height: 8),
            const _SectionHeading(label: 'Proposal'),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Proposal for Adoption'),
              subtitle: const Text('Version $_proposalVersion · $_proposalDate'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showProposalReference(context),
            ),
            const Divider(),
            const _SectionHeading(label: 'Documents'),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy notice'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const PrivacyNoticeViewScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('End User Licence Agreement'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, const EulaViewScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Open-source licences'),
              subtitle: const Text('Third-party packages bundled with the application'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openLicensePage(context),
            ),
            const Divider(),
            const _SectionHeading(label: 'Contact'),
            const ListTile(
              leading: Icon(Icons.support_agent),
              title: Text('ICTD Help Desk'),
              subtitle: Text(_helpDeskEmail),
            ),
            const ListTile(
              leading: Icon(Icons.shield_outlined),
              title: Text('Data Protection Officer'),
              subtitle: Text(_dataProtectionEmail),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openLicensePage(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: 'JCF Duty',
      applicationVersion: 'Version ${info.version} (build ${info.buildNumber})',
      applicationLegalese: _legalese,
    );
  }

  void _showProposalReference(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Proposal for Adoption'),
        content: const Text(
          'JCF Document Hub — Proposal for Adoption, Version $_proposalVersion, '
          'issued $_proposalDate.\n\n'
          'Prepared by Sgt. Dwayne Aitken, Shevon Robinson and Nicholas Hunter for '
          'the JCF Information and Communications Technology Division.\n\n'
          'A copy of the proposal and the ICTD assessment is held in the project '
          'repository under docs/proposals/v2/ and docs/assessments/.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                ),
                child: Icon(Icons.shield, size: 40, color: colors.onPrimaryContainer),
              ),
              const SizedBox(height: 12),
              Text('JCF Duty', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                info == null
                    ? 'Version —'
                    : 'Version ${info.version} (build ${info.buildNumber})',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                'Jamaica Constabulary Force\nInformation and Communications Technology Division',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: colors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

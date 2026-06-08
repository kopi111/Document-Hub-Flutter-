import '../../models/email/email_message.dart';

abstract class EmailRepository {
  Future<List<EmailMessage>> inbox();
}

class InMemoryEmailRepository implements EmailRepository {
  const InMemoryEmailRepository();

  static final List<EmailMessage> _messages = [
    EmailMessage(
      id: 'EM-0001',
      sender: 'ICTD Help Desk',
      senderAddress: 'helpdesk@jcf.gov.jm',
      subject: 'Mandatory Password Change — Action Required by 6 June 2026',
      preview:
          'All JCF network accounts must rotate passwords before 6 June 2026 in compliance with IT Policy DP-04.',
      body:
          'Dear Officer,\n\n'
          'In accordance with JCF IT Policy DP-04 (Data Protection & Access Control), all officers are '
          'required to update their network account passwords before 6 June 2026.\n\n'
          'To change your password:\n'
          '1. Press Ctrl+Alt+Delete on any JCF workstation.\n'
          '2. Select "Change a password".\n'
          '3. Follow the on-screen prompts.\n\n'
          'Passwords must be at least 12 characters and must not be reused from the last five cycles.\n\n'
          'Failure to comply will result in account lock-out.\n\n'
          'ICTD Help Desk\n'
          'Internal ext. 4400',
      receivedAt: DateTime(2026, 5, 31, 8, 14),
      unread: true,
    ),
    EmailMessage(
      id: 'EM-0002',
      sender: 'Force Orders Unit',
      senderAddress: 'forceorders@jcf.gov.jm',
      subject: 'Force Order 12/2026 — Community Engagement Initiative',
      preview:
          'Force Order 12/2026 outlines the revised Community Engagement Policy effective 1 June 2026.',
      body:
          'FORCE ORDER 12/2026\n'
          'Subject: Revised Community Engagement Policy\n'
          'Effective Date: 1 June 2026\n\n'
          'By direction of the Commissioner of Police, all divisional commanders are to ensure compliance '
          'with the revised Community Engagement Policy attached hereto as Annex A.\n\n'
          'Key changes include:\n'
          '- Monthly community consultation meetings at each station.\n'
          '- Mandatory recording of all community liaison activities in the Station Diary.\n'
          '- Quarterly reporting to Crime Management Unit.\n\n'
          'Station Commanders are to acknowledge receipt and brief all ranks at the earliest opportunity.\n\n'
          'Force Orders Unit\n'
          'Jamaica Constabulary Force',
      receivedAt: DateTime(2026, 5, 30, 11, 45),
      unread: true,
    ),
    EmailMessage(
      id: 'EM-0003',
      sender: 'HR Directorate',
      senderAddress: 'hr@jcf.gov.jm',
      subject: 'June 2026 Roster Adjustments — Half-Way-Tree Division',
      preview:
          'Please review the updated June 2026 duty roster for Half-Way-Tree Division; changes effective 2 June 2026.',
      body:
          'Dear Officers,\n\n'
          'Please be advised that the June 2026 duty roster for Half-Way-Tree Division has been revised. '
          'Key adjustments are as follows:\n\n'
          '- Constable M. Brown (#19234) transferred to B Relief effective 2 June.\n'
          '- Sergeant G. Thompson (#08821) on approved leave 5–12 June.\n'
          '- Acting promotion: Corporal D. Reid (#14677) acting Sergeant during absence.\n\n'
          'The full updated roster is pinned to the noticeboard at the station and is available on the '
          'JCF Intranet under HR > Rosters.\n\n'
          'For queries contact the HR Directorate at hr@jcf.gov.jm or ext. 3301.\n\n'
          'HR Directorate\n'
          'Jamaica Constabulary Force',
      receivedAt: DateTime(2026, 5, 29, 9, 30),
      unread: true,
    ),
    EmailMessage(
      id: 'EM-0004',
      sender: 'Corporate Communications',
      senderAddress: 'comms@jcf.gov.jm',
      subject: 'ICTD Bulletin: New Document Hub App — Now Available',
      preview:
          'The JCF Document Hub mobile app is now live on the internal app distribution portal.',
      body:
          'Dear Members,\n\n'
          'The ICTD is pleased to announce the availability of the JCF Document Hub mobile application.\n\n'
          'The app provides officers with instant access to:\n'
          '- JCF Force Orders and Standing Orders\n'
          '- Divisional Notices and Circulars\n'
          '- Training Manuals and SOP Documents\n\n'
          'The app is available for download from the JCF internal app portal at apps.jcf.gov.jm. '
          'Use your JCF network credentials to authenticate.\n\n'
          'For technical support contact ICTD at helpdesk@jcf.gov.jm or ext. 4400.\n\n'
          'ICTD — Enabling Smarter Policing',
      receivedAt: DateTime(2026, 5, 28, 14, 5),
      unread: false,
    ),
    EmailMessage(
      id: 'EM-0005',
      sender: 'Legal Services Branch',
      senderAddress: 'legal@jcf.gov.jm',
      subject: 'Court Date — R v. Marcus Webb — Kingston & St Andrew Parish Court',
      preview:
          'You are required to attend Kingston & St Andrew Parish Court on 10 June 2026 re: R v. Marcus Webb.',
      body:
          'NOTICE TO GIVE EVIDENCE\n\n'
          'Officer: Sergeant D. Aitken #09451\n'
          'Case: R v. Marcus Webb — Case No. KSA/2026/1134\n'
          'Court: Kingston & St Andrew Parish Court\n'
          'Date: Wednesday, 10 June 2026\n'
          'Time: 10:00 a.m.\n'
          'Courtroom: No. 3\n\n'
          'Please report to the Witness Room no later than 09:30 a.m. Bring your occurrence book '
          'entry and any supporting documentation.\n\n'
          'Confirm attendance with this office at legal@jcf.gov.jm or ext. 5500 by 4 June 2026.\n\n'
          'Legal Services Branch\n'
          'Jamaica Constabulary Force',
      receivedAt: DateTime(2026, 5, 27, 10, 20),
      unread: false,
    ),
    EmailMessage(
      id: 'EM-0006',
      sender: 'Training Branch',
      senderAddress: 'training@jcf.gov.jm',
      subject: 'Upcoming Training: Use of Force & De-escalation — 15 June 2026',
      preview:
          'Mandatory Use of Force refresher training is scheduled for 15 June 2026 at the JCF Training Academy.',
      body:
          'Dear Officer,\n\n'
          'You have been nominated to attend the Use of Force & De-escalation refresher course:\n\n'
          'Date: Monday, 15 June 2026\n'
          'Time: 08:00 a.m. – 04:00 p.m.\n'
          'Venue: JCF Training Academy, Twickenham Park, St Catherine\n'
          'Attire: Service uniform\n\n'
          'This training is mandatory under Force Standing Order 7.4. Officers who miss this session '
          'will be rescheduled to the next available cohort.\n\n'
          'Please confirm attendance by 8 June 2026 by replying to this email.\n\n'
          'Training Branch\n'
          'Jamaica Constabulary Force',
      receivedAt: DateTime(2026, 5, 26, 8, 50),
      unread: false,
    ),
    EmailMessage(
      id: 'EM-0007',
      sender: 'Crime Management Unit',
      senderAddress: 'cmu@jcf.gov.jm',
      subject: 'Intelligence Advisory: Spike in Robberies — St Andrew North',
      preview:
          'CMU intelligence indicates an elevated risk of armed robberies in the Stony Hill corridor this weekend.',
      body:
          'INTELLIGENCE ADVISORY — RESTRICTED\n\n'
          'FROM: Crime Management Unit\n'
          'TO: All Station Commanders, St Andrew North Division\n'
          'DATE: 26 May 2026\n\n'
          'Reliable intelligence indicates a coordinated group is targeting small businesses in the '
          'Stony Hill / Constant Spring corridor between 10 p.m. and 2 a.m. this weekend '
          '(30–31 May 2026).\n\n'
          'Recommended actions:\n'
          '- Increase mobile patrols on Stony Hill Road and Red Hills Road.\n'
          '- Conduct stop-and-question operations at key junctions.\n'
          '- Liaise with community wardens for ground intelligence.\n\n'
          'Report any observations to CMU Operations Desk at ext. 6600 immediately.\n\n'
          'Crime Management Unit\n'
          'Jamaica Constabulary Force',
      receivedAt: DateTime(2026, 5, 25, 15, 35),
      unread: true,
    ),
    EmailMessage(
      id: 'EM-0008',
      sender: 'ICTD Help Desk',
      senderAddress: 'helpdesk@jcf.gov.jm',
      subject: 'Planned Network Maintenance — Sunday 1 June 2026 02:00–06:00',
      preview:
          'JCF internal systems will be unavailable Sunday 1 June 2026 from 02:00 to 06:00 a.m. for scheduled maintenance.',
      body:
          'Dear All,\n\n'
          'Please be advised that JCF internal network systems, including email, the intranet, '
          'and the CSTATS portal, will be unavailable on:\n\n'
          'Date: Sunday, 1 June 2026\n'
          'Window: 02:00 a.m. – 06:00 a.m.\n\n'
          'This maintenance window is required to apply critical security patches to the core '
          'network infrastructure.\n\n'
          'Emergency communications should be directed through the radio dispatch system during '
          'this window. The 119 emergency line is unaffected.\n\n'
          'ICTD Help Desk\n'
          'Internal ext. 4400',
      receivedAt: DateTime(2026, 5, 24, 16, 0),
      unread: false,
    ),
  ];

  @override
  Future<List<EmailMessage>> inbox() async => _messages;
}

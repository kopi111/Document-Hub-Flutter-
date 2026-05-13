import '../../models/news/news_article.dart';
import '../../models/news/news_priority.dart';
import 'news_repository.dart';

class InMemoryNewsRepository implements NewsRepository {
  InMemoryNewsRepository({DateTime? referenceDate})
      : _articles = _buildSeed(referenceDate ?? DateTime.now());

  final List<NewsArticle> _articles;

  @override
  Future<List<NewsArticle>> latestArticles({int limit = 20}) async {
    await _simulateNetworkLatency();
    final sorted = List<NewsArticle>.from(_articles)
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    if (limit >= sorted.length) return sorted;
    return sorted.sublist(0, limit);
  }

  @override
  Future<NewsArticle> articleById(String id) async {
    await _simulateNetworkLatency();
    for (final article in _articles) {
      if (article.id == id) return article;
    }
    throw NewsArticleNotFoundException(id);
  }

  Future<void> _simulateNetworkLatency() {
    return Future<void>.delayed(const Duration(milliseconds: 250));
  }

  static List<NewsArticle> _buildSeed(DateTime now) {
    return <NewsArticle>[
      NewsArticle(
        id: 'jcf-news-001',
        title: 'Commissioner appoints new Western Operations head',
        summary:
            'ACP Marcia Bennett takes the helm of Western Operations effective Monday, with a remit to drive down major crime across Areas 1 and 2.',
        body: _commissionerAnnouncementBody,
        imageUrl:
            'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=1600&q=80',
        category: 'Force-wide',
        publishedAt: now.subtract(const Duration(hours: 4)),
        author: 'JCF Public Affairs',
        priority: NewsPriority.high,
      ),
      NewsArticle(
        id: 'jcf-news-002',
        title: 'Force Order 12/2026 updated — review by 31 May',
        summary:
            'Revised guidance on body-worn camera retention takes effect immediately. All sub-officers must review and acknowledge by month-end.',
        body: _forceOrderBody,
        imageUrl:
            'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=1600&q=80',
        category: 'Force-wide',
        publishedAt: now.subtract(const Duration(days: 1, hours: 2)),
        author: 'JCF Office of the Commissioner',
        priority: NewsPriority.urgent,
      ),
      NewsArticle(
        id: 'jcf-news-003',
        title: 'PECC dispatch protocol revised for May 2026',
        summary:
            'New triage codes for domestic incidents come into force across all PECC dispatch desks. Training refreshers run all week at OCA.',
        body: _peccProtocolBody,
        imageUrl:
            'https://images.unsplash.com/photo-1494891848038-7bd202a2afeb?w=1600&q=80',
        category: 'Operational',
        publishedAt: now.subtract(const Duration(days: 3)),
        author: 'PECC Operations',
        priority: NewsPriority.high,
      ),
      NewsArticle(
        id: 'jcf-news-004',
        title: 'New Constable cohort sworn in at Twickenham Park',
        summary:
            '184 new constables completed the basic training course and were commissioned by the Commissioner of Police on Saturday.',
        body: _newCohortBody,
        imageUrl:
            'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?w=1600&q=80',
        category: 'Training',
        publishedAt: now.subtract(const Duration(days: 5, hours: 6)),
        author: 'NPCJ',
        priority: NewsPriority.normal,
      ),
      NewsArticle(
        id: 'jcf-news-005',
        title: 'ICTD rolls out Document Hub pilot to Area 1',
        summary:
            'The JCF Document Hub mobile app enters its first field pilot with officers in St James and Hanover. Feedback channels open this week.',
        body: _documentHubPilotBody,
        imageUrl:
            'https://images.unsplash.com/photo-1551434678-e076c223a692?w=1600&q=80',
        category: 'ICTD',
        publishedAt: now.subtract(const Duration(days: 9)),
        author: 'ICTD',
        priority: NewsPriority.normal,
      ),
      NewsArticle(
        id: 'jcf-news-006',
        title: 'Operation Restore Calm — week 18 summary',
        summary:
            'Joint operations across Areas 4 and 5 yielded 23 illegal firearms and 47 arrests in the past seven days. Operations continue.',
        body: _operationRestoreCalmBody,
        imageUrl:
            'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c8?w=1600&q=80',
        category: 'Operational',
        publishedAt: now.subtract(const Duration(days: 14, hours: 3)),
        author: 'Area 4 Command',
        priority: NewsPriority.normal,
      ),
      NewsArticle(
        id: 'jcf-news-007',
        title: 'PMMD vehicle maintenance window — 18 to 20 May',
        summary:
            'Service-wide quarterly inspection cycle begins next week. Divisional fleet officers should confirm vehicle slots with PMMD by Friday.',
        body: _pmmdMaintenanceBody,
        imageUrl:
            'https://images.unsplash.com/photo-1486006920555-c77dcf18193c?w=1600&q=80',
        category: 'Operational',
        publishedAt: now.subtract(const Duration(days: 21, hours: 12)),
        author: 'PMMD',
        priority: NewsPriority.normal,
      ),
      NewsArticle(
        id: 'jcf-news-008',
        title: 'JCF community policing forum returns to Spanish Town',
        summary:
            'The 2026 Q2 community policing town hall opens at the parish church hall on 28 May. All divisional commanders are expected to attend.',
        body: _communityForumBody,
        imageUrl: null,
        category: 'Force-wide',
        publishedAt: now.subtract(const Duration(days: 28)),
        author: 'JCF Public Affairs',
        priority: NewsPriority.normal,
      ),
    ];
  }
}

const String _commissionerAnnouncementBody = '''
The Commissioner of Police is pleased to announce the appointment of
**Assistant Commissioner Marcia Bennett** as the new head of **Western Operations**,
effective the coming Monday.

### Priorities for the first 90 days
- Drive down major crime in Areas 1 and 2
- Strengthen the partnership with the Jamaica Defence Force on joint patrols
- Roll out the new body-worn camera deployment schedule across St James

ACP Bennett brings 22 years of operational experience, having previously served as
the Deputy Commander for Area 1 and as the Inspectorate's lead investigator for
internal affairs matters. Her appointment follows the retirement of ACP Lloyd
Hamilton after 34 years of distinguished service.

> "The men and women of Western Operations have my full confidence and my full
> support. We will deliver on the Force's strategic plan and bring tangible
> safety improvements to the communities we serve." — ACP Marcia Bennett
''';

const String _forceOrderBody = '''
**Force Order 12/2026** has been updated to reflect the revised retention schedule
for body-worn camera footage. The amendments take effect **immediately**.

### What has changed
1. Standard retention extended from 30 to **90 days** for non-evidential footage.
2. Evidential footage tagged in CCN must be retained until the case is closed.
3. Every sub-officer must complete the acknowledgement form in the Document Hub by
   **31 May 2026**.

Failure to acknowledge by the deadline will be escalated through the divisional
commander. Detailed Q&A is published alongside the order in the **Force Orders**
category of the Document Hub.
''';

const String _peccProtocolBody = '''
The Police Emergency Communications Centre (PECC) has revised its dispatch
protocol for incoming domestic incidents.

### New triage codes
- **D1 — In progress**: dispatch a marked unit immediately and notify the
  divisional Domestic Violence Liaison Officer.
- **D2 — Recent / threat persisting**: dispatch within 15 minutes and capture a
  full caller statement.
- **D3 — Historic, no immediate threat**: route to the divisional desk for a
  scheduled welfare visit within 24 hours.

Training refreshers run all week at the **Operations Centre Annex**. Dispatchers
must complete the refresher before their next rostered shift.
''';

const String _newCohortBody = '''
On Saturday, **184 new constables** completed the basic training course and were
commissioned by the Commissioner of Police at the Police Officers' Club in
Twickenham Park.

The cohort includes:
- 112 male and 72 female recruits
- The first 18 graduates of the expanded cybercrime stream
- 9 recruits who completed the bilingual community-policing track

Postings will be communicated through the usual divisional channels next week.
The Commissioner thanked the families of the graduates and reminded the cohort
that the badge is a daily commitment to the people of Jamaica.
''';

const String _documentHubPilotBody = '''
ICTD is rolling out the **JCF Document Hub** mobile application to officers in
**Area 1**, beginning with the divisions of **St James** and **Hanover**.

### What officers can do today
- Browse Force Orders, JCF Policies, NPCJ training manuals and SOPs offline
- Search across the entire policy library by keyword
- Open documents in the integrated PDF reader without leaving the app

### Feedback
A dedicated feedback channel is open via the **About** screen. ICTD will publish
a weekly digest of issues and resolutions every Friday for the duration of the
pilot.
''';

const String _operationRestoreCalmBody = '''
Joint operations across **Areas 4 and 5** under Operation Restore Calm continued
through the past week.

### Highlights
- **23** illegal firearms recovered
- **47** arrests for serious offences
- **312** vehicles processed at static checkpoints
- **6** wanted persons apprehended without incident

The operation will continue through the end of the month. Divisional commanders
should ensure that all post-operation reports are filed in CCN within 48 hours
of each tactical deployment.
''';

const String _pmmdMaintenanceBody = '''
The quarterly service-wide vehicle inspection cycle runs from **18 to 20 May**.

### What divisional fleet officers must do
1. Confirm each vehicle's inspection slot with PMMD scheduling by Friday.
2. Ensure all on-board equipment is logged and accounted for.
3. Coordinate with the divisional duty officer to maintain operational cover
   during the maintenance window.

Vehicles that miss the cycle will be re-scheduled at the divisional fleet
officer's request, but this is strongly discouraged for marked units in
front-line service.
''';

const String _communityForumBody = '''
The **2026 Q2 community policing town hall** returns to the Spanish Town parish
church hall on **28 May**.

### Agenda
- Updates on Operation Restore Calm
- Community feedback session with the parish council
- Q&A with the Commissioner of Police

All divisional commanders in Area 5 are expected to attend in person. Commanders
from neighbouring areas may join virtually through the link circulated by the
Office of the Commissioner.
''';

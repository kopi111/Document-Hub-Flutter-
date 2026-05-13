# JCF Document Hub — Implementation TODO

Tracks the work needed to bring the codebase in line with **Proposal v2.0 (13 May 2026)** and the **ICTD Assessment (11 May 2026)**.

Source documents in this repo:
- `docs/proposals/v2/JCF_Document_Hub_Proposal_v2.pdf` (+ .docx / .txt)
- `docs/assessments/JCF Document Hub Assessment.pdf` (+ .docx / .txt)

## Legend

| Status | Meaning |
|---|---|
| Done | Merged into `production` |
| In progress | Branch open against `production` |
| Planned | Scoped, awaiting start |
| Blocked | Cannot start without ICTD action (AD tenant, SharePoint URL, Intune enrolment, etc.) |
| Server | Out of scope for this repo — backend work |

---

## Priority 1 — Critical (blocks pilot approval)

| # | v2 Section | Item | Side | Status | Notes |
|---|---|---|---|---|---|
| 1.1 | §5 | AD security groups (`JCF-DocHub-*`) defined and provisioned | Server | Blocked | Needs ICTD tenant access |
| 1.2 | §5.3 | Server-side group enforcement on every API request | Server | Blocked | Backend not yet built |
| 1.3 | §6 | REST endpoints `/api/v1/categories`, `/documents/{id}/content`, etc. | Server | In progress | Stub controllers in `backend/JcfDocumentHub.Api/Controllers/` (`CategoriesController`, `DocumentsController`, `SyncController`, `AuditController`). Mongo-backed list/search live; `/documents/{id}/content` and `/thumbnail` return 501 pending TODO 1.4. JWT validation is a dev stub (see `Authentication/DevelopmentJwtBearer.cs`). |
| 1.4 | §6.3 | PDF byte-range streaming (`Range:` header support) | Server | Blocked | Backend not yet built |
| 1.5 | §6.5 | Append-only audit log (2-year retention) | Server | Blocked | Backend not yet built |
| 1.6 | §9.1 | Tokens stored in Android Keystore (not SharedPreferences) | Client | Planned | Add `flutter_secure_storage` or use MSAL's storage |
| 1.7 | §9.2 | Cached PDFs in encrypted app-private storage (AES-256-GCM) | Client | Planned | Add encryption layer over cache files |
| 1.8 | §4 | OAuth 2.0 / OIDC sign-in via MSAL against JCF M365 tenant | Client | Planned | Add `msal_mobile` (or equivalent); needs tenant ID from ICTD |

## Priority 2 — High (required before Force-wide rollout)

| # | v2 Section | Item | Side | Status | Notes |
|---|---|---|---|---|---|
| 2.1 | §13.3 | GitHub Actions CI/CD pipeline (build → test → sign → distribute) | DevOps | Planned | Needs JCF release keystore + secrets vault |
| 2.2 | §13.2 | Firebase Crashlytics integration | Client | Planned | No PII in payloads |
| 2.3 | §6, §6.4 | Client-side API layer + HTTP 429 / `Retry-After` retry | Client | Done | `lib/services/api/` — abstract `DocumentHubApiClient` covering all 8 v2 endpoints, concrete `HttpDocumentHubApiClient` with rate-limit retry honouring `Retry-After`, typed `ApiException` hierarchy (Bad/Unauthorised/Forbidden/NotFound/RateLimited/Server/Network/ApiDeprecated), pluggable `TokenProvider` (Null/Static today; MSAL plugs in later), `X-Api-Deprecated` callback. 5 passing unit tests in `test/services/api/`. Not yet wired into UI — separate refactor will replace `GitHubService`. |
| 2.4 | §10 | Offline mode: cached metadata, encrypted PDF cache, 7-day TTL, 500 MB cap | Client | Planned | Add `sqflite_cipher` or Drift + SQLCipher |
| 2.4a | §10.2 | Offline banner in app header when no data connection | Client | Done | `lib/widgets/offline_banner.dart` wraps the app via `MaterialApp.builder`; `ConnectivityPlusService` boundary in `lib/services/connectivity_service.dart`; banner exposes `Semantics(liveRegion: true)` so TalkBack announces the transition |
| 2.5 | §10.3 | Sync manifest poll (every 6 h) + SHA-256 mismatch → cache invalidate | Client | Planned | Depends on `/api/v1/sync/manifest` |
| 2.6 | §10.4 | Staleness badges: Cached / Expiring / Updated / Live | Client | Done | `lib/widgets/document_staleness_badge.dart` + `DocumentCacheRepository` interface; backed by `InMemoryDemoDocumentCache` (demo seed) until TODO 2.4 lands the real encrypted cache |
| 2.7 | §8 | TLS 1.2 minimum + certificate pinning on the API host | Client | Planned | Configure HTTP client + bundle pinned fingerprint |
| 2.8 | §4.3 | 30-minute idle timeout → silent re-authentication | Client | Done (skeleton) | `lib/widgets/idle_timeout_gate.dart` wraps the app via `MaterialApp.builder` nested inside `OfflineBanner`. Resets a 30-min `Timer` on every pointer-down, and uses `WidgetsBindingObserver` to lock immediately if the app was backgrounded for ≥ 30 min. Shows a full-screen "Session paused" lock with a Resume button. The actual silent re-auth call still needs MSAL — Resume currently just unlocks; the hook point is `_resumeSession()`. |
| 2.9 | §13.2 | Application Insights for backend latency / error rate | Server | Blocked | Server-side observability |
| 2.10 | new | WestOps operational endpoints (wanted, missing, stolen vehicles, traffic codes) ported from `~/projects/WestOPs/` | Server | In progress | Stub controllers `WantedController`, `MissingController`, `StolenVehiclesController`, `TrafficCodesController` in `backend/JcfDocumentHub.Api/Controllers/`. Mongo collections seeded from `WestOPs/sql/westapp.sql` via `DatabaseSeeder`. |
| 2.11 | new | Flutter screens for WestOps lists (wanted/missing/stolen) | Client | Planned | Depends on 2.10 |

## Priority 3 — Medium (strengthens the document)

| # | v2 Section | Item | Side | Status | Notes |
|---|---|---|---|---|---|
| 3.1 | §11.1 | Breadcrumb navigation across screens | Client | Done | `lib/widgets/breadcrumb_trail.dart` implements `PreferredSizeWidget`; slotted into `AppBar.bottom` on document list, PDF viewer, and search results. Tappable segments use `Navigator.canPop` so the breadcrumb stays inert when the document list is embedded in the tablet two-pane. |
| 3.1a | §11.1, assessment "Server-side hierarchical folder structure" | True folder drill-down (sub-folders inside categories) | Server + Client | Blocked | Needs a backend folder schema. The current data model is flat (category → document). Real folders depend on §6 hierarchical storage from ICTD. |
| 3.2 | §11.1 | List/grid view toggle + sort (name/date) | Client | Done | `lib/screens/document_list_screen.dart` adds an AppBar view-mode toggle (list ↔ grid) plus a `PopupMenuButton` sort menu (Name A↔Z, Date newest/oldest). Chosen view + sort persist across launches via `lib/services/document_list_preferences.dart` (keys `document_list_view_mode_v1`, `document_list_sort_order_v1`). Date sort falls back to `DocumentCacheRepository.stateFor(doc).cachedAt` — `live` rows sort last for newest-first and first for oldest-first; a real `lastModified` field requires the backend `/api/v1/documents/{id}/metadata` endpoint (proposal §6.3). Server-side filter chips still pending. |
| 3.3 | §11.2 | Server-side full-text search with authorised-category filtering | Server + Client | Blocked | Backend index + client wiring |
| 3.4 | §11.3 | Accessibility: TalkBack labels, font scaling, dark mode, 48 dp tap targets | Client | Done | Tooltips on every icon button; `materialTapTargetSize: padded` + `visualDensity: standard` enforced in theme; `themeMode: system`; `DocumentStalenessBadge` exposes rich `Semantics` labels with relative time; deprecated `.withOpacity` calls migrated to `.withValues(alpha:)` |
| 3.5 | §11.4 | Two-pane tablet layout (width > 600 dp) | Client | Done | `lib/screens/home_screen.dart` dispatches on `MediaQuery.sizeOf(context).width > 600`; phone layout (stats + grid) unchanged; tablet layout renders `_CategorySidebar` (300 dp wide, stats + All Documents + category list) and `_TabletCategoryDetail` which embeds `DocumentListScreen` keyed by the selected category. Empty-state placeholder shown before a category is picked. PDF viewer remains full-screen per spec. |
| 3.6 | §14.2 | In-app privacy notice at first launch | Client | Done | `lib/screens/privacy_notice_screen.dart`, gated by `FirstLaunchGate` |
| 3.7 | §14.3 | EULA acceptance at first launch | Client | Done | `lib/screens/eula_screen.dart`, accepted-flag persisted via `FirstLaunchPreferences` |
| 3.8 | §14.1 | About screen with bundled third-party licence texts | Client | Done | `lib/screens/about_screen.dart`; opens Flutter's built-in `showLicensePage` for third-party licences; reachable from the home app bar 3-dot menu |
| 3.9 | Phase 2 | iOS port — Keychain + sandbox + MDM profile | Client | Planned | Defer until officer demand confirmed |
| 3.10 | §6.3 | First-page thumbnails on document tiles | Client | Planned | Depends on `/api/v1/documents/{id}/thumbnail` |
| 3.11 | §8 | Screenshot blocking + per-officer watermarking | Client | Planned | Phase 2 hardening |
| 3.12 | new | Force-wide News feed (CRUD, paginated by published date) | Server | In progress | `NewsController` + `MongoNewsRepository` in `backend/`. Article fields: id, title, summary, body (markdown), imageUrl, category (Force-wide / Operational / ICTD), publishedAt, author, priority (Normal/High/Urgent). Admin gate is a TODO comment until `JCF-DocHub-NewsEditors` AD group exists. |
| 3.13 | new | Flutter News feed screen on home dashboard | Client | Planned | Depends on 3.12 |

---

## Western Operations features (ported from WestOps)

Four features lifted from the sibling `~/projects/WestOPs/WestOps/westops/` Flutter app, reskinned to match Document Hub conventions (AppBar + breadcrumb + search + list/detail). Each ships with an abstract repository and an in-memory mock seeded with Jamaica-flavoured sample data; HTTP-backed repositories will land once the backend agent exposes `/api/v1/westops/*`.

| # | Feature | Files | Status | Notes |
|---|---|---|---|---|
| W.1 | Wanted Persons | `lib/models/westops/wanted_person.dart`, `lib/services/westops/wanted_persons_repository.dart`, `lib/screens/westops/wanted_list_screen.dart`, `lib/screens/westops/wanted_detail_screen.dart` | Done (UI + mock data) | `HttpWantedPersonsRepository` blocked on backend agent shipping `/api/v1/westops/wanted-persons` |
| W.2 | Missing Persons | `lib/models/westops/missing_person.dart`, `lib/services/westops/missing_persons_repository.dart`, `lib/screens/westops/missing_list_screen.dart`, `lib/screens/westops/missing_detail_screen.dart` | Done (UI + mock data) | `HttpMissingPersonsRepository` blocked on backend agent shipping `/api/v1/westops/missing-persons` |
| W.3 | Stolen Vehicles | `lib/models/westops/stolen_vehicle.dart`, `lib/services/westops/stolen_vehicles_repository.dart`, `lib/screens/westops/stolen_vehicles_list_screen.dart`, `lib/screens/westops/stolen_vehicle_detail_screen.dart` | Done (UI + mock data) | `HttpStolenVehiclesRepository` blocked on backend agent shipping `/api/v1/westops/stolen-vehicles` |
| W.4 | Traffic Code Reference | `lib/models/westops/traffic_code.dart`, `lib/services/westops/traffic_codes_repository.dart`, `lib/screens/westops/traffic_codes_list_screen.dart`, `lib/screens/westops/traffic_code_detail_screen.dart` | Done (UI + mock data) | Mock seeded with 10 RTA offence samples from the WestOps catalogue (full set is 147). `HttpTrafficCodesRepository` blocked on backend agent shipping `/api/v1/westops/traffic-codes` |

Home-screen integration: `lib/widgets/westops/westops_section.dart` exposes `WestOpsSection` (phone 2x2 grid) and `WestOpsSidebarSection` (tablet sidebar). `lib/screens/home_screen.dart` mounts both, with a sealed `_TabletSelection` (`_CategorySelection` | `_WestOpsSelection`) driving the two-pane detail slot.

---

## News / Announcements

A "news app" style feed of Force-wide announcements inside the existing Document Hub app. Visual language: hero image, large headline, summary, category chip, relative date, priority badge.

| # | Item | Side | Status | Notes |
|---|---|---|---|---|
| N.1 | News feed list screen with hero cards + pull-to-refresh + empty state | Client | UI Done — mock data | `lib/screens/news/news_feed_screen.dart`. Cards in `lib/widgets/news/news_card.dart` use 16:9 `Image.network` heroes with loading + error placeholders, titleLarge headline, 2-line summary, category chip + relative-date footer ("2h ago" / "yesterday" / "5 May 2026"). Breadcrumb `Home > News`. Currently fed by `InMemoryNewsRepository`. |
| N.2 | News detail screen with markdown body + share placeholder | Client | Done | `lib/screens/news/news_detail_screen.dart`. Hero image, headlineMedium title, priority badge if not normal, author · category · absolute date subtitle row, body rendered with `flutter_markdown`. Breadcrumb `Home > News > {title-truncated}`. Share `IconButton` is wired to a snackbar placeholder — actual sharing is Phase 2. |
| N.3 | Home tile / latest-news carousel | Client | Done | Phone layout: `HomeNewsCarousel` (`lib/widgets/news/home_news_carousel.dart`) above the stats banner — horizontal `ListView` of three compact image-and-headline cards plus a "View all" button. Tablet layout: `_SidebarNewsSection` at the top of the 300 dp sidebar — three accent-bar list tiles plus "View all" link. Both routes navigate to the feed list or directly to the detail screen. |
| N.4 | HTTP-backed `NewsRepository` against `/api/v1/news` | Server + Client | Blocked on backend | Abstract `NewsRepository` lives in `lib/services/news/news_repository.dart` with a `TODO` pointing at the future `HttpNewsRepository`. That implementation should reuse the `TokenProvider` + 429 retry plumbing already in `lib/services/api/`. |

Sample data in `lib/services/news/in_memory_news_repository.dart` seeds 8 Jamaica-flavoured articles (Commissioner appoints new Western Operations head, Force Order 12/2026 update, PECC dispatch protocol revision, new constable cohort sworn in, Document Hub pilot, Operation Restore Calm summary, PMMD maintenance window, community policing forum) with a mix of `normal` / `high` / `urgent` priorities and publication dates spanning the past 30 days.

Dependency added in `pubspec.yaml`: `flutter_markdown: ^0.7.4`.

---

## Dependencies to add (`pubspec.yaml`)

Once the client-side slices start, the following packages will land:

- `msal_mobile` — Microsoft 365 OAuth 2.0 / PKCE
- `flutter_secure_storage` — Keystore-backed token storage
- `sqflite_cipher` — encrypted local metadata cache
- `cryptography` or `encrypt` — AES-256-GCM for cached PDFs
- `firebase_crashlytics` — crash reporting
- `connectivity_plus` — offline detection
- `flutter_oss_licenses` — bundled licence texts for About screen

---

## What we need from ICTD before client work can connect to real services

1. Microsoft 365 tenant ID + application (client) ID for MSAL registration
2. Redirect URI registered against the app's package name
3. JCF API base URL (dev / staging / prod) — or a staging mock until backend exists
4. SHA-256 fingerprint of the API server certificate for pinning
5. Decision on document store (SharePoint site URL vs. dedicated store)
6. Intune tenant enrolment for MAM SDK registration
7. Release keystore for signed APK distribution
8. Confirmation of pilot division and AD group provisioning approach

---

## Next slice (suggested)

Smallest end-to-end vertical that proves the v2 architecture without depending on a real backend:

1. Add `msal_mobile` + sign-in screen that gates the app. Mock the M365 tenant against a dev-tier app registration.
2. Replace the hard-coded local document list with an HTTP API client that targets a stub server (mock returning the same 346 documents).
3. Add `flutter_secure_storage` and store the access token there.
4. Add the encrypted local cache + 7-day TTL + staleness badges (Cached / Expiring / Updated / Live).
5. Add the privacy notice and EULA first-launch screens (text from Appendix E and §14.3).

Each is a self-contained branch off `production`, mergeable independently once tested.

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
| 1.3 | §6 | REST endpoints `/api/v1/categories`, `/documents/{id}/content`, etc. | Server | Blocked | Backend not yet built |
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
| 2.3 | §6.4 | Rate-limit handling client-side (HTTP 429 + `Retry-After`) | Client | Planned | Wraps API client |
| 2.4 | §10 | Offline mode: cached metadata, encrypted PDF cache, 7-day TTL, 500 MB cap | Client | Planned | Add `sqflite_cipher` or Drift + SQLCipher |
| 2.5 | §10.3 | Sync manifest poll (every 6 h) + SHA-256 mismatch → cache invalidate | Client | Planned | Depends on `/api/v1/sync/manifest` |
| 2.6 | §10.4 | Staleness badges: Cached / Expiring / Updated / Live | Client | Done | `lib/widgets/document_staleness_badge.dart` + `DocumentCacheRepository` interface; backed by `InMemoryDemoDocumentCache` (demo seed) until TODO 2.4 lands the real encrypted cache |
| 2.7 | §8 | TLS 1.2 minimum + certificate pinning on the API host | Client | Planned | Configure HTTP client + bundle pinned fingerprint |
| 2.8 | §4.3 | 30-minute idle timeout → silent re-authentication | Client | Planned | App lifecycle hook |
| 2.9 | §13.2 | Application Insights for backend latency / error rate | Server | Blocked | Server-side observability |

## Priority 3 — Medium (strengthens the document)

| # | v2 Section | Item | Side | Status | Notes |
|---|---|---|---|---|---|
| 3.1 | §11 | Breadcrumb navigation + folder drill-down | Client | Planned | Replace current category grid |
| 3.2 | §11.1 | List/grid view toggle + sort (name/date) + filter | Client | Planned | UI work |
| 3.3 | §11.2 | Server-side full-text search with authorised-category filtering | Server + Client | Blocked | Backend index + client wiring |
| 3.4 | §11.3 | Accessibility: TalkBack labels, font scaling, dark mode, 48 dp tap targets | Client | Planned | Audit all widgets |
| 3.5 | §11.4 | Two-pane tablet layout (width > 600 dp) | Client | Planned | Responsive layout |
| 3.6 | §14.2 | In-app privacy notice at first launch | Client | Done | `lib/screens/privacy_notice_screen.dart`, gated by `FirstLaunchGate` |
| 3.7 | §14.3 | EULA acceptance at first launch | Client | Done | `lib/screens/eula_screen.dart`, accepted-flag persisted via `FirstLaunchPreferences` |
| 3.8 | §14.1 | About screen with bundled third-party licence texts | Client | Done | `lib/screens/about_screen.dart`; opens Flutter's built-in `showLicensePage` for third-party licences; reachable from the home app bar 3-dot menu |
| 3.9 | Phase 2 | iOS port — Keychain + sandbox + MDM profile | Client | Planned | Defer until officer demand confirmed |
| 3.10 | §6.3 | First-page thumbnails on document tiles | Client | Planned | Depends on `/api/v1/documents/{id}/thumbnail` |
| 3.11 | §8 | Screenshot blocking + per-officer watermarking | Client | Planned | Phase 2 hardening |

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

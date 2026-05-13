# JCF Document Hub — Status Snapshot

**Snapshot date:** 13 May 2026
**Branch:** `production` (11 commits ahead of `main`, unpushed)
**Source of truth:** `docs/IMPLEMENTATION_TODO.md` (30-row backlog table)

This document is an executive view derived from the full backlog. The numbers in brackets are the row IDs in `IMPLEMENTATION_TODO.md`.

---

## Summary

| Status | Count |
|---|---:|
| Done | 11 |
| Pickable now (no external blocker) | 5 |
| Blocked on ICTD inputs | 6 |
| Blocked on backend stand-up | 8 |
| **Total backlog rows** | **30** |

The pilot the v2.0 proposal asks for cannot start without the JCF backend being stood up; until then ~70 % of the v2 architecture is half-real even though every visible client-side commitment that does not require a backend has been delivered.

---

## Done in this repo (11 slices on `production`)

1. v2.0 proposal + ICTD assessment + IMPLEMENTATION_TODO landed
2. Privacy notice + EULA gate at first launch [3.6, 3.7]
3. About screen + bundled open-source licences [3.8]
4. Document cache staleness badges (Live / Cached / Expiring / Expired / Updated) [2.6]
5. Accessibility audit — tooltips, semantics, 48 dp tap targets, dark mode, font scaling [3.4]
6. Offline banner across every route, driven by `connectivity_plus` [2.4a]
7. List/grid view toggle + sort by name/date (persisted) [3.2]
8. Two-pane tablet layout at width > 600 dp [3.5]
9. Breadcrumb navigation across document list, viewer and search [3.1]
10. 30-minute idle-timeout lock with lifecycle-aware grace [2.8 — skeleton, MSAL hook pending]
11. API client layer + HTTP 429 retry + typed exceptions + 5 unit tests [2.3]

---

## Pickable now (no external blocker)

These can land without waiting on ICTD or the backend.

- **[1.7 / 2.4]** AES-256-GCM encrypted PDF cache with 7-day TTL and 500 MB cap. Replaces the in-memory demo cache currently behind the staleness badges. Pick `sqflite_cipher` or Drift + SQLCipher for the metadata store.
- **[3.10]** First-page thumbnails on tiles. Generate locally from cached PDFs via the Syncfusion PDF library; replace with the server `/thumbnail` endpoint when that lands.
- **[3.11]** Screenshot blocking on Android via `FLAG_SECURE` per sensitive route. One platform call per screen; fast.
- **[2.2]** Firebase Crashlytics integration. Needs a Firebase project but no JCF dependency.
- **(refactor)** Wire the new `HttpDocumentHubApiClient` into the existing screens, replacing `GitHubService`. Will point at a stub server until the real backend exists.

---

## Blocked on ICTD inputs

Cannot be completed until JCF provides the named artefact.

| Row | Item | What's needed from ICTD |
|---|---|---|
| 1.6 | Android Keystore token storage | Comes with MSAL — needs 1.8 first |
| 1.8 | MSAL OAuth sign-in against JCF M365 | M365 tenant ID, application/client ID, redirect URI |
| 2.1 | GitHub Actions CI/CD pipeline | JCF release keystore + secrets vault access |
| 2.7 | TLS 1.2 + certificate pinning | SHA-256 fingerprint of the API server cert |
| — | Intune MAM SDK registration | Intune tenant enrolment |
| 3.9 | iOS port (Keychain, sandbox, MDM profile) | Officer-population demand confirmation + Apple developer account |

---

## Blocked on backend stand-up

Cannot be completed until JCF ICTD stands up the API backend described in proposal §6.

| Row | Item |
|---|---|
| 1.1 | AD security groups `JCF-DocHub-*` defined and provisioned |
| 1.2 | Server-side group enforcement on every API request |
| 1.3 | REST endpoints (`/categories`, `/documents/{id}/content`, etc.) |
| 1.4 | PDF byte-range streaming (HTTP `Range` header) |
| 1.5 | Append-only audit log with 2-year retention |
| 2.5 | Sync-manifest poll + SHA-256 cache invalidation |
| 2.9 | Application Insights backend observability |
| 3.1a | True sub-folder drill-down (hierarchical folder schema) |
| 3.3 | Server-side full-text search with authorised-category filtering |

---

## What is asked of JCF

To unblock the pilot the proposal recommends, JCF/ICTD action is required on:

1. **Approval in principle** to proceed to pilot.
2. **ICTD sponsorship** to register the application in the JCF Microsoft 365 tenant.
3. **A nominated Content Owner.**
4. **A pilot division.**
5. **Intune MAM enrolment.**
6. **Confirmation of SharePoint as document store.**
7. **A staffed backend project** to deliver the REST API described in proposal §6.

These match the requests in section 16 of the v2.0 proposal.

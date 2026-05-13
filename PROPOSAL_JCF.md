# Proposal: JCF Document Hub

**Submitted to:** Jamaica Constabulary Force — Information & Communications Technology Division (ICTD)
**Prepared by:** Dwayne Aitken
**Date:** 2026-04-22
**Subject:** Mobile application for secure, anywhere access to JCF policies, Force Orders, and SOPs

---

## 1. Executive Summary

The JCF Document Hub is a mobile application that places the Force's policies, Force Orders, and Standard Operating Procedures directly in the hands of every officer — on duty, off duty, or at home. Instead of searching through binders, shared drives, or relying on a colleague to forward a PDF, an officer pulls out their phone, signs in with their **@jcf.gov.jm webmail credentials**, and has the entire policy library at their fingertips.

The application is built, tested, and deployable today. This document proposes its formal adoption by the Force.

---

## 2. The Problem

Officers across the Force routinely need to consult policy documents and Force Orders to do their jobs correctly:

- A patrol officer responding to a missing-person report needs the Missing Person Investigation SOP.
- A station commander preparing a disciplinary review needs the Administrative Review Policy.
- A traffic officer needs the latest TMMD operating procedures.
- A new constable needs to study Force Orders before an exam.

Today, accessing these documents typically requires:

- Being physically at a station with a computer connected to the JCF network.
- Asking a supervisor to email a copy.
- Carrying printed binders that go out of date.
- Searching personal WhatsApp threads for a forwarded PDF.

This friction costs time, leads to officers acting on outdated versions, and prevents officers from preparing or studying outside of work hours.

---

## 3. The Proposed Solution

The **JCF Document Hub** is a native Android application that provides:

| Feature | What it does |
|---|---|
| **Centralised library** | All 346 policy documents in one place, organised into 19 categories (Force Orders, NPCJ, TMMD, CIB, PMMD, SOPs, PECC, PRDB, PMAS, FLPD, FIPT, DWTT, FIBUA, PPMU, ICTD, ICT, and General). |
| **Search** | Find any policy by keyword across the entire library or within a specific category. |
| **PDF viewer** | Open and read documents directly in the app — pinch-to-zoom, page navigation, no third-party app required. |
| **Read-aloud (Text-to-Speech)** | Officers can have policies *read* to them — useful while commuting, on a break, or for accessibility. |
| **Offline cache** | Once a document is opened, it remains accessible without a data connection. |
| **Always current** | Documents are pulled from a single, controlled source — the moment a policy is updated centrally, every officer sees the new version on next refresh. |

### 3.1 Authentication via JCF Webmail (Proposed)

Currently the prototype is open. Before Force-wide deployment, we propose adding a sign-in layer that uses each officer's existing **JCF webmail account** (`@jcf.gov.jm`) as the credential.

This gives the Force:

- **No new password to remember** — officers use the credentials they already have.
- **No new identity system** — we leverage the existing JCF mail infrastructure (Microsoft 365 / Exchange).
- **Instant deprovisioning** — when an officer's webmail account is disabled, their access to the Document Hub is automatically revoked. No separate offboarding step.
- **Audit trail** — every sign-in is tied to a verified JCF identity.
- **Domain restriction** — only `@jcf.gov.jm` addresses can authenticate; the app rejects all others.

Implementation would use **OAuth 2.0 / OpenID Connect** against Microsoft 365 (the standard, supported method). No passwords are stored by the app.

---

## 4. How It Benefits the Force

### For the rank-and-file officer
- Study Force Orders at home before a promotion exam.
- Confirm the correct procedure on scene without leaving the location.
- Access the policy library on personal time, on a personal device, securely.

### For supervisors and station commanders
- Confidence that every officer has the *current* version of every policy.
- No more printing, distributing, or chasing acknowledgement of paper policies.

### For the Force as an institution
- A measurable reduction in policy-knowledge gaps.
- A modern, professional tool that signals investment in officer development.
- Centralised control: when a policy changes, every phone in the Force updates.

### For ICTD
- Built on standard, supported technology (Flutter, OAuth/M365).
- No new servers required for the document library — content can be hosted on existing JCF-controlled storage.
- Low operational overhead.

---

## 5. Security Considerations

| Concern | How it is addressed |
|---|---|
| Unauthorised access | JCF webmail (M365) sign-in restricted to `@jcf.gov.jm` domain. |
| Stale access for ex-officers | Disabling the webmail account immediately revokes app access. |
| Document leakage | App-level controls (no screenshot, no share, watermarking) can be added in phase 2. |
| Document integrity | Documents are served from a single ICTD-controlled source, signed, and version-tracked. |
| Lost or stolen device | Re-authentication is required after a configurable idle period; M365 Conditional Access policies (MFA, device compliance) apply automatically. |

---

## 6. Technical Overview

- **Platform:** Android (iOS port available on request)
- **Framework:** Flutter (single codebase, native performance)
- **Document storage:** Documents are served from an **ICTD-controlled document store**. The app is storage-agnostic and integrates with **JCF SharePoint** or any approved internal document service.
- **Authentication (proposed):** Microsoft Authentication Library (MSAL) → JCF Microsoft 365 tenant.
- **Footprint:** ~60 MB install, no background services, minimal battery impact.

---

## 7. Proposed Rollout

| Phase | Scope | Duration |
|---|---|---|
| **1. Pilot** | ICTD staff + one selected division. JCF webmail sign-in enabled. Feedback collected. | 4 weeks |
| **2. Hardening** | Add screenshot blocking, watermarking, audit logging based on pilot feedback. | 2 weeks |
| **3. Force-wide release** | Distribute via JCF-managed channel (MDM / internal app catalogue). Training note circulated. | 2 weeks |
| **4. Ongoing** | ICTD owns content updates. Quarterly app updates. | Continuous |

---

## 8. What is Asked of JCF

1. **Approval in principle** to proceed to a pilot.
2. **ICTD sponsorship** to register the app in the JCF Microsoft 365 tenant (for webmail sign-in).
3. **A nominated content owner** — the person(s) authorised to add/update/retire policy documents.
4. **A pilot division** — one division willing to use the app for 4 weeks and provide feedback.

No cost is requested for the pilot. The app is built. The infrastructure is leveraged from systems the Force already operates.

---

## 9. Closing

Every officer carries a smartphone. Every officer is expected to know Force policy. The gap between those two facts is what the JCF Document Hub closes — securely, cheaply, and immediately.

I am available to demonstrate the app at the Force's convenience.

**Contact:** Dwayne Aitken — dwayneaitken111@gmail.com

---

*Appendices available on request: screenshots, architecture diagram, sample webmail sign-in flow, security review checklist.*

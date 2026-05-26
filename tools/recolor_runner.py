#!/usr/bin/env python3
"""Spawn 15 parallel `claude -p` workers, each recoloring ONE screen unit to the
unified JCF color grading.

Foundation (lib/theme/jcf_palette.dart + the rewired DutyTheme/NamStyle) is
already in place and the global theme is dark-first. Each worker owns a disjoint
set of files, so concurrent edits never collide. Workers reference the shared
JcfPalette tokens (passed verbatim below) and apply the per-screen semantic
mapping from the design spec.

Output: tools/run-<timestamp>/<unit>.txt (worker summary) and .err (stderr).
"""
import subprocess
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

PROJECT = Path(__file__).resolve().parent.parent
TOOLS = PROJECT / "tools"
PALETTE = (PROJECT / "lib/theme/jcf_palette.dart").read_text()

TS = time.strftime("%Y%m%d-%H%M%S")
RUN_DIR = TOOLS / f"run-{TS}"
RUN_DIR.mkdir(parents=True, exist_ok=True)

# unit name -> (relative file paths, per-screen semantic mapping)
UNITS = {
    "home": (
        ["lib/screens/home_screen.dart"],
        "Home dashboard. Use theme surfaces for cards; amber accent (JcfPalette.accent) "
        "for the active bottom-nav state and primary actions; urgency badges via UrgencyStyle.",
    ),
    "dashboard": (
        ["lib/screens/dashboard/services_home_screen.dart"],
        "Services dashboard. Replace ALL hardcoded Color(0x...) literals with the nearest "
        "JcfPalette token. Greeting/section cards use theme surface; amber accent for highlights.",
    ),
    "documents": (
        ["lib/screens/documents/documents_home_screen.dart",
         "lib/screens/document_list_screen.dart"],
        "Document categories + list. Category cards use theme surface + JcfPalette.hairline "
        "borders; category icons use JcfPalette.iconDefault, active/selected uses amber accent.",
    ),
    "map": (
        ["lib/screens/map/map_screen.dart"],
        "Operations map. Map overlays/legend panels use JcfPalette.surface at ~85% opacity; "
        "the user-location ring uses amber accent (JcfPalette.accent); incident pins use "
        "JcfPalette.danger.",
    ),
    "calendar": (
        ["lib/screens/calendar/calendar_screen.dart"],
        "Calendar + reminders. Today marker dot uses JcfPalette.info (Patrol Blue); overdue "
        "items use JcfPalette.danger; near-deadline uses JcfPalette.warning.",
    ),
    "news": (
        ["lib/screens/news/news_feed_screen.dart",
         "lib/screens/news/news_detail_screen.dart"],
        "Announcements feed. Cards use theme surface; HIGH-priority badge uses UrgencyStyle.high "
        "(amber bg / dark text), URGENT uses UrgencyStyle.urgent (red bg / white text / red border). "
        "Replace hardcoded Color(0x...) with JcfPalette tokens.",
    ),
    "notes": (
        ["lib/screens/notes/notes_screen.dart"],
        "Notes / quick capture. Save button uses amber accent (JcfPalette.accent on onAccent text); "
        "delete action uses JcfPalette.danger; note cards use theme surface.",
    ),
    "notifications": (
        ["lib/screens/notifications/notifications_screen.dart"],
        "Notification center. Unread/important items badged via UrgencyStyle; list tiles use theme "
        "surface; icons use JcfPalette.iconDefault, critical alerts JcfPalette.iconCritical.",
    ),
    "missing": (
        ["lib/screens/westops/missing_list_screen.dart",
         "lib/screens/westops/missing_detail_screen.dart",
         "lib/screens/westops/mark_found_screen.dart"],
        "Missing persons. Info icons use JcfPalette.info (Patrol Blue); a 'days missing > 14' "
        "indicator uses JcfPalette.warning (Urgent Amber); 'Found' status uses JcfPalette.success. "
        "These screens already use NamStyle tokens (now JCF) — only adjust per-screen semantics.",
    ),
    "wanted": (
        ["lib/screens/westops/wanted_list_screen.dart",
         "lib/screens/westops/wanted_detail_screen.dart"],
        "Wanted persons. ARMED/VIOLENT badge uses JcfPalette.danger (Critical Red, white text); "
        "high-risk uses amber accent (JcfPalette.accent). Hero/detail header may use "
        "JcfPalette.heroGradient. Screens already use NamStyle — adjust semantics only.",
    ),
    "stolen": (
        ["lib/screens/westops/stolen_vehicles_list_screen.dart",
         "lib/screens/westops/stolen_vehicle_detail_screen.dart"],
        "Stolen vehicles. 'Stolen' badge uses amber accent (JcfPalette.accent); 'Recovered' tag "
        "uses JcfPalette.success (Operational Green). Replace any hardcoded Color(0x...) with "
        "JcfPalette tokens.",
    ),
    "traffic": (
        ["lib/screens/westops/traffic_codes_list_screen.dart",
         "lib/screens/westops/traffic_code_detail_screen.dart"],
        "Traffic codes. Fine-amount highlight uses amber accent (JcfPalette.accent); a '0 points' "
        "value uses JcfPalette.success. Sticky header + rows use theme surface.",
    ),
    "search_pdf": (
        ["lib/screens/search_results_screen.dart",
         "lib/screens/pdf_viewer_screen.dart"],
        "Search results + PDF viewer. Result tiles use theme surface; category labels use "
        "JcfPalette.textSecondary; match highlight / active controls use amber accent.",
    ),
    "info_screens": (
        ["lib/screens/about_screen.dart",
         "lib/screens/eula_screen.dart",
         "lib/screens/privacy_notice_screen.dart",
         "lib/screens/first_launch_gate.dart",
         "lib/screens/app_shell.dart"],
        "Static / gate screens. Background = JcfPalette.background; body text = "
        "JcfPalette.textPrimary, secondary = JcfPalette.textSecondary; primary CTA uses amber "
        "accent. Keep all existing copy and logic.",
    ),
    "shared_widgets": (
        ["lib/widgets/news/news_card.dart",
         "lib/widgets/news/news_priority_badge.dart",
         "lib/widgets/news/news_category_label.dart",
         "lib/widgets/news/news_date_label.dart",
         "lib/widgets/news/home_news_carousel.dart",
         "lib/widgets/news/news_hero_image.dart",
         "lib/widgets/dashboard/category_card.dart",
         "lib/widgets/dashboard/greeting_card.dart",
         "lib/widgets/dashboard/dashboard_skeleton.dart",
         "lib/widgets/offline_banner.dart",
         "lib/widgets/notifications_bell.dart"],
        "Shared widgets. news_priority_badge MUST map priorities to UrgencyStyle "
        "(urgent->red+border, high->amber, medium->blue, routine->grey). Replace every hardcoded "
        "Color(0x...) with the nearest JcfPalette token. Skeletons use JcfPalette.surfaceRaised.",
    ),
}

PROMPT_TEMPLATE = """You are one of 15 parallel workers recoloring the JCF Document Hub Flutter app to a single unified color grading. You own ONE unit only.

SHARED COLOR SOURCE OF TRUTH (already created at lib/theme/jcf_palette.dart) — use these exact token names:
---
{palette}
---

The global theme (DutyTheme) and the West-Ops NamStyle are ALREADY rewired to this palette and the app is dark-first, so most colors flow automatically. Your job is the per-screen REFINEMENT below.

YOUR UNIT: {unit}
FILES YOU MAY EDIT (relative to repo root, and ONLY these):
{files}

PER-SCREEN MAPPING (from the design spec):
{guidance}

HARD RULES:
1. Edit ONLY the files listed above. Do NOT touch any other file. Do NOT create files.
2. Do NOT change layout, copy, navigation, business logic, or imports beyond adding
   `import '../../theme/jcf_palette.dart';` (fix the relative depth) only if you actually
   reference JcfPalette/UrgencyStyle/UrgencyLevel and it is not already imported.
3. Replace every hardcoded `Color(0x........)` literal you find with the NEAREST JcfPalette
   token. Prefer `Theme.of(context).colorScheme.*` / existing NamStyle tokens where the file
   already uses them — do not fight the existing pattern, just correct the color values.
4. Apply the per-screen mapping above for badges/accents/urgency.
5. The result MUST still compile: valid Dart, no undefined names, no removed required args.
6. Do NOT run any shell command, build, or test — just make the edits.

When done, print a 3-6 line summary: which files you changed and the key color decisions. No preamble.
"""


def run_worker(unit: str, files, guidance: str):
    out_file = RUN_DIR / f"{unit}.txt"
    err_file = RUN_DIR / f"{unit}.err"
    file_list = "\n".join(f"  - {f}" for f in files)
    prompt = PROMPT_TEMPLATE.format(
        palette=PALETTE, unit=unit, files=file_list, guidance=guidance,
    )
    start = time.time()
    proc = subprocess.run(
        ["claude", "-p", "--model", "haiku",
         "--permission-mode", "acceptEdits", prompt],
        cwd=str(PROJECT), capture_output=True, text=True, timeout=900,
    )
    out_file.write_text(proc.stdout)
    if proc.stderr.strip():
        err_file.write_text(proc.stderr)
    return unit, time.time() - start, proc.returncode, len(proc.stdout)


def main():
    work = [(u, f, g) for u, (f, g) in UNITS.items()]
    print(f"[runner] spawning {len(work)} workers -> {RUN_DIR}")
    with ThreadPoolExecutor(max_workers=15) as pool:
        futures = {pool.submit(run_worker, *w): w for w in work}
        for fut in as_completed(futures):
            unit, dur, rc, size = fut.result()
            status = "OK" if rc == 0 else f"RC={rc}"
            print(f"  [{status}] {unit:<16} {dur:>6.1f}s {size:>6}B")
    (TOOLS / ".last_run").write_text(TS)
    print(f"\n[runner] done: {RUN_DIR}")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""15-agent QA swarm for the JCF Document Hub chat feature.

Fans out 15 headless `claude -p` workers (the project's preferred swarm runtime),
each given the exact source it needs and a focused review lens. Workers are pure
analysts — they are told NOT to use tools, so they never block on a headless
permission prompt. Findings are collected per worker and aggregated into
REPORT.md.
"""

import concurrent.futures
import pathlib
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(__file__).resolve().parent / "findings"
OUT.mkdir(parents=True, exist_ok=True)

MODEL = "sonnet"          # fast, capable enough for code QA
MAX_CONCURRENT = 5        # gentle on the machine; 15 at once is too heavy
PER_WORKER_TIMEOUT = 300  # seconds


def read(rel):
    p = REPO / rel
    try:
        return f"// ===== FILE: {rel} =====\n" + p.read_text(encoding="utf-8")
    except Exception as e:  # noqa: BLE001
        return f"// ===== FILE: {rel} (UNREADABLE: {e}) ====="


def bundle(rels):
    return "\n\n".join(read(r) for r in rels)


CHAT = "lib/screens/chat"
MODELS = "lib/models/chat"
REPO_FILE = "lib/services/chat/chat_repository.dart"

# (id, short_title, [files], lens)
TASKS = [
    (1, "repository-logic", [REPO_FILE],
     "Audit conversation/group data logic: startConversation dedupe correctness, "
     "startGroupConversation, availableContacts filtering, and any bugs from the "
     "single mutable shared seed list (aliasing, ordering, stale state)."),
    (2, "thread-screen", [f"{CHAT}/chat_thread_screen.dart"],
     "Audit the message thread: send flow, text controller handling, empty/whitespace "
     "messages, auto-scroll, keyboard, and async correctness."),
    (3, "list-screen", [f"{CHAT}/chat_list_screen.dart"],
     "Audit the conversation list: loading/empty/error states, navigation, and whether "
     "the list refreshes after returning from a thread or creating a chat."),
    (4, "new-chat-and-group", [f"{CHAT}/new_chat_screen.dart", f"{CHAT}/new_group_screen.dart"],
     "Audit chat/group creation: contact selection, validation (empty group name, zero "
     "members, single member), duplicate handling, and how results are returned/consumed."),
    (5, "model-message", [f"{MODELS}/chat_message.dart"],
     "Audit the message model: fields, timestamp/status handling, immutability, equality, "
     "and any missing fields the UI assumes."),
    (6, "model-conversation", [f"{MODELS}/chat_conversation.dart"],
     "Audit the conversation model: group vs one-to-one invariants, last-message/unread "
     "derivation, and null-safety of optional fields."),
    (7, "model-contact-group", [f"{MODELS}/chat_contact.dart", f"{MODELS}/chat_group.dart"],
     "Audit contact & group models: presence fields (isOnline/lastSeen), member lists, "
     "avatar handling, and invariants."),
    (8, "async-lifecycle", [f"{CHAT}/chat_thread_screen.dart", f"{CHAT}/chat_list_screen.dart",
                            f"{CHAT}/new_chat_screen.dart", f"{CHAT}/new_group_screen.dart"],
     "Hunt ONLY for async/lifecycle bugs: use of BuildContext across an await, missing "
     "`mounted` checks before setState/Navigator, uncancelled controllers/timers, and "
     "dispose() correctness. Cite file + line."),
    (9, "null-safety-errors", [REPO_FILE, f"{CHAT}/chat_thread_screen.dart", f"{CHAT}/chat_list_screen.dart"],
     "Hunt ONLY for null-safety and error-handling defects: force-unwraps (!), unhandled "
     "Futures/exceptions, the UnsupportedError group path, and unguarded .first/index access."),
    (10, "edge-cases", [REPO_FILE, f"{CHAT}/chat_thread_screen.dart", f"{MODELS}/chat_message.dart"],
     "Enumerate concrete EDGE CASES and predict the behavior: empty/very long messages, "
     "emoji/RTL/unicode, rapid double-send, duplicate conversation, messaging yourself, "
     "empty roster. Flag which ones break."),
    (11, "presence", [f"{CHAT}/chat_presence.dart"],
     "Audit presence/last-seen logic: online vs last-seen formatting, 'x min ago' math, "
     "timezone/DateTime.now assumptions, and future-dated timestamps."),
    (12, "styling-theme", [f"{CHAT}/chat_style.dart", f"{CHAT}/chat_wallpaper.dart"],
     "Audit styling: hardcoded colors vs theme tokens, text contrast, overflow/wrapping, "
     "and whether it aligns with a redesigned light/blue 'Hub' look."),
    (13, "accessibility-ux", [f"{CHAT}/chat_thread_screen.dart", f"{CHAT}/chat_list_screen.dart"],
     "Audit accessibility & UX: tap-target sizes, Semantics/labels, send-button enabled/"
     "disabled states, focus, and empty-state guidance."),
    (14, "clean-code", [REPO_FILE, f"{CHAT}/chat_thread_screen.dart", f"{CHAT}/chat_list_screen.dart"],
     "Review against Clean Code: intention-revealing names, function size/single-purpose, "
     "duplication across chat files, SRP, and comments that merely restate code."),
    (15, "integration-flows", [REPO_FILE, f"{CHAT}/chat_list_screen.dart", f"{CHAT}/chat_thread_screen.dart",
                               f"{CHAT}/new_chat_screen.dart", f"{CHAT}/new_group_screen.dart"],
     "Trace end-to-end flows and find breaks: start conversation -> thread -> back -> list "
     "ordering/update; group creation end-to-end; sent messages surviving navigation."),
]

PROMPT_TEMPLATE = """You are a senior Flutter/Dart code reviewer doing a focused QA pass on ONE \
slice of an officer-to-officer chat feature (in-memory, no backend) in the JCF Document Hub app.

REVIEW LENS: {lens}

Rules:
- Analyze ONLY the code provided below. Do NOT use any tools. Do NOT ask questions.
- Report concrete, specific findings — each with: a severity tag [BUG]/[RISK]/[EDGE]/[NIT], \
the file and approximate line/symbol, what's wrong, and a one-line fix suggestion.
- If a behavior is actually correct, don't invent problems. Aim for real defects over nitpicks.
- End with a one-line "TOP ISSUE:" naming the single most important thing to fix.

Output GitHub-flavored markdown, no preamble.

CODE UNDER REVIEW:
{code}
"""


def run_worker(task):
    tid, title, files, lens = task
    prompt = PROMPT_TEMPLATE.format(lens=lens, code=bundle(files))
    started = time.time()
    try:
        proc = subprocess.run(
            ["claude", "-p", prompt, "--model", MODEL],
            capture_output=True, text=True, timeout=PER_WORKER_TIMEOUT,
        )
        body = proc.stdout.strip() or f"(no output; stderr: {proc.stderr.strip()[:500]})"
    except subprocess.TimeoutExpired:
        body = f"(worker timed out after {PER_WORKER_TIMEOUT}s)"
    except Exception as e:  # noqa: BLE001
        body = f"(worker failed: {e})"
    elapsed = time.time() - started
    header = f"# Worker {tid:02d} — {title}\n\n_Lens: {lens}_\n\n_Files: {', '.join(files)} | {elapsed:.0f}s_\n\n"
    (OUT / f"{tid:02d}_{title}.md").write_text(header + body, encoding="utf-8")
    print(f"[{tid:02d}] {title}: done in {elapsed:.0f}s ({len(body)} chars)", flush=True)
    return tid, title, body


def main():
    print(f"Chat QA swarm: {len(TASKS)} workers, model={MODEL}, "
          f"max {MAX_CONCURRENT} concurrent\n", flush=True)
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_CONCURRENT) as pool:
        for r in pool.map(run_worker, TASKS):
            results.append(r)
    results.sort(key=lambda x: x[0])

    report = pathlib.Path(__file__).resolve().parent / "REPORT.md"
    with report.open("w", encoding="utf-8") as f:
        f.write("# Chat Feature — 15-Agent QA Report\n\n")
        f.write(f"_Generated by `run_chat_qa.py` · {len(TASKS)} `claude -p` workers · model {MODEL}_\n\n")
        f.write("## Contents\n")
        for tid, title, _ in results:
            f.write(f"- [Worker {tid:02d} — {title}](#worker-{tid:02d}--{title.replace('-', '-')})\n")
        f.write("\n---\n\n")
        for tid, title, body in results:
            f.write(f"## Worker {tid:02d} — {title}\n\n{body}\n\n---\n\n")
    print(f"\nAggregated report -> {report}", flush=True)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""15-agent QA swarm (v3) for the NEW chat system: Telegram-parity features +
LDAP login + live API + per-user identity.

Unlike v1/v2 (static code review), these workers ACTUALLY TEST:
  - 9 API workers hit the running backend on http://localhost:5070 with curl
    assertions (one bash suite each under findings_v3/<id>.sh).
  - 6 Flutter workers write and RUN `flutter test` suites under test/chat_qa/.

Each worker owns DISJOINT files and ends its log with a machine-readable verdict:
    QA-VERDICT id=<id> PASS=<n> FAIL=<n> BLOCKED=<n>
so run_chat_qa_v3.py can aggregate REPORT_v3.md.

Prereqs: API running on :5070 (Ldap disabled), Flutter SDK at ~/flutter/bin.

Usage:
  python3 run_chat_qa_v3.py                 # all 15
  python3 run_chat_qa_v3.py --dry-run qa-identity
  python3 run_chat_qa_v3.py qa-auth qa-reactions
"""

import concurrent.futures
import os
import pathlib
import re
import subprocess
import sys
import time

REPO = pathlib.Path(__file__).resolve().parents[2]          # Document-Hub-Flutter-
HERE = pathlib.Path(__file__).resolve().parent              # swarm/chat-qa
FINDINGS = HERE / "findings_v3"
FINDINGS.mkdir(parents=True, exist_ok=True)
API = "http://localhost:5070"
FLUTTER = os.path.expanduser("~/flutter/bin/flutter")

MODEL = os.environ.get("SWARM_MODEL", "sonnet")
MAX_CONCURRENT = int(os.environ.get("SWARM_CONCURRENCY", "4"))
PER_WORKER_TIMEOUT = int(os.environ.get("SWARM_TIMEOUT", "900"))

SHARED = f"""You are ONE worker in a 15-agent QA swarm acting as a meticulous senior QA engineer.
You TEST the JCF Document Hub chat system and report real, reproduced results — never guess.

System under test:
- Flutter app at {REPO} (chat in lib/screens/chat, lib/widgets/chat, lib/services/chat, lib/services/auth).
- .NET API RUNNING at {API} (routes under /v1; auth /v1/auth/login accepts any non-empty creds because
  Ldap:Enabled=false; chat under /v1/chat). JSON is snake_case; bearer token from login in Authorization.
- Recent additions you are validating: reactions, reply, edit/delete, pin, forward, voice/image/file
  attachments, in-chat search, disappearing messages, typing/presence/read-receipts, LDAP login gate,
  live polling, and PER-USER IDENTITY (the API stamps each message's sender from the bearer token and
  returns `from_me` relative to the reader).

Rules:
- Own ONLY the files this slice names. Do not touch other workers' files or app source (you write TESTS,
  not fixes). If you find a real defect, REPORT it — do not patch app code.
- Make assertions explicit and reproducible. Prefer many small checks over one big one.
- Distinguish a real BUG (system behaves wrong) from a test-harness issue (BLOCKED).
- End your output with EXACTLY this block (machine-parsed), then a short bullet list of any bugs:
    QA-VERDICT id={{ID}} PASS=<int> FAIL=<int> BLOCKED=<int>
    BUGS:
    - [SEV: HIGH|MED|LOW] <what failed> | <endpoint or file:line> | <expected vs actual>
  If no bugs, write 'BUGS: none'.
"""

API_HOWTO = f"""You are an API tester. Write a self-contained bash suite to {{SUITE}} and RUN it with bash.
- Get a token: TOKEN=$(curl -s -X POST {API}/v1/auth/login -H 'Content-Type: application/json' \
-d '{{"username":"<user>","password":"x"}}' | grep -oE '"token":"[a-f0-9]+"' | cut -d'"' -f4)
- Call endpoints with -H "Authorization: Bearer $TOKEN"; assert on HTTP status (curl -o /dev/null -w '%{{http_code}}')
  and on response body (grep/jq if available, else grep -oE). Print 'PASS: <case>' / 'FAIL: <case> expected.. got..'
  for every case. Use distinct usernames per officer when identity matters. Seed conv ids exist: conv-001..conv-004.
- Tally PASS/FAIL from your own output for the verdict. Keep the .sh file so results are reproducible."""

FLUTTER_HOWTO = f"""You are a Flutter test author. Write {{SUITE}} and RUN it with: {FLUTTER} test <file> -r expanded
- Use package:flutter_test. For HTTP mocking use package:http/testing.dart MockClient (NO mockito — not a dep).
- Test real behavior and edge cases; assert with expect(). If a test reveals an app bug, keep the failing test
  and REPORT the bug (do not edit app code). Tally expect-group results for the verdict from the run output."""

# (id, kind, suite_path, task)
SLICES = [
    ("qa-auth", "api", "swarm/chat-qa/findings_v3/qa-auth.sh",
     "Auth: POST /v1/auth/login with (a) valid creds -> 200 + token+display_name+username, "
     "(b) empty username, (c) empty password, (d) unicode/special-char username. GET /v1/auth/me WITH a "
     "valid bearer -> 200 echoing the username; GET /v1/auth/me with NO token and with a GARBAGE token. "
     "Verify two separate logins yield DIFFERENT tokens and that a token keeps working across several calls "
     "(singleton store persistence)."),
    ("qa-conversations", "api", "swarm/chat-qa/findings_v3/qa-conversations.sh",
     "Conversations: GET /v1/chat/conversations -> envelope with items[], page, page_size, total_items, "
     "has_more; check pagination with ?page=1&page_size=2. GET /v1/chat/conversations/conv-004 -> detail. "
     "GET an UNKNOWN id -> 404 + error envelope. POST /v1/chat/conversations to start a 1:1 (needs a valid "
     "contact id from GET /v1/chat/contacts) and a group; assert group validation (empty name / no members)."),
    ("qa-messages-core", "api", "swarm/chat-qa/findings_v3/qa-messages-core.sh",
     "Messages core: POST a text message to conv-003 -> 201/200 with type=text, status=sent. GET messages "
     "lists it; verify newest handling, total_items increments, and ?page_size= pagination has_more. Send a "
     "message with reply_to_id set to an existing message id and assert reply_to_preview/reply_to_sender come "
     "back populated. Assert EMPTY/whitespace text is rejected (4xx, not 500). Try a 5k-char body and emoji/RTL text."),
    ("qa-message-ops", "api", "swarm/chat-qa/findings_v3/qa-message-ops.sh",
     "Message ops on a freshly-sent message in conv-002: PATCH edit text -> edited_at set and text changed; "
     "editing a DELETED message -> rejected. DELETE (soft) -> is_deleted true and text cleared. POST .../pin -> "
     "is_pinned toggles true then false on a second call. Confirm a deleted message can't be edited and that "
     "pin survives a subsequent GET."),
    ("qa-reactions", "api", "swarm/chat-qa/findings_v3/qa-reactions.sh",
     "Reactions on a sent message in conv-001: POST .../reactions {emoji:'\\U0001F44D'} -> reactions[] has it with "
     "count=1, by_me=true. POST same emoji again -> toggled OFF (removed or count 0). Add two different emojis -> "
     "both present. Have a SECOND officer (different token) add the SAME emoji -> count increments and reflects "
     "by_me correctly per viewer."),
    ("qa-forward-search", "api", "swarm/chat-qa/findings_v3/qa-forward-search.sh",
     "Forward + search: POST .../{mid}/forward {to_conversation_id:'conv-004'} -> new message in conv-004 with "
     "is_forwarded=true and forwarded_from set. Search: send a message containing 'ZEBRA-TOKEN', then GET "
     "messages?q=zebra -> case-insensitive match returns it; q for a missing term -> empty; ensure a soft-DELETED "
     "message does NOT appear in search results."),
    ("qa-identity", "api", "swarm/chat-qa/findings_v3/qa-identity.sh",
     "PER-USER IDENTITY (critical new feature): officer A (sgt.aitken) and officer B (const.brown) each log in. "
     "A sends a message to conv-004. GET as A -> that message from_me=true. GET as B -> SAME message id from_me=false. "
     "Then B sends a reply; GET as B -> from_me=true, GET as A -> from_me=false. Verify a SEEDED message keeps its "
     "fixed from_me regardless of viewer, and that GET /v1/chat/conversations last_message.from_me is also viewer-relative."),
    ("qa-uploads", "api", "swarm/chat-qa/findings_v3/qa-uploads.sh",
     "Uploads + attachments: POST multipart to /v1/chat/uploads (a small temp file you create) -> returns url, "
     "name, size_bytes, mime_type. Then POST a message with an attachment object + type=image to a conversation "
     "and assert the attachment echoes back on GET. Try a zero-byte/no-file upload -> graceful 4xx, not 500."),
    ("qa-security", "api", "swarm/chat-qa/findings_v3/qa-security.sh",
     "Security/negative: CORS preflight (OPTIONS with Origin: http://localhost:5000) returns "
     "Access-Control-Allow-Origin. Malformed JSON body -> 400 with {message,error,request_id} envelope, not 500. "
     "Unknown conversation/message ids -> 404 envelope. Inject script/SQL-ish payloads in message text "
     "(<script>, '; DROP TABLE) -> stored/returned verbatim and safe (no 500, no execution). Very long URL/headers. "
     "Note whether chat endpoints require auth at all (RequireBearer) and report the security posture."),

    ("qa-models", "flutter", "test/chat_qa/models_test.dart",
     "Test the chat models: ChatMessage.fromJson/toJson round-trip INCLUDING the new fields (type, attachment, "
     "reply*, reactions, edited_at, is_deleted, is_pinned, forward*, ttl_seconds); fromJson tolerates missing "
     "optionals; copyWith preserves untouched fields and overrides given ones; the preview getter returns the "
     "right string per MessageType (voice/image/file/text/deleted). Also MessageReaction, ChatAttachment.readableSize, "
     "and MessageType wire mapping round-trip."),
    ("qa-controller", "flutter", "test/chat_qa/controller_test.dart",
     "Test ChatThreadController (construct with a seeded ChatConversation, no repository): sendText appends an "
     "outbound msg and throws on empty; beginReply then sendText carries reply_to fields; toggleReaction adds then "
     "removes; applyEdit sets editedAt+text and clears editing; deleteMessage sets isDeleted+clears text; togglePin "
     "flips pinnedMessage; setDisappearing makes new messages inherit ttlSeconds; search returns matching indices; "
     "markMyMessagesRead promotes outbound to read. Assert notifyListeners fires (add a listener counter)."),
    ("qa-repository", "flutter", "test/chat_qa/repository_test.dart",
     "Test repositories. InMemoryChatRepository: conversations() sorted, startConversation dedupes, the new "
     "messagesFor/editMessage/deleteMessage/togglePin/toggleReaction/searchMessages behave. HttpChatRepository: "
     "inject a package:http/testing.dart MockClient and assert it issues the correct method+path+body for "
     "sendMessage, editMessage, toggleReaction, messagesFor, and parses snake_case responses into models. "
     "Assert auth header is attached when a token provider is set."),
    ("qa-auth-session", "flutter", "test/chat_qa/auth_session_test.dart",
     "Test the auth layer: AuthSession.fromJson maps token/display_name/username/rank/station; Session.store/clear "
     "and currentAccessToken() reflect state and implement TokenProvider; HttpAuthService with a MockClient returns "
     "an AuthSession on 200 and throws AuthException on 401/network error and stores the token in Session on success. "
     "Verify ChatGate shows LdapLoginScreen when session.current is null (pump it)."),
    ("qa-widgets", "flutter", "test/chat_qa/widgets_test.dart",
     "Widget tests — pump each in a MaterialApp and assert it renders without throwing and reflects inputs: "
     "ReactionChips (shows emoji+count, highlights byMe), ReadReceiptTicks (sent/delivered/read variants), "
     "TypingIndicator (shows name), DeletedMessageBubble, EditedTag, PinnedMessageBanner (renders the pinned "
     "preview and returns shrink when controller has no pin), DisappearingBadge. Use the real widget constructors "
     "(read each file for the signature)."),
    ("qa-flow", "flutter", "test/chat_qa/flow_test.dart",
     "Higher-level widget tests: MessageBubble dispatches to the right child per MessageType (text vs voice vs image "
     "vs file vs deleted) — verify by finding the expected child widget/text. Pump ChatThreadScreen with a seeded "
     "conversation (no repository) and verify the composer send appends a bubble. Keep it deterministic (no real "
     "network/timers leaking — pump and settle, cancel)."),
]

VALID_IDS = {s[0] for s in SLICES}


def build_prompt(slice_):
    sid, kind, suite, task = slice_
    howto = (API_HOWTO if kind == "api" else FLUTTER_HOWTO).replace("{SUITE}", str(REPO / suite))
    shared = SHARED.replace("{{ID}}", sid)
    return f"""{shared}

--- YOUR SLICE: {sid} ({kind}) ---
You OWN exactly one file: {REPO / suite}
{howto}

Test scope:
{task}

Write the suite, RUN it, read the real output, and report the verdict block for id={sid}."""


def run_one(slice_):
    sid = slice_[0]
    prompt = build_prompt(slice_)
    log_path = FINDINGS / f"{sid}.log"
    started = time.time()
    try:
        with open(log_path, "w") as log:
            proc = subprocess.run(
                ["claude", "-p", prompt, "--dangerously-skip-permissions", "--model", MODEL],
                cwd=str(REPO), stdout=log, stderr=subprocess.STDOUT, text=True,
                timeout=PER_WORKER_TIMEOUT,
            )
        rc = proc.returncode
    except subprocess.TimeoutExpired:
        rc = -1
    elapsed = int(time.time() - started)
    verdict = parse_verdict(log_path)
    print(f"[{'ok' if rc == 0 else 'ERR':>3}] {sid:<18} {elapsed:>4}s  {verdict}", flush=True)
    return sid, rc, verdict


def parse_verdict(log_path):
    try:
        text = log_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return {"pass": 0, "fail": 0, "blocked": 0, "raw": "no log"}
    m = re.search(r"QA-VERDICT\s+id=\S+\s+PASS=(\d+)\s+FAIL=(\d+)\s+BLOCKED=(\d+)", text)
    if not m:
        return {"pass": 0, "fail": 0, "blocked": 0, "raw": "no verdict line"}
    return {"pass": int(m.group(1)), "fail": int(m.group(2)), "blocked": int(m.group(3)), "raw": ""}


def write_report(results):
    report = HERE / "REPORT_v3.md"
    total_pass = sum(v["pass"] for _, _, v in results)
    total_fail = sum(v["fail"] for _, _, v in results)
    total_block = sum(v["blocked"] for _, _, v in results)
    lines = ["# Chat System QA — v3 (live test execution)\n",
             f"_15 `claude -p` QA workers · model {MODEL} · API {API}_\n",
             f"\n## Totals: {total_pass} PASS · {total_fail} FAIL · {total_block} BLOCKED\n",
             "\n| Slice | Pass | Fail | Blocked | Log |\n|---|---|---|---|---|"]
    for sid, _, v in sorted(results):
        flag = " ⚠️" if v["fail"] else ""
        lines.append(f"| {sid}{flag} | {v['pass']} | {v['fail']} | {v['blocked']} | findings_v3/{sid}.log |")
    lines.append("\n## Bugs reported\n")
    for sid, _, v in sorted(results):
        try:
            text = (FINDINGS / f"{sid}.log").read_text(errors="replace")
            bugs = text.split("BUGS:", 1)[1].strip() if "BUGS:" in text else "(no bugs block)"
        except Exception:
            bugs = "(log unreadable)"
        lines.append(f"### {sid}\n{bugs[:1500]}\n")
    report.write_text("\n".join(lines), encoding="utf-8")
    print(f"\nReport: {report}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    selected = [s for s in SLICES if not args or s[0] in args]

    if "--dry-run" in flags:
        for s in selected:
            print("=" * 80, f"\n# {s[0]} ({s[1]})\n", build_prompt(s))
        return

    print(f"QA swarm v3: {len(selected)} workers (model={MODEL}, concurrency={MAX_CONCURRENT})")
    print(f"Findings: {FINDINGS}\n")
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_CONCURRENT) as pool:
        futures = [pool.submit(run_one, s) for s in selected]
        for f in concurrent.futures.as_completed(futures):
            results.append(f.result())
    write_report(results)
    fails = sum(v["fail"] for _, _, v in results)
    print(f"\nDone. {sum(v['pass'] for _,_,v in results)} pass / {fails} fail across {len(results)} workers.")


if __name__ == "__main__":
    main()

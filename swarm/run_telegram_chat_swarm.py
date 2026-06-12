#!/usr/bin/env python3
"""15-agent swarm: upgrade the JCF Document Hub chat to Telegram-grade messaging
with LDAP-backed login.

Fans out headless `claude -p` workers. Each worker owns a DISJOINT set of files
(see SLICES) so the agents do not collide. The shared data model + the
ChatThreadController seam are already built (foundation); workers build against
them. Two workers touch the .NET API (LDAP auth + chat backend); the other 13
build Flutter features and the login flow.

Usage:
  python3 run_telegram_chat_swarm.py            # run all 15
  python3 run_telegram_chat_swarm.py --dry-run  # print prompts only
  python3 run_telegram_chat_swarm.py reactions-ui ldap-login   # run a subset
  SWARM_CONCURRENCY=4 SWARM_MODEL=opus python3 run_telegram_chat_swarm.py
"""

import concurrent.futures
import os
import subprocess
import sys
import time

FLUTTER = os.path.expanduser("~/projects/Document-Hub-Flutter-")
API = os.path.expanduser("~/projects/document-hub-api")
SWARM = os.path.join(FLUTTER, "swarm")
LOG_DIR = os.path.join(SWARM, "logs", "telegram-chat")
CONVENTIONS = os.path.join(SWARM, "TELEGRAM_CHAT_CONVENTIONS.md")

MAX_CONCURRENT = int(os.environ.get("SWARM_CONCURRENCY", "4"))
MODEL = os.environ.get("SWARM_MODEL", "sonnet")

# Each slice: id, repo ('flutter'|'api'), the working dir, the files it OWNS,
# and the task spec. Ownership is disjoint by construction.
SLICES = [
    # --- .NET API (2) -----------------------------------------------------
    {
        "id": "api-ldap-auth", "repo": "api", "cwd": API,
        "owns": [
            "src/DocumentHub.Domain/Auth/*",
            "src/DocumentHub.Application/Auth/*",
            "src/DocumentHub.Infrastructure/Auth/*",
            "src/DocumentHub.Presentation/Controllers/AuthController.cs",
            "src/DocumentHub.Presentation/Contracts/AuthContracts.cs",
        ],
        "task": (
            "Build a NEW self-contained 'Auth' vertical slice that signs officers in against "
            "JCF Active Directory over LDAP, mirroring the existing slice layout (Domain + "
            "Application + Infrastructure + Controller + Contracts) and the IFeatureModule "
            "auto-wiring pattern used by the other slices (read one existing *FeatureModule.cs "
            "and FeatureModuleRegistration.cs first).\n"
            "Endpoints:\n"
            "  POST /v1/auth/login  {username,password} -> {token, display_name, username, rank?, station?}\n"
            "  GET  /v1/auth/me     (bearer) -> the current principal\n"
            "LDAP bind: use System.DirectoryServices.Protocols.LdapConnection with config-driven "
            "Host/Port/BaseDn/UserDnFormat from appsettings 'Ldap' section. Bind as "
            "`{username}@internal.jcf.gov.jm` style per UserDnFormat. On success issue a bearer "
            "token via the SAME mechanism the existing BearerAuthenticationMiddleware validates "
            "(read src/DocumentHub.Presentation/Authentication/* to match it).\n"
            "IMPORTANT: add an `Ldap:Enabled` toggle (default false). When false, accept any "
            "non-empty username/password and synthesize a principal — so the app runs locally "
            "without a domain controller. NEVER hardcode real credentials; appsettings carries "
            "placeholders only. Wrap LdapException and translate bind failures to a clean 401 "
            "(log the real reason server-side). Apply Clean Code; build with `dotnet build`."
        ),
    },
    {
        "id": "api-chat-extend", "repo": "api", "cwd": API,
        "owns": [
            "src/DocumentHub.Domain/Chat/* (extend)",
            "src/DocumentHub.Application/Chat/* (extend)",
            "src/DocumentHub.Infrastructure/Chat/* (extend)",
            "src/DocumentHub.Presentation/Controllers/ChatController.cs (extend)",
            "src/DocumentHub.Presentation/Contracts/ChatContracts.cs (extend)",
        ],
        "task": (
            "You OWN the entire Chat slice extension — no other agent touches it, so make all "
            "Chat changes coherently in one pass. Read the existing Chat slice end to end first "
            "(Domain/Chat, Application/Chat, Infrastructure/Chat, ChatController, ChatContracts).\n"
            "Extend the ChatMessage domain entity + its contract DTO to carry the Telegram fields "
            "the Flutter ChatMessage already serializes (read "
            "~/projects/Document-Hub-Flutter-/lib/models/chat/chat_message.dart and chat_attachment.dart "
            "and message_reaction.dart for the exact snake_case wire shape): type, attachment, "
            "reply_to_id/preview/sender, reactions[], edited_at, is_deleted, is_pinned, "
            "is_forwarded, forwarded_from, ttl_seconds.\n"
            "Add endpoints (all under the existing /v1/chat):\n"
            "  POST   .../conversations/{cid}/messages            (extend: accept reply_to_id, type, attachment, ttl_seconds)\n"
            "  PATCH  .../conversations/{cid}/messages/{mid}       (edit text -> sets edited_at)\n"
            "  DELETE .../conversations/{cid}/messages/{mid}       (soft delete -> is_deleted)\n"
            "  POST   .../conversations/{cid}/messages/{mid}/pin   (toggle is_pinned)\n"
            "  POST   .../conversations/{cid}/messages/{mid}/forward {to_conversation_id}\n"
            "  POST   .../conversations/{cid}/messages/{mid}/reactions {emoji}   (toggle for caller)\n"
            "  POST   .../conversations/{cid}/messages/{mid}/read   (read receipt)\n"
            "  POST   .../conversations/{cid}/typing               (typing ping)\n"
            "  GET    .../conversations/{cid}/messages?q=           (in-thread text search)\n"
            "  POST   /v1/chat/uploads (multipart) -> {url,name,size_bytes,mime_type,duration_ms?,width?,height?}\n"
            "Keep the in-memory store; persist reactions/edits/pins there. Apply Clean Code; "
            "build with `dotnet build`."
        ),
    },

    # --- Flutter auth + data wiring (2) -----------------------------------
    {
        "id": "ldap-login", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/screens/auth/ldap_login_screen.dart",
            "lib/services/auth/auth_service.dart",
            "lib/services/auth/http_auth_service.dart",
            "lib/services/auth/session.dart",
        ],
        "task": (
            "Build the LDAP-backed login for the app. Create:\n"
            "  - auth_service.dart: an abstract AuthService { Future<AuthSession> signIn(String username, String password); "
            "Future<void> signOut(); AuthSession? get current; } plus an AuthSession value type "
            "(token, displayName, username, rank?, station?). No null returns — throw AuthException on failure.\n"
            "  - http_auth_service.dart: implementation calling POST /v1/auth/login on the API "
            "(reuse lib/services/api/api_config.dart for the base URL and the token plumbing in "
            "lib/services/api/token_provider.dart). On success store the token via Session.\n"
            "  - session.dart: a Session holder (singleton-ish via provided instance) that keeps the "
            "current AuthSession in memory and exposes the bearer token to the api client.\n"
            "  - ldap_login_screen.dart: a polished JCF sign-in screen (username + password, show/hide, "
            "loading state, inline error on AuthException). Style with the existing NamStyle theme "
            "(read lib/screens/email/email_login_screen.dart for the look to match, but this is the "
            "REAL one). On success it should Navigator.pushReplacement to the app's home; expose an "
            "onSignedIn callback so the integrator wires the destination. Add a // INTEGRATION: note "
            "saying this screen should replace the email-login stub as the chat entry gate. "
            "flutter analyze your files clean."
        ),
    },
    {
        "id": "chat-repo-wiring", "repo": "flutter", "cwd": FLUTTER,
        "owns": ["lib/services/chat/chat_repository.dart (extend)"],
        "task": (
            "You OWN chat_repository.dart. Read it fully first (it has an abstract ChatRepository, an "
            "InMemoryChatRepository, and an HTTP repository). Extend the abstract ChatRepository "
            "contract with new methods for the Telegram features, giving each a default "
            "implementation that throws UnsupportedError so existing impls still compile:\n"
            "  editMessage(convId, msgId, newText), deleteMessage(convId, msgId), "
            "togglePin(convId, msgId), toggleReaction(convId, msgId, emoji), "
            "forwardMessage(fromConvId, msgId, toConvId), sendAttachment(convId, attachment, type, text), "
            "uploadAttachment(bytes/path) -> ChatAttachment, searchMessages(convId, query), "
            "sendTyping(convId), markMessageRead(convId, msgId).\n"
            "Then implement all of them in the HTTP repository against the endpoints the "
            "api-chat-extend slice exposes (see TELEGRAM_CHAT_CONVENTIONS wire contract). For the "
            "InMemoryChatRepository, give correct local implementations that mutate the seeded data "
            "(so the app is fully functional offline). Do NOT touch any other file. Keep Clean Code; "
            "flutter analyze clean."
        ),
    },

    # --- Flutter chat feature widgets (11) --------------------------------
    {
        "id": "reply-quote", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/reply_compose_bar.dart",
            "lib/widgets/chat/quoted_reply.dart",
            "lib/widgets/chat/swipe_to_reply.dart",
        ],
        "task": (
            "Telegram-style REPLY. Build: (1) SwipeToReply — a gesture wrapper around a message "
            "bubble that reveals a reply arrow on horizontal drag and calls controller.beginReply(msg) "
            "on release; (2) ReplyComposeBar — the little quoted bar that sits above the text input "
            "when controller.replyingTo != null, showing the quoted sender + preview with an X to "
            "controller.clearCompose(); (3) QuotedReply — the inset quoted snippet rendered INSIDE a "
            "bubble for messages that have replyToPreview, tappable to jump to the original "
            "(expose an onJumpTo(messageId) callback). All take a ChatThreadController. INTEGRATION "
            "note for each. flutter analyze clean."
        ),
    },
    {
        "id": "forward", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/forward_sheet.dart",
            "lib/widgets/chat/forwarded_tag.dart",
        ],
        "task": (
            "Telegram-style FORWARD. Build: (1) ForwardSheet — a bottom sheet listing the user's "
            "conversations (take a List<ChatConversation> and a ChatMessage to forward); on pick it "
            "calls controller.forwardIn or returns the chosen conversation id via a callback; include "
            "a search field to filter the list. (2) ForwardedTag — the small 'Forwarded from <name>' "
            "header shown at the top of a forwarded bubble (reads msg.isForwarded / forwardedFrom). "
            "INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "reactions-ui", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/reaction_picker.dart",
            "lib/widgets/chat/reaction_chips.dart",
        ],
        "task": (
            "Telegram-style REACTIONS. Build: (1) ReactionPicker — a floating rounded bar of quick "
            "emojis (👍 ❤️ 😂 😮 😢 🙏 ✅) that appears on long-press of a bubble; picking one calls "
            "controller.toggleReaction(msgId, emoji) and dismisses. Animate it in (scale/fade). "
            "(2) ReactionChips — the row of emoji+count chips rendered under a bubble from "
            "msg.reactions, highlighting chips where byMe is true; tapping a chip toggles it. Use a "
            "showReactionPicker(context, ...) helper using an OverlayEntry positioned near the bubble. "
            "INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "voice-notes", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/services/chat/voice_recorder.dart",
            "lib/widgets/chat/voice_record_button.dart",
            "lib/widgets/chat/voice_message_bubble.dart",
        ],
        "task": (
            "Telegram-style VOICE NOTES. Build: (1) voice_recorder.dart — an abstract VoiceRecorder "
            "{ Future<void> start(); Future<ChatAttachment> stop(); Future<void> cancel(); } plus a "
            "StubVoiceRecorder that simulates a recording (synthesizes a ChatAttachment with a fake "
            "url, durationMs, and a generated waveform list) so the app compiles with NO native "
            "plugin. Note the real package ('record') in an INTEGRATION comment. (2) VoiceRecordButton "
            "— a mic button that, held down, shows a recording UI (elapsed timer, slide-to-cancel) and "
            "on release calls controller.sendAttachment(att, type: MessageType.voice). (3) "
            "VoiceMessageBubble — renders a voice message: play/pause button, a waveform painted from "
            "attachment.waveform (CustomPainter), and duration; playback can be simulated progress. "
            "INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "media-images", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/services/chat/image_attachment_picker.dart",
            "lib/widgets/chat/image_message_bubble.dart",
            "lib/widgets/chat/photo_viewer_screen.dart",
        ],
        "task": (
            "Telegram-style PHOTOS. Build: (1) image_attachment_picker.dart — an abstract "
            "ImageAttachmentPicker { Future<ChatAttachment?> pickFromGallery(); Future<ChatAttachment?> "
            "captureFromCamera(); } plus a StubImageAttachmentPicker returning a sample remote image "
            "ChatAttachment (with width/height) so it compiles without image_picker; note the real "
            "package in INTEGRATION. (2) ImageMessageBubble — renders an image message with rounded "
            "corners sized from attachment.width/height, a caption from msg.text, and tap-to-open. "
            "(3) PhotoViewerScreen — fullscreen viewer with pinch-zoom (InteractiveViewer), swipe to "
            "dismiss, and a caption bar. INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "files-docs", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/services/chat/file_attachment_picker.dart",
            "lib/widgets/chat/file_message_bubble.dart",
            "lib/widgets/chat/attachment_menu.dart",
        ],
        "task": (
            "Telegram-style FILES + the attach menu. Build: (1) file_attachment_picker.dart — abstract "
            "FileAttachmentPicker { Future<ChatAttachment?> pickFile(); } + a stub returning a sample "
            "ChatAttachment (name, sizeBytes, mimeType) so it compiles without file_picker; note the "
            "package in INTEGRATION. (2) FileMessageBubble — a document bubble: type icon by mimeType, "
            "name, readableSize, and a download/open affordance. (3) AttachmentMenu — the '+' / paperclip "
            "popup the composer opens, offering Photo / Camera / File / Location options as a grid; it "
            "takes callbacks (onPhoto, onCamera, onFile, onLocation) so the integrator wires the "
            "pickers. INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "edit-delete", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/message_actions_sheet.dart",
            "lib/widgets/chat/edited_tag.dart",
            "lib/widgets/chat/deleted_message_bubble.dart",
        ],
        "task": (
            "Telegram-style EDIT/DELETE + the long-press action menu. Build: (1) MessageActionsSheet "
            "— a context menu (bottom sheet or popup) shown on long-press offering Reply, Copy, "
            "Forward, Edit (own messages only), Delete (own only), Pin, React; it takes a ChatMessage "
            "+ ChatThreadController + callbacks (onReply, onForward, onReact) and directly calls "
            "controller.beginEdit / deleteMessage / togglePin for the ones it owns. For Edit, show an "
            "inline edit flow: put the message text into the composer via controller.beginEdit, and "
            "the integrator commits with controller.applyEdit. (2) EditedTag — a tiny 'edited' label "
            "shown on bubbles where editedAt != null. (3) DeletedMessageBubble — the italic tombstone "
            "shown when msg.isDeleted ('🚫 This message was deleted'). INTEGRATION notes. flutter "
            "analyze clean."
        ),
    },
    {
        "id": "pin-messages", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/pinned_message_banner.dart",
        ],
        "task": (
            "Telegram-style PINNED MESSAGES. Build PinnedMessageBanner — the slim banner pinned under "
            "the app bar showing controller.pinnedMessage (a vertical accent bar, 'Pinned message' "
            "label, and the message preview). Tapping it calls an onJumpTo(messageId) callback to "
            "scroll to the original; an X unpins via controller.togglePin. It listens to the "
            "ChatThreadController so it appears/updates/disappears as messages are pinned/unpinned. "
            "Returns an empty SizedBox.shrink() when nothing is pinned (no null). INTEGRATION note: "
            "place directly under the AppBar in chat_thread_screen. flutter analyze clean."
        ),
    },
    {
        "id": "typing-presence", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/typing_indicator.dart",
            "lib/widgets/chat/presence_subtitle.dart",
            "lib/widgets/chat/read_receipt_ticks.dart",
        ],
        "task": (
            "Telegram-style TYPING + PRESENCE + READ RECEIPTS. Build: (1) TypingIndicator — the "
            "animated three-bouncing-dots widget with an optional name ('Sgt Reid is typing…'); "
            "drive the animation with an AnimationController. (2) PresenceSubtitle — the app-bar "
            "subtitle that shows 'online' / 'last seen <relative time>' / 'typing…' from a ChatContact "
            "(reads isOnline + lastSeen; format last-seen relative). (3) ReadReceiptTicks — the "
            "single/double/blue-double tick widget from a MessageStatus (sent/delivered/read), only "
            "for outbound messages. Pure presentational widgets (take their data in). INTEGRATION "
            "notes. flutter analyze clean."
        ),
    },
    {
        "id": "in-chat-search", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/in_chat_search_bar.dart",
            "lib/widgets/chat/highlighted_text.dart",
        ],
        "task": (
            "Telegram-style IN-CHAT SEARCH. Build: (1) InChatSearchBar — an app-bar search field that "
            "queries controller.search(query), shows 'n of m' match count, and up/down arrows to step "
            "through hits, emitting onJumpTo(messageIndex) so the thread scrolls to and flashes the "
            "matched bubble. Open/close as an overlay over the normal app bar. (2) HighlightedText — a "
            "Text replacement that yellow-highlights the matched substring within a message bubble for "
            "the active query (RichText/TextSpan). INTEGRATION notes. flutter analyze clean."
        ),
    },
    {
        "id": "disappearing", "repo": "flutter", "cwd": FLUTTER,
        "owns": [
            "lib/widgets/chat/disappearing_timer_menu.dart",
            "lib/widgets/chat/disappearing_badge.dart",
            "lib/services/chat/disappearing_sweeper.dart",
        ],
        "task": (
            "Telegram-style DISAPPEARING (self-destruct) messages. Build: (1) DisappearingTimerMenu — "
            "a menu (off / 30s / 5m / 1h / 1d) that calls controller.setDisappearing(ttlSeconds) and "
            "shows the current selection; new messages then inherit ttlSeconds (already handled by the "
            "controller). (2) DisappearingBadge — a small flame/clock badge + live countdown shown on "
            "a bubble whose msg.ttlSeconds != null, computed from sentAt + ttl. (3) "
            "disappearing_sweeper.dart — a DisappearingSweeper that, given a ChatThreadController, runs "
            "a periodic Timer and removes (or tombstones via controller.deleteMessage) messages whose "
            "ttl has elapsed; expose start()/stop(). INTEGRATION notes. flutter analyze clean."
        ),
    },
]

PROMPT_TEMPLATE = """You are a senior engineer and ONE worker in a 15-agent swarm. \
First read the shared conventions file IN FULL: {conventions}

Your slice id: {slice_id}   (repo: {repo})
Work ONLY in: {cwd}

Files you OWN (create/edit ONLY these — touch nothing else):
{owns}

Your task:
{task}

Before writing, read the foundation files named in the conventions so you build against \
the real ChatMessage / ChatThreadController APIs. {ref_hint}

Constraints recap: own only your files; no edits to chat_thread_screen.dart / chat_message.dart \
(unless you own it); reuse ChatStyle tokens; Clean Code; no AI attribution; finish with a green \
{verify} over the files you touched. End with a short summary of files written, the public \
widget/class names with constructor signatures, and your `// INTEGRATION:` note(s) verbatim."""


def build_prompt(slice_):
    owns = "\n".join(f"  - {f}" for f in slice_["owns"])
    is_flutter = slice_["repo"] == "flutter"
    ref_hint = (
        "Consult swarm/reference/ (DrKLO/Telegram) for interaction fidelity."
        if is_flutter else
        "Read one existing API slice + the BearerAuthentication* files to match patterns."
    )
    verify = "`flutter analyze`" if is_flutter else "`dotnet build`"
    return PROMPT_TEMPLATE.format(
        conventions=CONVENTIONS,
        slice_id=slice_["id"],
        repo=slice_["repo"],
        cwd=slice_["cwd"],
        owns=owns,
        task=slice_["task"],
        ref_hint=ref_hint,
        verify=verify,
    )


def run_one(slice_):
    prompt = build_prompt(slice_)
    log_path = os.path.join(LOG_DIR, f"{slice_['id']}.log")
    started = time.time()
    with open(log_path, "w") as log:
        proc = subprocess.run(
            ["claude", "-p", prompt,
             "--dangerously-skip-permissions",
             "--model", MODEL],
            cwd=slice_["cwd"],
            stdout=log, stderr=subprocess.STDOUT,
            text=True,
        )
    elapsed = int(time.time() - started)
    status = "ok" if proc.returncode == 0 else f"FAIL({proc.returncode})"
    print(f"[{status:>9}] {slice_['id']:<18} {elapsed:>4}s  -> {log_path}", flush=True)
    return slice_["id"], proc.returncode


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a for a in sys.argv[1:] if a.startswith("--")}
    selected = [s for s in SLICES if not args or s["id"] in args]

    os.makedirs(LOG_DIR, exist_ok=True)

    if "--dry-run" in flags:
        for s in selected:
            print("=" * 80)
            print(f"# SLICE: {s['id']}  ({s['repo']})")
            print(build_prompt(s))
        print(f"\n{len(selected)} slice(s). Logs would go to {LOG_DIR}")
        return

    print(f"Launching {len(selected)} agents  (model={MODEL}, concurrency={MAX_CONCURRENT})")
    print(f"Logs: {LOG_DIR}\n")
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_CONCURRENT) as pool:
        futures = [pool.submit(run_one, s) for s in selected]
        for f in concurrent.futures.as_completed(futures):
            results.append(f.result())

    failed = [sid for sid, rc in results if rc != 0]
    print("\n" + "=" * 60)
    print(f"Done: {len(results) - len(failed)}/{len(results)} ok")
    if failed:
        print("FAILED: " + ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()

# Chat System QA — v3 (live test execution)

_15 `claude -p` QA workers · model sonnet · API http://localhost:5070_


## Totals: 270 PASS · 36 FAIL · 2 BLOCKED


| Slice | Pass | Fail | Blocked | Log |
|---|---|---|---|---|
| qa-auth ⚠️ | 19 | 4 | 0 | findings_v3/qa-auth.log |
| qa-auth-session | 0 | 0 | 0 | findings_v3/qa-auth-session.log |
| qa-controller | 0 | 0 | 0 | findings_v3/qa-controller.log |
| qa-conversations ⚠️ | 36 | 3 | 0 | findings_v3/qa-conversations.log |
| qa-flow | 0 | 0 | 0 | findings_v3/qa-flow.log |
| qa-forward-search ⚠️ | 18 | 2 | 0 | findings_v3/qa-forward-search.log |
| qa-identity ⚠️ | 14 | 6 | 0 | findings_v3/qa-identity.log |
| qa-message-ops ⚠️ | 19 | 4 | 0 | findings_v3/qa-message-ops.log |
| qa-messages-core ⚠️ | 36 | 6 | 0 | findings_v3/qa-messages-core.log |
| qa-models | 91 | 0 | 0 | findings_v3/qa-models.log |
| qa-reactions ⚠️ | 14 | 6 | 0 | findings_v3/qa-reactions.log |
| qa-repository | 0 | 0 | 0 | findings_v3/qa-repository.log |
| qa-security | 0 | 0 | 0 | findings_v3/qa-security.log |
| qa-uploads ⚠️ | 23 | 5 | 2 | findings_v3/qa-uploads.log |
| qa-widgets | 0 | 0 | 0 | findings_v3/qa-widgets.log |

## Bugs reported

### qa-auth
- [SEV: HIGH] Empty username accepted → 200 + token issued | POST /v1/auth/login | expected 400/422/401 (no token), got 200 with token=65e0fa4e8d8b41999276b675761c5151 and username=""
- [SEV: HIGH] Empty username token issuance | POST /v1/auth/login | expected no token for empty username, got valid token that authenticates as the empty-string user
- [SEV: HIGH] Empty password accepted → 200 + token issued | POST /v1/auth/login | expected 400/422/401 (no token), got 200 with token for qa_officer2 — password field not validated
- [SEV: HIGH] Empty password token issuance | POST /v1/auth/login | expected no token for empty password, got valid token=2e965b6a6b55449c8e7c74058f4f3a04
```

### qa-auth-session
(no bugs block)

### qa-controller
(no bugs block)

### qa-conversations
- [SEV: HIGH] No auth enforcement on /v1/chat/conversations | GET /v1/chat/conversations (no token) | expected: HTTP 401 | got: HTTP 200 — unauthenticated callers can read all conversations
- [SEV: HIGH] Invalid bearer token not rejected on /v1/chat/conversations | GET /v1/chat/conversations (bad token) | expected: HTTP 401 | got: HTTP 200 — any garbage token grants full read access
- [SEV: MED] Group conversation creation not supported via POST /v1/chat/conversations | POST /v1/chat/conversations {"name":"...","member_ids":[...]} | expected: HTTP 201 with group conversation | got: HTTP 400 VALIDATION_FAILED "ContactId field is required" — no route exists to create group conversations; seed group conv-003 was inserted directly, not via API
```

### qa-flow
(no bugs block)

### qa-forward-search
- [SEV: HIGH] Unauthenticated forward accepted (HTTP 200, creates message) | POST /v1/chat/conversations/{cid}/messages/{mid}/forward | expected 401, got 200
- [SEV: MED] forwarded_from field is always "Unknown" (no sender attribution) | POST /v1/chat/conversations/{cid}/messages/{mid}/forward response | expected forwarded_from=<original sender username/display_name>, got "Unknown"
```

### qa-identity
- [SEV: MED] Seeded message msg-009 returns from_me=true for ALL viewers; sender identity not stored | GET /v1/chat/conversations/conv-004/messages | exactly one user should see from_me=true, other false
- [SEV: MED] Seeded message msg-010 returns same from_me=false for both viewers | GET /v1/chat/conversations/conv-004/messages | expected opposite values since it has a different sender than msg-009
- [SEV: HIGH] Legacy forwarded message 0d13a76d returns from_me=true for ALL viewers; sender identity lost | GET /v1/chat/conversations/conv-004/messages | one user must see false; both returned true
- [SEV: HIGH] Legacy forwarded message 04f5108e returns from_me=true for ALL viewers; sender identity lost | GET /v1/chat/conversations/conv-004/messages | one user must see false; both returned true
- [SEV: HIGH] Legacy forwarded message 773bb3d6 returns from_me=true for ALL viewers; sender identity lost | GET /v1/chat/conversations/conv-004/messages | one user must see false; both returned true
- [SEV: HIGH] Unauthenticated messages endpoint returned 200 instead of 401 | GET /v1/chat/conversations/conv-004/messages | expected 401
```
ctly one sender — one must be false

--- 9. Unauthenticated access returns 401 ---
FAIL: unauth-messages-401 expected=401 got=200 | GET /v1/chat/conversations/conv-004/messages | missing auth must return 401

==============================
TOTAL: PASS=14 FAIL=6 BLOCKED=0
==============================

QA-VERDICT id=qa-identity PASS=14 FAIL=6 BLOCKED=0


### qa-message-ops
- [SEV: HIGH] Auth middleware missing on mutation endpoints — PATCH/DELETE/PIN accept no token or garbage token and return HTTP 200 | PATCH|DELETE /v1/chat/conversations/conv-002/messages/{id} | expected 401, got 200 with mutation applied (anonymous client edited seed msg-004 text successfully)
- [SEV: MED] Soft delete does not clear message text | DELETE /v1/chat/conversations/conv-002/messages/{id} + GET /v1/chat/conversations/conv-002/messages | expected text='' or null after is_deleted=true, got original text preserved in both DELETE response and messages list
```

### qa-messages-core
**

- **[SEV: HIGH]** Auth middleware not enforced — requests without bearer token and with invalid tokens return 200/201 | `GET+POST /v1/chat/conversations/{id}/messages` | Expected 401; got 200 (unauthenticated reads and writes succeed — full auth bypass)

- **[SEV: HIGH]** `reply_to_sender` not reader-relative for cross-user reply | `POST /v1/chat/conversations/{id}/messages` + `GET` | Beta replies to Alpha's message; Beta should see `reply_to_sender=<Alpha's name>` but gets `'You'` — the field is incorrectly computed relative to the message sender rather than the requesting reader

- **[SEV: MED]** `sender_name=null` for dynamically-created API users in non-`from_me` message view | `GET /v1/chat/conversations/{id}/messages` | Expected `sender_name=<display_name>` got `null`; only hardcoded seed-data users (Yolanda Brown, Carlton Reid, etc.) have `sender_name` populated

- **[SEV: MED]** `reply_to_id` referencing a non-existent message silently accepted with 201, `reply_to_preview` null | `POST /v1/chat/conversations/{id}/messages` | Expected 400/404 or a populated preview; got 201 with dangling `reply_to_id` and no preview (orphaned reply stored in DB)

### qa-models
none
```

### qa-reactions
- [SEV: HIGH] Multi-user same-emoji reaction destroys existing reaction instead of incrementing count | POST /v1/chat/conversations/conv-001/messages/{id}/reactions | expected count=2 by_me per-viewer; got reactions=[] (officer1's reaction silently deleted when officer2 adds same emoji) — root cause: ChatService.ToggleEmoji has no per-user ownership tracking
- [SEV: HIGH] Reaction endpoint accepts requests with no Authorization header (HTTP 200, reaction recorded) | POST /v1/chat/conversations/{convId}/messages/{msgId}/reactions | expected 401; got 200 with reaction applied as anonymous user
- [SEV: MED] Toggle-remove returns by_me=true instead of false after removing own reaction | POST /v1/chat/conversations/{convId}/messages/{msgId}/reactions | expected by_me=false after second officer removes their emoji; got by_me=true
```

### qa-repository
(no bugs block)

### qa-security
(no bugs block)

### qa-uploads
- [SEV: HIGH] /v1/chat/uploads accepts file uploads with no auth token — returns HTTP 200 | POST /v1/chat/uploads (no Authorization header) | expected: 401 or 403 / got: 200
- [SEV: HIGH] /v1/chat/uploads accepts file uploads with an invalid/garbage bearer token — returns HTTP 200 | POST /v1/chat/uploads -H "Authorization: Bearer deadbeef..." | expected: 401 or 403 / got: 200
- [SEV: MED] Uploaded file URLs are not served — GET on the URL returned by the upload endpoint returns 404 | GET /v1/chat/uploads/{id} | expected: 200 with file bytes / got: 404 (endpoint does not exist for GET)
- [SEV: LOW] TC-08e/TC-08f reported as FAIL/BLOCKED due to test harness pagination gap (conv-003 accumulated 64 messages across runs; message confirmed present on page 2) — not a system bug
```
e without attachment does not 500 (got 201)

=== TC-12: Upload same file twice — both succeed with distinct URLs ===
PASS: TC-12a both duplicate uploads succeed
PASS: TC-12b duplicate uploads get distinct URLs

=== TC-13: Upload by different user — both get unique URLs ===
PASS: TC-13a uploads from two different users both succeed
PASS: TC-13b uploads from two users get distinct URLs

=== TC-14: Non-multipart POST to /v1/chat/uploads → 4xx ===
PASS: TC-14a JSON body (non-multipart) to uploads returns 4xx (got 415)

=== TC-15: Attachment from_me perspective — TOKEN_B reads TOKEN_A's message ===
BLOCKED: TC-15a from_me cross-user check — message not visible to TOKEN_B's conversations

━━━━━━━━━━━━━━━━━━━━━━

### qa-widgets
(no bugs block)

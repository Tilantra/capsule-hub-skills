---
name: capsule-save
description: Create a new Capsule Hub capsule from the current conversation or provided content. Optionally attach local files. Use when you want to persist a conversation, decision, or piece of knowledge as a new capsule.
argument-hint: [--tag <tag>] [--team <team_id>] [--attach <file_path> ...]
allowed-tools: Bash
---

!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** If content scope is ambiguous, confirm with user before saving.

**Header shortcuts used below:**
- `[AUTH]` = `-H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"`

## Phase 1 — Upload attachments (skip if no `--attach`)

MIME map: `.py→text/x-python` `.js→text/javascript` `.ts→text/typescript` `.go→text/x-go` `.rs→text/x-rust` `.java→text/x-java` `.c→text/x-c` `.cpp→text/x-c++` `.cs→text/x-csharp` `.rb→text/x-ruby` `.swift→text/x-swift` `.kt→text/x-kotlin` `.html→text/html` `.css→text/css` `.json→application/json` `.yaml/.yml→text/yaml` `.xml→text/xml` `.md→text/markdown` `.sql→text/x-sql` `.csv→text/csv` `.sh→text/x-sh` `.txt→text/plain` `.pdf→application/pdf` `.png→image/png` `.jpg/.jpeg→image/jpeg` `.gif→image/gif` `.webp→image/webp`

```bash
B64=$(base64 < "FILEPATH") && curl -s -X POST "$CAPSULE_API_BASE/capsules/attachments" \
  [AUTH] -d "{\"base64_data\":\"$B64\",\"filename\":\"FILENAME\",\"content_type\":\"MIME_TYPE\"}"
```
Collect each returned `asset_id`. On `403`: inform user their tier does not allow attachments.

## Phase 2 — Create the capsule

Build `messages` array from conversation: `[{"role":"user"|"assistant"|"system","content":"..."}]`

```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/" [AUTH] -d '{
  "tag": TAG_OR_NULL, "team": TEAM_OR_NULL, "extracted_from": "claude-code",
  "attachment_ids": [ASSET_IDS_OR_EMPTY],
  "content": {"messages": MESSAGES_ARRAY, "attachments": [], "metadata": {}}
}'
```

On success display:
```
Capsule created.
  ID:      <capsule_id>
  Version: <version_id>
  Summary: <summary>
```

Errors: `401` re-login | `403` capsule limit or attachments not allowed | `400` show error detail

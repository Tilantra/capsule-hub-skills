---
name: capsule-version
description: Mutate an existing capsule. Supports adding a new version, rolling back, renaming the tag, changing the team, deleting an attachment, or deleting the entire capsule. Use /capsule-read first to inspect what you're modifying.
argument-hint: <capsule_id> [--new-version] [--rollback <version_id>] [--tag <new_tag>] [--team <team_id>] [--rm-attachment <asset_id>] [--delete] [--attach <file_path> ...]
allowed-tools: Bash
---

## Auth state
!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`

**Stop immediately if AUTH is missing.**
The first positional argument is always the `capsule_id`.

---

## Operations

### `--new-version` — Add a new version

Follows the same two-phase flow as `/capsule-save`.

**Phase 1 — Upload new attachments** (only if `--attach` is also provided):

For each file, base64-encode and upload:
```bash
B64=$(base64 < "FILEPATH") && \
curl -s -X POST "$CAPSULE_API_BASE/capsules/attachments" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d "{\"base64_data\":\"$B64\",\"filename\":\"FILENAME\",\"content_type\":\"MIME_TYPE\"}"
```
Collect returned `asset_id` values.

**Phase 2 — Create the version:**
```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/CAPSULE_ID/versions" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{
    "extracted_from": "claude-code",
    "attachment_ids": [ASSET_IDS_ARRAY],
    "content": {
      "messages": MESSAGES_ARRAY,
      "attachments": [],
      "metadata": {}
    }
  }'
```

Display: `New version <version_id> created. Parent: <parent_version_id>.`
Note: the response contains `capsule_id`, `version_id`, `content_hash`, `parent_version_id`, and `extracted_from` — it does NOT include `version_number`.

---

### `--rollback <version_id>` — Roll back to a prior version

```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/CAPSULE_ID/rollback" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{"version_id": "TARGET_VERSION_ID"}'
```

Display: rollback confirmation with new active version number and summary.

---

### `--tag <new_tag>` — Rename the capsule tag

```bash
curl -s -X PUT "$CAPSULE_API_BASE/capsules/CAPSULE_ID/tag" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{"tag": "NEW_TAG"}'
```

Display: `Tag updated to "<new_tag>".`

---

### `--team <team_id>` — Share capsule with a team

**Note:** This is a one-way operation. A private capsule can be moved to a team, but cannot be reassigned to a different team afterwards.

```bash
curl -s -X PUT "$CAPSULE_API_BASE/capsules/CAPSULE_ID/team" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{"team": "TEAM_ID"}'
```

Display: `Capsule shared with team <team_id>.`

---

### `--rm-attachment <asset_id>` — Remove an attachment

```bash
curl -s -X DELETE "$CAPSULE_API_BASE/capsules/CAPSULE_ID/attachments/ASSET_ID" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

Display: `Attachment <asset_id> removed.`

---

### `--delete` — Delete the entire capsule

**Before running**, confirm with the user: "This will permanently delete capsule `<capsule_id>` and all its versions. Type 'yes' to confirm."

Only proceed if the user confirms.

```bash
curl -s -X DELETE "$CAPSULE_API_BASE/capsules/CAPSULE_ID" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

Display: `Capsule <capsule_id> and all versions deleted.`

---

## Error handling
- `401` → token expired — run `/capsule-login`
- `403` → tier restriction (e.g., cannot version a capsule created by a higher-tier user)
- `404` → capsule or version not found, or no access
- `400` with "already has a team" → capsule already belongs to a team; team reassignment is not allowed

---
name: capsule-version
description: Mutate an existing capsule. Supports adding a new version, rolling back, renaming the tag, changing the team, deleting an attachment, or deleting the entire capsule. Use /capsule-read first to inspect what you're modifying.
argument-hint: <capsule_id> [--new-version] [--rollback <version_id>] [--tag <new_tag>] [--team <team_id>] [--rm-attachment <asset_id>] [--delete] [--attach <file_path> ...]
allowed-tools: Bash
---

!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** First positional arg is always `capsule_id`.

**Header shortcuts used below:**
- `[AUTH]` = `-H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"`
- `[CT]` = `-H "Content-Type: application/json"` (add for POST/PUT)

---

### `--new-version`

**Phase 1** (only if `--attach`): Upload each file (MIME map same as `/capsule-save`):
```bash
B64=$(base64 < "FILEPATH") && curl -s -X POST "$CAPSULE_API_BASE/capsules/attachments" \
  [AUTH] [CT] -d "{\"base64_data\":\"$B64\",\"filename\":\"FILENAME\",\"content_type\":\"MIME_TYPE\"}"
```
Collect `asset_id` values.

**Phase 2**: Create version:
```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/CAPSULE_ID/versions" [AUTH] [CT] -d '{
  "extracted_from":"claude-code","attachment_ids":[ASSET_IDS_OR_EMPTY],
  "content":{"messages":MESSAGES_ARRAY,"attachments":[],"metadata":{}}
}'
```
Display: `New version <version_id> created. Parent: <parent_version_id>.`
Response fields: `capsule_id`, `version_id`, `content_hash`, `parent_version_id`, `extracted_from` — no `version_number`.

---

### `--rollback <version_id>`
```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/CAPSULE_ID/rollback" [AUTH] [CT] -d '{"version_id":"TARGET_VERSION_ID"}'
```
Display rollback confirmation with new active version.

### `--tag <new_tag>`
```bash
curl -s -X PUT "$CAPSULE_API_BASE/capsules/CAPSULE_ID/tag" [AUTH] [CT] -d '{"tag":"NEW_TAG"}'
```
Display: `Tag updated to "<new_tag>".`

### `--team <team_id>`
One-way only — private→team, no reassignment afterwards.
```bash
curl -s -X PUT "$CAPSULE_API_BASE/capsules/CAPSULE_ID/team" [AUTH] [CT] -d '{"team":"TEAM_ID"}'
```
Display: `Capsule shared with team <team_id>.`

### `--rm-attachment <asset_id>`
```bash
curl -s -X DELETE "$CAPSULE_API_BASE/capsules/CAPSULE_ID/attachments/ASSET_ID" [AUTH]
```
Display: `Attachment <asset_id> removed.`

### `--delete`
Confirm first: "This will permanently delete capsule `<capsule_id>` and all its versions. Type 'yes' to confirm." Only proceed on confirmation.
```bash
curl -s -X DELETE "$CAPSULE_API_BASE/capsules/CAPSULE_ID" [AUTH]
```
Display: `Capsule <capsule_id> and all versions deleted.`

---

Errors: `401` re-login | `403` tier restriction | `404` not found | `400` "already has a team" → no reassignment

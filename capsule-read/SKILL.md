---
name: capsule-read
description: Read a capsule's metadata, version history, or full message content. Can also fetch and decode attachment file content (code, images, PDFs). Use /capsule-search first if you don't have a capsule ID.
argument-hint: <capsule_id> [--versions] [--version <version_id|latest>] [--attachments] [--attachment <asset_id>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.**

**Header shortcuts used below:**
- `[AUTH]` = `-H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"`

## Modes

| Arg | Endpoint | Display |
|---|---|---|
| (none) | `GET /capsules/CAPSULE_ID` | tag, summary, created_by, team, version_count, attachment_count, latest_version_id, attachments list |
| `--versions` | `GET /capsules/CAPSULE_ID/versions` | Response shape: `{"capsule_id":…,"versions":[…]}` — iterate `response["versions"]`. Show version_number, version_id, created_at, summary, change_summary |
| `--version <id>` | `GET /capsules/CAPSULE_ID/versions/VERSION_ID` | Show `content.messages` (role/content list), summary, change_summary |
| `--version latest` | Fetch metadata first → use `latest_version_id` as VERSION_ID → same as above | — |
| `--attachments` | `GET /capsules/CAPSULE_ID/attachments` | asset_id, filename, media_type, size_bytes, uploaded_at |
| `--attachment <id>` | `GET /capsules/attachments/ASSET_ID` | See attachment handler below |

All commands use `curl -s "ENDPOINT" [AUTH]`

## Attachment handler

Pipe the `--attachment` curl response into this unified handler:

```bash
python3 -c "
import base64, json, sys, os
d = json.load(sys.stdin)
mt = d.get('media_type', '')
data = base64.b64decode(d['base64_data'])
ext = os.path.splitext(d.get('filename','file'))[1] or '.bin'
if mt == 'image':
    path = '/tmp/capsule_attachment' + ext
    open(path, 'wb').write(data)
    print('SAVED_TO:' + path)
    print('CAPTION:' + (d.get('vision_caption') or '(no caption)'))
    print('OCR:' + (d.get('vision_ocr_text') or '(no OCR)'))
elif mt in ('pdf','word_document','powerpoint','spreadsheet'):
    path = '/tmp/capsule_attachment' + ext
    open(path, 'wb').write(data)
    print('SAVED_TO:' + path)
else:
    print(data.decode('utf-8','replace'))
"
```

- **image**: Use the Read tool on `SAVED_TO` path to display. Show CAPTION and OCR.
- **pdf/office**: Use the Read tool on `SAVED_TO` path.
- **text/code**: Output is printed directly — display in a code block with appropriate language syntax.

Errors: `401` re-login | `404` capsule/version not found

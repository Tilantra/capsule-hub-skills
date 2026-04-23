---
name: capsule-read
description: Read a capsule's metadata, version history, or full message content. Can also fetch and decode attachment file content (code, images, PDFs). Use /capsule-search first if you don't have a capsule ID.
argument-hint: <capsule_id> [--versions] [--version <version_id>] [--attachments] [--attachment <asset_id>]
allowed-tools: Bash
---

## Auth state
!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`

**Stop immediately if AUTH is missing.**

---

## Modes

| Arguments | What it does |
|---|---|
| `<capsule_id>` only | Capsule metadata + attachment list |
| `--versions` | All versions with summaries and change notes |
| `--version <id>` | Full message content of a specific version |
| `--version latest` | Full message content of the latest version |
| `--attachments` | List all attachment metadata for the capsule |
| `--attachment <asset_id>` | Fetch and decode one attachment's content |

---

## Commands

**Capsule metadata** (replace CAPSULE_ID):
```bash
curl -s "$CAPSULE_API_BASE/capsules/CAPSULE_ID" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```
Display: tag, summary, created_by, team, version_count, attachment_count, latest_version_id, extracted_from, and the list of attachments with their asset_id, filename, and media_type.

**List versions:**
```bash
curl -s "$CAPSULE_API_BASE/capsules/CAPSULE_ID/versions" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```
Response shape: `{"capsule_id": "...", "versions": [...]}` — iterate over `response["versions"]`, not the top-level object.
Display each version: version_number, version_id, created_at, created_by, summary, change_summary.

**Get version content:**

If the user says `--version latest`, first fetch capsule metadata to get `latest_version_id`, then use that as VERSION_ID.

```bash
curl -s "$CAPSULE_API_BASE/capsules/CAPSULE_ID/versions/VERSION_ID" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```
The response contains `content.messages` — a list of `{role, content}` objects. Display the full conversation. Also show `summary` and `change_summary` for context.

**List attachments:**
```bash
curl -s "$CAPSULE_API_BASE/capsules/CAPSULE_ID/attachments" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```
Display: asset_id, filename, media_type, size_bytes, uploaded_at for each.

**Fetch attachment content** (replace ASSET_ID):
```bash
curl -s "$CAPSULE_API_BASE/capsules/attachments/ASSET_ID" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

The response is `MediaAssetMetadata` containing `base64_data` (the file content, already decrypted by the server). Handle by `media_type`:

- **Code/text types** (`python`, `javascript`, `typescript`, `go`, `rust`, `java`, `c`, `cpp`, `csharp`, `swift`, `kotlin`, `php`, `ruby`, `html`, `css`, `json`, `yaml`, `xml`, `markdown`, `sql`, `csv`, `shell`, `batch`, `text`, `log`):
  Decode the base64 field and display the file content as a code block with appropriate language syntax.
  ```bash
  python3 -c "import base64,json,sys; d=json.load(sys.stdin); print(base64.b64decode(d['base64_data']).decode('utf-8','replace'))"
  ```
  Pipe the curl output into this.

- **Images** (`image`):
  Display the vision metadata if present: `vision_caption`, `vision_ocr_text`, `vision_dense_caption`, `vision_status`.
  Decode base64 to a temp file and read it so Claude Code can render it:
  ```bash
  python3 -c "
  import base64, json, sys, tempfile, os
  d = json.load(sys.stdin)
  ext = os.path.splitext(d.get('filename','img'))[1] or '.png'
  path = '/tmp/capsule_attachment' + ext
  with open(path, 'wb') as f:
      f.write(base64.b64decode(d['base64_data']))
  print('SAVED_TO:' + path)
  print('CAPTION:' + (d.get('vision_caption') or '(no caption)'))
  print('OCR:' + (d.get('vision_ocr_text') or '(no OCR)'))
  "
  ```
  Read the saved file path using the Read tool to display the image.

- **PDF / office docs** (`pdf`, `word_document`, `powerpoint`, `spreadsheet`):
  Decode to a temp file and read it with the Read tool:
  ```bash
  python3 -c "
  import base64, json, sys, os
  d = json.load(sys.stdin)
  ext = os.path.splitext(d.get('filename','doc'))[1] or '.pdf'
  path = '/tmp/capsule_attachment' + ext
  with open(path, 'wb') as f:
      f.write(base64.b64decode(d['base64_data']))
  print('SAVED_TO:' + path)
  "
  ```
  Then use the Read tool on the saved path.

---

**Error handling:**
- `401` → token expired — run `/capsule-login`
- `404` → capsule or version not found, or no access

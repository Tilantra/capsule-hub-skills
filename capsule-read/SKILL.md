---
name: capsule-read
description: Read a capsule's metadata, version history, or full message content. Use /capsule-search first if you don't have a capsule ID.
argument-hint: <capsule_id> [--versions] [--version <version_id|latest>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_api_key ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.**

All scripts share this helper — include it at the top of every Python block below:

```python
import json, os, sys, urllib.request, urllib.error

def mcp(tool, **args):
    base = os.environ.get("CAPSULE_API_BASE","https://backend.tilantra.com").rstrip("/")
    key  = open(os.path.expanduser("~/.capsule_api_key")).read().strip()
    req  = urllib.request.Request(
        base + "/mcp/",
        data=json.dumps({"jsonrpc":"2.0","id":"1","method":"tools/call",
                         "params":{"name":tool,"arguments":args}}).encode(),
        headers={"Content-Type":"application/json","Accept":"application/json","X-API-Key":key,
                 "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as r:
            rpc = json.loads(r.read())
    except urllib.error.HTTPError as e:
        print("STATUS:http_error_" + str(e.code)); sys.exit(1)
    if "error" in rpc:
        print("STATUS:error"); print(str(rpc["error"])); sys.exit(1)
    result = json.loads(rpc["result"]["content"][0]["text"])
    if "error" in result:
        print("STATUS:error"); print(result["error"]); sys.exit(1)
    return result
```

---

## (no flag) — capsule metadata

Replace `REPLACE_CAPSULE_ID` and run:

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
c = mcp("get_capsule", capsule_id=capsule_id)
print(f'ID:       {c["capsule_id"]}')
print(f'Tag:      {c.get("tag") or "(none)"}')
print(f'Summary:  {c.get("summary") or "(none)"}')
print(f'Created:  {c.get("created_at","?")} by {c.get("created_by","?")}')
print(f'Team:     {c.get("team") or "personal"}')
print(f'Versions: {c.get("version_count","?")}')
print(f'Latest:   {c.get("latest_version_id","?")}')
PYEOF
```

---

## `--versions` — version history

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
result = mcp("list_versions", capsule_id=capsule_id)
for v in result.get("versions", []):
    print(f'[{v["version_id"]}] created:{v.get("created_at","?")} by:{v.get("created_by","?")} parent:{v.get("parent_version_id","—")}')
print(f'\nTotal: {result.get("count","?")} version(s).')
PYEOF
```

---

## `--version <version_id>` — full message content

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
version_id = "REPLACE_VERSION_ID"
v = mcp("get_version", capsule_id=capsule_id, version_id=version_id)
print(f'Version:  {v["version_id"]}')
print(f'Created:  {v.get("created_at","?")} by {v.get("created_by","?")}')
print(f'Parent:   {v.get("parent_version_id","—")}')
print()
for msg in v.get("messages", []):
    print(f'[{msg["role"].upper()}]')
    print(msg["content"])
    print()
PYEOF
```

---

## `--version latest`

First call `get_capsule` to get `latest_version_id`, then call `get_version` with that ID — same output format as `--version <id>` above.

---

Errors: `http_error_401` → re-run `/capsule-login` | `error` → show message | `404` → capsule or version not found

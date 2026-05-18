---
name: capsule-version
description: Mutate an existing capsule. Supports adding a new version, renaming the tag, or sharing with a team. Use /capsule-read first to inspect what you're modifying.
argument-hint: <capsule_id> [--new-version] [--tag <new_tag>] [--team <team_id>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_api_key ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** First positional arg is always `capsule_id`.

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

### `--new-version`

Build `messages` from the conversation. Replace `REPLACE_CAPSULE_ID`, `REPLACE_MESSAGES` and run:

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
messages   = REPLACE_MESSAGES  # list of {"role":…,"content":…}

result = mcp("create_version", capsule_id=capsule_id, messages=messages)
print(f'New version {result["version_id"]} created.')
print(f'Parent: {result.get("parent_version_id","—")}')
PYEOF
```

---

### `--tag <new_tag>`

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
new_tag    = "REPLACE_TAG"

result = mcp("update_capsule_tag", capsule_id=capsule_id, new_tag=new_tag)
print(f'Tag updated to "{result["tag"]}".')
PYEOF
```

---

### `--team <team_id>`

One-way only — private → team. Cannot be reassigned afterwards.

```bash
python3 << 'PYEOF'
# [include helper above]
capsule_id = "REPLACE_CAPSULE_ID"
team_id    = "REPLACE_TEAM_ID"

result = mcp("update_capsule_team", capsule_id=capsule_id, team=team_id)
print(f'Capsule shared with team {result["team"]}.')
PYEOF
```

---

Errors: `http_error_401` → re-run `/capsule-login` | `http_error_403` → tier restriction | `error` → show message

> **Not supported:** `--rollback`, `--rm-attachment`, `--delete`, `--attach` — these require REST endpoints not yet available via API key auth.

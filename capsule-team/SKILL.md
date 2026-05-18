---
name: capsule-team
description: Manage Capsule Hub teams. Create a new team or add a member. Requires Elite or Enterprise tier. The team_id returned on creation is needed for --team flags in other skills.
argument-hint: --create <name> [--description <desc>] [--color <hex>] [--members <email,...>] | --add <email> --team <team_id>
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

### `--create <name>`

Optional: `--description`, `--color` (hex e.g. `#3B82F6`), `--members` (comma-separated emails → Python list).
Replace `REPLACE_NAME`, `REPLACE_DESC`, `REPLACE_COLOR`, `REPLACE_MEMBERS` and run:

```bash
python3 << 'PYEOF'
# [include helper above]
name        = "REPLACE_NAME"
description = REPLACE_DESC     # string or None
color_tag   = REPLACE_COLOR    # string or None
members     = REPLACE_MEMBERS  # list of email strings or []

args = {"name": name, "members": members, "color_tag": color_tag or ""}
if description: args["description"] = description

result = mcp("create_team", **args)
print(f'Team created.')
print(f'  ID:      {result["team_id"]}')
print(f'  Name:    {result["name"]}')
print(f'  Admin:   {result["admin_email"]}')
print(f'  Members: {", ".join(result.get("members", [])) or "(none)"}')
print()
print(f'Use this team_id with --team in /capsule-save, /capsule-version, and /capsule-search.')
PYEOF
```

On `error` containing "basic tier": inform user that members must be Pro tier or above.

---

### `--add <email> --team <team_id>`

```bash
python3 << 'PYEOF'
# [include helper above]
team_id      = "REPLACE_TEAM_ID"
member_email = "REPLACE_EMAIL"

result = mcp("add_team_member", team_id=team_id, member_email=member_email)
print(f'{member_email} added to team {result["team_id"]}.')
print(f'Members: {", ".join(result.get("members", []))}')
PYEOF
```

---

Errors: `http_error_401` → re-run `/capsule-login` | `http_error_403` → Elite/Enterprise required | `error` → show message

> **Not supported:** `--list`, `--delete` — these require REST endpoints not yet available via API key auth.

---
name: capsule-save
description: Create a new Capsule Hub capsule from the current conversation or provided content. Use when you want to persist a conversation, decision, or piece of knowledge as a new capsule.
argument-hint: [--tag <tag>] [--team <team_id>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_api_key ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** If content scope is ambiguous, confirm with user before saving.

Build `messages` from the conversation as a list of `{"role": "user"|"assistant"|"system", "content": "..."}` dicts. Replace `REPLACE_TAG`, `REPLACE_TEAM`, `REPLACE_MESSAGES` and run:

```bash
python3 << 'PYEOF'
import json, os, sys, urllib.request, urllib.error

tag      = REPLACE_TAG       # string or None
team     = REPLACE_TEAM      # string or None
messages = REPLACE_MESSAGES  # list of {"role":…,"content":…}

base = os.environ.get("CAPSULE_API_BASE","https://backend.tilantra.com").rstrip("/")
key  = open(os.path.expanduser("~/.capsule_api_key")).read().strip()

args = {"messages": messages}
if tag:  args["tag"]  = tag
if team: args["team"] = team

try:
    req = urllib.request.Request(
        base + "/mcp/",
        data=json.dumps({"jsonrpc":"2.0","id":"1","method":"tools/call",
                         "params":{"name":"create_capsule","arguments":args}}).encode(),
        headers={"Content-Type":"application/json","Accept":"application/json","X-API-Key":key,
                 "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
        method="POST"
    )
    with urllib.request.urlopen(req) as r:
        rpc = json.loads(r.read())
except urllib.error.HTTPError as e:
    print("STATUS:http_error_" + str(e.code)); sys.exit(1)
except Exception as e:
    print("STATUS:error"); print(str(e)); sys.exit(1)

if "error" in rpc:
    print("STATUS:error"); print(str(rpc["error"])); sys.exit(1)

result = json.loads(rpc["result"]["content"][0]["text"])
if "error" in result:
    print("STATUS:error"); print(result["error"]); sys.exit(1)

print("STATUS:ok")
print(f'ID:      {result["capsule_id"]}')
print(f'Version: {result["version_id"]}')
print(f'Summary: {result.get("summary","")}')
PYEOF
```

On `STATUS:ok` display:
```
Capsule created.
  ID:      <capsule_id>
  Version: <version_id>
  Summary: <summary>
```

Errors: `http_error_401` → re-run `/capsule-login` | `http_error_403` → capsule limit reached or tier restriction | `error` → show message

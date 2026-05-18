---
name: capsule-login
description: Authenticate with Capsule Hub. Run once — stores your API key permanently at ~/.capsule_api_key. Get your API key from capsulehub.tilantra.com → Profile → API Key. Works for Google and password accounts alike.
argument-hint: (no arguments needed)
allowed-tools: Bash
---

## Auth state
!`printf "CAPSULE_API_BASE: %s\nAPI key: %s\n" "${CAPSULE_API_BASE:-NOT SET}" "$([ -f ~/.capsule_api_key ] && echo 'already set' || echo 'missing')"`

If `CAPSULE_API_BASE` is `NOT SET`: tell user to add `export CAPSULE_API_BASE=https://backend.tilantra.com` to `~/.zshrc`, reload shell, then stop.

If API key is `already set`: ask to refresh or skip. Stop if skip.

## Step 1 — Prompt for API key

Tell the user: "Open **capsulehub.tilantra.com** → go to your Profile → click **Generate API Key** → copy the `cht-` key."

Then run:

```bash
python3 << 'PYEOF'
import subprocess, sys, os

r = subprocess.run(
    ["osascript",
     "-e", 'display dialog "Paste your Capsule Hub API key below.\n\nGet it from: capsulehub.tilantra.com → Profile → API Key" default answer "" buttons {"Cancel", "Save"} default button "Save"',
     "-e", "text returned of result"],
    capture_output=True, text=True
)
if r.returncode != 0: print("STATUS:cancelled"); sys.exit(0)
key = r.stdout.strip()
if not key: print("STATUS:empty"); sys.exit(1)
if not key.startswith("cht-"): print("STATUS:invalid_format"); sys.exit(1)
open(os.path.expanduser("~/.capsule_api_key"), "w").write(key)
print("STATUS:saved")
PYEOF
```

Handle:
- `STATUS:cancelled` → offer to retry
- `STATUS:empty` → "No key entered." — offer to retry
- `STATUS:invalid_format` → "That doesn't look like a Capsule Hub API key (should start with `cht-`)." — offer to retry
- `STATUS:saved` → proceed to Step 2

## Step 2 — Validate key

```bash
python3 << 'PYEOF'
import json, os, sys, urllib.request, urllib.error

base = os.environ.get("CAPSULE_API_BASE", "https://backend.tilantra.com").rstrip("/")
key  = open(os.path.expanduser("~/.capsule_api_key")).read().strip()

try:
    req = urllib.request.Request(
        base + "/mcp/",
        data=json.dumps({"jsonrpc":"2.0","id":"1","method":"tools/list","params":{}}).encode(),
        headers={"Content-Type":"application/json","Accept":"application/json","X-API-Key":key,
                 "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
        method="POST"
    )
    with urllib.request.urlopen(req) as r:
        rpc = json.loads(r.read())
    if "result" in rpc:
        print("STATUS:ok")
    else:
        print("STATUS:error"); print("DETAIL:" + json.dumps(rpc.get("error", {})))
except urllib.error.HTTPError as e:
    if e.code == 401:
        os.remove(os.path.expanduser("~/.capsule_api_key"))
    print("STATUS:http_error_" + str(e.code))
except Exception as e:
    print("STATUS:error"); print("DETAIL:" + str(e))
PYEOF
```

| Status | Action |
|---|---|
| `STATUS:ok` | "API key saved. You're all set — no need to run this again unless you regenerate your key." |
| `STATUS:http_error_401` | Key is invalid (file deleted) — offer to retry from Step 1 |
| `STATUS:error` | Show `DETAIL:` to user |

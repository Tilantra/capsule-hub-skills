---
name: capsule-search
description: Search and browse Capsule Hub. Use to discover capsules by keyword or tag. Returns capsule IDs and summaries — use /capsule-read to inspect one in detail.
argument-hint: [query] [--tag <tag>] [--limit <n>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_api_key ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** Default `--limit` is 20.

Parse args from the user's input:
- `query` → `summary_query` (free-text keywords, or `None`)
- `--tag <tag>` → `tag` (exact tag match, or `None`)
- `--limit <n>` → `limit` (default `20`)

Replace `REPLACE_QUERY`, `REPLACE_TAG`, `REPLACE_LIMIT` and run:

```bash
python3 << 'PYEOF'
import json, os, sys, urllib.request, urllib.error

summary_query = REPLACE_QUERY  # string or None
tag           = REPLACE_TAG    # string or None
limit         = REPLACE_LIMIT  # int, default 20

base = os.environ.get("CAPSULE_API_BASE","https://backend.tilantra.com").rstrip("/")
key  = open(os.path.expanduser("~/.capsule_api_key")).read().strip()

args = {"limit": limit, "offset": 0}
if summary_query: args["summary_query"] = summary_query
if tag:           args["tag"] = tag

try:
    req = urllib.request.Request(
        base + "/mcp/",
        data=json.dumps({"jsonrpc":"2.0","id":"1","method":"tools/call",
                         "params":{"name":"search_capsules","arguments":args}}).encode(),
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
    print("STATUS:error"); print(rpc["error"]); sys.exit(1)

result = json.loads(rpc["result"]["content"][0]["text"])
if "error" in result:
    print("STATUS:error"); print(result["error"]); sys.exit(1)

for c in result.get("results", []):
    tag_str  = c.get("tag") or "(no tag)"
    versions = c.get("version_count", "?")
    team_str = f' — team:{c["team"]}' if c.get("team") else ""
    print(f'[{c["capsule_id"]}] {tag_str} — v{versions}{team_str}')
    summary = (c.get("summary") or "")[:120]
    if summary: print(f'  {summary}')

total = result.get("total", 0)
print(f'\nTotal: {total} result(s). Use /capsule-read <id> to inspect one.')
PYEOF
```

Errors: `http_error_401` → re-run `/capsule-login` | `error` → show message

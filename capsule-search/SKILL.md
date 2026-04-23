---
name: capsule-search
description: Search and browse Capsule Hub. Use to discover capsules by keyword or tag, or list private/team/featured collections. Returns capsule IDs and summaries — use /capsule-read to inspect one in detail.
argument-hint: [query] [--tag <tag>] [--private] [--team <team_id>] [--featured] [--limit <n>]
allowed-tools: Bash
---

## Auth state
!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`

**Stop immediately if AUTH is missing.**

---

## Modes

Parse the user's arguments to pick the right mode. Default `--limit` is 20.

| Arguments | Endpoint |
|---|---|
| `--private` | `GET /capsules/private` |
| `--team <id>` | `GET /capsules/team/<id>` |
| `--featured` | `GET /capsules/featured` (no auth header needed) |
| plain text / `--tag` | `POST /capsules/search` |
| no arguments | `POST /capsules/search` with empty body |

---

## Commands

**Private capsules:**
```bash
curl -s "$CAPSULE_API_BASE/capsules/private?limit=LIMIT&offset=0" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

**Team capsules** (replace TEAM_ID):
```bash
curl -s "$CAPSULE_API_BASE/capsules/team/TEAM_ID?limit=LIMIT&offset=0" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

**Featured capsules:**
```bash
curl -s "$CAPSULE_API_BASE/capsules/featured?limit=LIMIT&offset=0" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

**Search** (replace values; set fields to `null` if not provided):
```bash
curl -s -X POST "$CAPSULE_API_BASE/capsules/search" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "Content-Type: application/json" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -d '{"summary_query": QUERY_OR_NULL, "tag": TAG_OR_NULL, "limit": LIMIT, "offset": 0}'
```

---

## Output format

Parse the JSON response. For each result in `results`, display:
```
[<capsule_id>] <tag or "(no tag)"> — v<version_count> — <attachment_count> attachment(s)
  <summary (first 120 chars)>
```

Then show: `Total: <total> result(s). Use /capsule-read <id> to inspect one.`

**Error handling:**
- `401` → token expired — tell user to run `/capsule-login`
- `403` → not a member of that team
- `404` → no results found

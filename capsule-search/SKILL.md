---
name: capsule-search
description: Search and browse Capsule Hub. Use to discover capsules by keyword or tag, or list private/team/featured collections. Returns capsule IDs and summaries — use /capsule-read to inspect one in detail.
argument-hint: [query] [--tag <tag>] [--private] [--team <team_id>] [--featured] [--limit <n>]
allowed-tools: Bash
---

!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.** Default `--limit` is 20.

**Header shortcuts used below:**
- `[AUTH]` = `-H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"`
- `[CT]` = `-H "Content-Type: application/json"` (add for POST)

## Endpoints

| Mode | curl |
|---|---|
| `--private` | `curl -s "$CAPSULE_API_BASE/capsules/private?limit=L&offset=0" [AUTH]` |
| `--team <id>` | `curl -s "$CAPSULE_API_BASE/capsules/team/ID?limit=L&offset=0" [AUTH]` |
| `--featured` | `curl -s "$CAPSULE_API_BASE/capsules/featured?limit=L&offset=0"` (no auth) |
| text / `--tag` / no args | `curl -s -X POST "$CAPSULE_API_BASE/capsules/search" [AUTH] [CT] -d '{"summary_query":Q_OR_NULL,"tag":T_OR_NULL,"limit":L,"offset":0}'` |

## Output
Per result in `results[]`:
```
[<capsule_id>] <tag or "(no tag)"> — v<version_count> — <attachment_count> attachment(s)
  <summary[:120]>
```
Footer: `Total: <total> result(s). Use /capsule-read <id> to inspect one.`

Errors: `401` re-login | `403` not a team member | `404` no results

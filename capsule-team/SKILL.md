---
name: capsule-team
description: Manage Capsule Hub teams. List teams, create a new team, add a member, or delete a team. Requires Elite or Enterprise tier for create/add. The team_id returned on creation is needed for --team flags in other skills.
argument-hint: --list | --create <name> [--description <desc>] [--color <hex>] [--members <email,...>] | --add <email> --team <team_id> | --delete <team_id>
allowed-tools: Bash
---

!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`
**Stop if AUTH missing.**

**Header shortcuts used below:**
- `[AUTH]` = `-H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"`
- `[CT]` = `-H "Content-Type: application/json"` (add for POST)

---

### `--list`
```bash
curl -s "$CAPSULE_API_BASE/teams/current-user" [AUTH]
```
Per team: `[<team_id>] <name> — admin: <admin_email> — <member_count> member(s)\n  <description or "(no description)">`

### `--create <name>`
Optional: `--description`, `--color` (hex e.g. `#3B82F6`), `--members` (comma-separated emails → JSON array).
```bash
curl -s -X POST "$CAPSULE_API_BASE/teams/" [AUTH] [CT] \
  -d '{"name":"NAME","description":DESC_OR_NULL,"members":ARRAY_OR_EMPTY,"color_tag":COLOR_OR_NULL}'
```
Display: `Team created.\n  ID: <team_id>\n  Name: <name>\n  Admin: <email>\n  Members: <list>\n\nUse this team_id with --team in /capsule-save, /capsule-version, and /capsule-search.`
On `403`/`400` for a member: inform user that member must be Pro tier or above.

### `--add <email> --team <team_id>`
```bash
curl -s -X POST "$CAPSULE_API_BASE/teams/TEAM_ID/members" [AUTH] [CT] -d '{"email":"MEMBER_EMAIL"}'
```
Display: `<email> added to team <team_id>.` and updated member list.

### `--delete <team_id>`
```bash
curl -s -X DELETE "$CAPSULE_API_BASE/teams/TEAM_ID" [AUTH]
```
Display: `Team <team_id> deleted.`

---

Errors: `401` re-login | `403` Elite/Enterprise required | `400` member on basic tier | `404` team not found

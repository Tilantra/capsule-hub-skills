---
name: capsule-team
description: Manage Capsule Hub teams. Create a new team or add a member to an existing team. Requires Elite or Enterprise tier. The team_id returned on creation is needed for --team flags in other skills.
argument-hint: --list | --create <name> [--description <desc>] [--color <hex>] [--members <email,...>] | --add <email> --team <team_id>
allowed-tools: Bash
---

## Auth state
!`[ -f ~/.capsule_session_jwt ] && echo "AUTH: ok" || echo "AUTH: missing — run /capsule-login first"`

**Stop immediately if AUTH is missing.**

---

## Operations

### `--list` — List all teams you belong to

```bash
curl -s "$CAPSULE_API_BASE/teams/current-user" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
```

For each team in the response array, display:
```
[<team_id>] <name> — admin: <admin_email> — <member_count> member(s)
  <description or "(no description)">
```

---

### `--create <name>` — Create a new team

Collect optional arguments: `--description`, `--color` (hex string e.g. `#3B82F6`), `--members` (comma-separated emails).

Build the JSON body. Set fields to `null` if not provided. For members, convert the comma-separated string to a JSON array.

```bash
curl -s -X POST "$CAPSULE_API_BASE/teams/" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "TEAM_NAME",
    "description": DESCRIPTION_OR_NULL,
    "members": MEMBERS_ARRAY_OR_EMPTY,
    "color_tag": COLOR_OR_NULL
  }'
```

On success, display:
```
Team created.
  ID:      <team_id>
  Name:    <name>
  Admin:   <admin_email>
  Members: <members list>

Use this team_id with --team in /capsule-save, /capsule-version, and /capsule-search.
```

If a member email returns a `403` or error about basic tier, inform the user that member must be on Pro tier or above to join a team.

---

### `--add <email> --team <team_id>` — Add a member

```bash
curl -s -X POST "$CAPSULE_API_BASE/teams/TEAM_ID/members" \
  -H "Authorization: Bearer $(cat ~/.capsule_session_jwt)" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{"email": "MEMBER_EMAIL"}'
```

Display: `<email> added to team <team_id>.` and the updated member list.

---

## Error handling
- `401` → token expired — run `/capsule-login`
- `403` → your tier (Elite/Enterprise required to create or manage teams)
- `400` → member is on basic tier and cannot join teams
- `404` → team not found

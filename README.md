# Capsule Hub — Claude Code Skills

Claude Code skills for [Capsule Hub](https://capsulehub.tilantra.com). Save, search, read, and manage your capsules directly from Claude Code without loading tool schemas into your context on every turn.

## Skills

| Skill | What it does |
|---|---|
| `/capsule-login` | Authenticate once per terminal session |
| `/capsule-search` | Browse and search capsules by keyword, tag, team, or filter |
| `/capsule-read` | Read capsule metadata, version history, messages, and attachments |
| `/capsule-save` | Create a new capsule from the current conversation, with optional file attachments |
| `/capsule-version` | Add a version, rollback, rename, share with team, or delete |
| `/capsule-team` | Create teams and add members |

## Requirements

- [Claude Code](https://claude.ai/code) installed
- A Capsule Hub account at [capsulehub.tilantra.com](https://capsulehub.tilantra.com)

## Installation

```bash
git clone https://github.com/Tilantra/capsule-hub-skills.git
cd capsule-hub-skills
chmod +x setup.sh
./setup.sh
```

`setup.sh` creates symlinks from `~/.claude/skills/` to this repo. Pull updates at any time with `git pull` — your symlinks pick up changes immediately.

## One-time configuration

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
export CAPSULE_API_BASE=https://backend.tilantra.com
```

Then reload: `source ~/.zshrc`

## Usage

Each new terminal session, log in once:
```
/capsule-login
```

Then use the other skills freely:
```
/capsule-search my project notes
/capsule-read <capsule_id> --version latest
/capsule-save --tag "auth refactor decisions"
/capsule-version <capsule_id> --new-version
```

The JWT token is stored in your shell session. It expires based on your account settings — run `/capsule-login` again if you get `401` errors.

## Updating

```bash
cd capsule-hub-skills
git pull
```

No re-running `setup.sh` needed — symlinks point to the live files.

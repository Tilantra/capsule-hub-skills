---
name: capsule-login
description: Authenticate with Capsule Hub. Run once per terminal session before any other capsule skill. Shows a native macOS password dialog (no terminal TTY needed), makes the login call, and stores the JWT for this session — fully automated, nothing to copy-paste.
argument-hint: (no arguments needed)
allowed-tools: Bash
---

## Auth state
!`printf "CAPSULE_API_BASE: %s\nCAPSULE_JWT_FILE: %s\n" "${CAPSULE_API_BASE:-NOT SET}" "$([ -f ~/.capsule_session_jwt ] && echo 'already set' || echo '')"`

---

**If `CAPSULE_API_BASE` is `NOT SET`**, stop and tell the user:
> Add `export CAPSULE_API_BASE=https://backend.tilantra.com` to your `~/.zshrc`, reload your shell, then run `/capsule-login` again.

**If `CAPSULE_JWT_FILE` shows `already set`**, ask if they want to refresh or skip. If skip, stop.

---

## Login steps

**1.** Ask the user for their Capsule Hub **email address**.

**2.** Once you have the email, substitute it for `REPLACE_EMAIL` and run the following Bash command. It will pop a native macOS password dialog — the user types their password there and clicks Login. Nothing appears in the chat.

```bash
python3 << 'PYEOF'
import json, os, subprocess, sys, urllib.request, urllib.error, datetime

email    = "REPLACE_EMAIL"
base_url = os.environ.get("CAPSULE_API_BASE", "https://backend.tilantra.com").rstrip("/")

r = subprocess.run(
    [
        "osascript",
        "-e", f'display dialog "Capsule Hub — enter password for {email}:" default answer "" with hidden answer buttons {{"Cancel", "Login"}} default button "Login"',
        "-e", "text returned of result"
    ],
    capture_output=True, text=True
)

if r.returncode != 0:
    print("STATUS:cancelled")
    sys.exit(0)

password = r.stdout.strip()
if not password:
    print("STATUS:empty_password")
    sys.exit(1)

body = json.dumps({"email": email, "password": password}).encode()

try:
    req = urllib.request.Request(
        base_url + "/users/login",
        data=body,
        headers={
            "Content-Type": "application/json",
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "en-US,en;q=0.9",
            "Origin": "https://tilantra.com",
            "Referer": "https://tilantra.com/",
        },
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        data   = json.loads(resp.read())
        exp_dt = datetime.datetime.fromtimestamp(data["exp"]).strftime("%Y-%m-%d %H:%M")
        open(os.path.expanduser("~/.capsule_session_jwt"), "w").write(data["token"])
        print("STATUS:ok")
        print("EXPIRES:" + exp_dt)
except urllib.error.HTTPError as e:
    print("STATUS:http_error_" + str(e.code))
    print("DETAIL:" + e.read().decode())
    sys.exit(1)
except Exception as e:
    print("STATUS:error")
    print("DETAIL:" + str(e))
    sys.exit(1)
PYEOF
```

**3.** Parse the output:

- `STATUS:ok` → tell the user: "Logged in. Session active until `<EXPIRES value>`. Run `/capsule-login` again if you ever get 401 errors."

- `STATUS:cancelled` → user clicked Cancel — offer to retry.

- `STATUS:http_error_401` → wrong password — offer to retry.

- `STATUS:http_error_429` → rate limited (5 attempts/min per IP) — wait a moment then retry.

- `STATUS:http_error_403` → request blocked (Cloudflare or account issue) — check network/VPN, then contact Capsule Hub support if it persists.

- `STATUS:error` with `DETAIL:` → unexpected error — show the detail to the user.

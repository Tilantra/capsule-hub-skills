---
name: capsule-login
description: Authenticate with Capsule Hub. Run once per terminal session before any other capsule skill. Shows a native macOS password dialog, makes the login call, and stores the JWT at ~/.capsule_session_jwt.
argument-hint: (no arguments needed)
allowed-tools: Bash
---

## Auth state
!`printf "CAPSULE_API_BASE: %s\nJWT: %s\n" "${CAPSULE_API_BASE:-NOT SET}" "$([ -f ~/.capsule_session_jwt ] && echo 'already set' || echo 'missing')"`

If `CAPSULE_API_BASE` is `NOT SET`: tell user to add `export CAPSULE_API_BASE=https://backend.tilantra.com` to `~/.zshrc`, reload shell, then stop.
If JWT is `already set`: ask to refresh or skip. Stop if skip.

**1.** Ask for the user's email. **2.** Replace `REPLACE_EMAIL` and run:

```bash
python3 << 'PYEOF'
import json, os, subprocess, sys, urllib.request, urllib.error, datetime

email    = "REPLACE_EMAIL"
base_url = os.environ.get("CAPSULE_API_BASE", "https://backend.tilantra.com").rstrip("/")

r = subprocess.run(
    ["osascript",
     "-e", f'display dialog "Capsule Hub — enter password for {email}:" default answer "" with hidden answer buttons {{"Cancel", "Login"}} default button "Login"',
     "-e", "text returned of result"],
    capture_output=True, text=True
)
if r.returncode != 0: print("STATUS:cancelled"); sys.exit(0)
password = r.stdout.strip()
if not password: print("STATUS:empty_password"); sys.exit(1)

try:
    req = urllib.request.Request(
        base_url + "/users/login",
        data=json.dumps({"email": email, "password": password}).encode(),
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
        data = json.loads(resp.read())
        open(os.path.expanduser("~/.capsule_session_jwt"), "w").write(data["token"])
        print("STATUS:ok")
        print("EXPIRES:" + datetime.datetime.fromtimestamp(data["exp"]).strftime("%Y-%m-%d %H:%M"))
except urllib.error.HTTPError as e:
    print("STATUS:http_error_" + str(e.code)); print("DETAIL:" + e.read().decode()); sys.exit(1)
except Exception as e:
    print("STATUS:error"); print("DETAIL:" + str(e)); sys.exit(1)
PYEOF
```

**3.** Handle output:

| Status | Action |
|---|---|
| `STATUS:ok` | "Logged in. Session active until `<EXPIRES>`." |
| `STATUS:cancelled` | Offer to retry |
| `STATUS:http_error_401` | Wrong password — offer to retry |
| `STATUS:http_error_429` | Rate limited — wait then retry |
| `STATUS:http_error_403` | Blocked (Cloudflare/account) — check VPN, contact support |
| `STATUS:error` | Show `DETAIL:` to user |

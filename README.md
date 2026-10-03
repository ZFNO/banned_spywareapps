# banned_spywareapps

Non-root **adb** toolkit that makes misbehaving / spyware-ish apps behave:
each app runs **only when you launch it** — no background execution, no
foreground service, no push notifications, no boot autostart — and can be
**force-stopped the instant you leave it**, so nothing lingers in the
background draining battery or phoning home.

No root required. Works on Android 9+.

## Layout

The tree mirrors the on-device path, anchored at the repo root:

```
0/data/com.banned_fuckers.apps/   ==   /data/local/tmp/com.banned_fuckers.apps
```

## Deploy to a phone

```bash
# 1. push the toolkit
adb push 0/data/com.banned_fuckers.apps /data/local/tmp/

# 2. apply every ban (or run a single ban_*.sh)
ADB="adb -s SERIAL" bash 0/data/com.banned_fuckers.apps/run_all.sh
```

`run_all.sh` re-tightens the folder to owner-only (`chmod -R go-rwx`) every
run, since git/push do not preserve file modes.

## What's inside

| Path | Purpose |
|------|---------|
| `run_all.sh` | applies every ban (Messenger is opt-in) |
| `applovin/` | HARD ban — adware / OPPO·realme AppHub |
| `instagram/` | Instagram + Threads |
| `meta/` | Facebook (katana); Messenger (orca) opt-in |
| `tiktok/` | TikTok Lite + kill-on-exit watchdog |
| `README.txt` | human overview of the toolkit |
| `ADDING_AN_APP.md` | how to add another app (for a human or an agent) |

## Permissions / safety

Scripts live under `/data/local/tmp/…` labelled `shell_data_file`, owned by
`shell:shell`. **Only an `adb shell` (or root) can run them** — no installable
app can (wrong uid *and* wrong SELinux domain, and `am`/`cmd`/`pm` require the
shell uid anyway). The archive keeps itself owner-only; git does not store
Unix modes, so `run_all.sh` re-applies them.

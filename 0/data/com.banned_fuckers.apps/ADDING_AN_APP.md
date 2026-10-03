# ADDING A NEW APP TO THE BAN LIST
_(for a human **or** an AI agent - read section 3 first, then follow the recipe)_

This folder neuters misbehaving apps on a **non-rooted** Android phone using
`adb`. One app = one folder. Every script is **host-side** (runs on the PC,
drives the phone over adb) except the optional *on-device watchdogs*.

--------------------------------------------------------------------------
## 0. TL;DR recipe
1. Find the package name:  `adb shell pm list packages | grep -i <name>`
2. `mkdir <shortname>/`
3. Copy the templates in **section 6** into
   `<shortname>/ban_<shortname>.sh` and `<shortname>/unban_<shortname>.sh`
4. Set the package: `PKG="com.pkg.name"` (one) or `PKGS="a b"` (many)
5. Add `<shortname>/ban_<shortname>.sh` to the `for` list in `run_all.sh`
6. Add a row to `BANNED_MANIFEST.txt` **and** to `README.txt`
7. `chmod -R go-rwx .` ; ensure **LF** line endings ; `bash -n` each script
8. Test it (section 5) and confirm it is idempotent (run it twice)

--------------------------------------------------------------------------
## 1. Layout
```
com.banned_fuckers.apps/
  run_all.sh              # applies every ban below, in order
  BANNED_MANIFEST.txt     # one-line-per-app index
  README.txt              # human overview
  ADDING_AN_APP.md        # <- this file
  <shortname>/
    ban_<shortname>.sh    # apply the ban
    unban_<shortname>.sh  # restore defaults
    <optional> kill_*.sh / watch_*.sh
  <app>_ban.log           # record of what was applied
```

--------------------------------------------------------------------------
## 2. What "ban" means here
The default is a **SOFT BAN = "runs only when I launch it"**:
  * no background execution, no foreground service, no wake locks
  * no push notifications (kills the "pull you back in" loop)
  * drops out of Doze whitelist, pinned to the `restricted` standby bucket
  * force-stopped now - nothing runs until you tap the icon
The app stays installed and fully usable when you open it.

A **HARD BAN** (disable the app outright) is only for adware - see
`applovin/ban_applovin.sh` for that pattern.

--------------------------------------------------------------------------
## 3. Conventions - MUST follow these or the archive fragments
* **Language**: `#!/usr/bin/env bash`, POSIX-friendly, **LF** endings.
* **adb handle**: always start with
      `ADB="${ADB:-adb}"`
  so callers can target a device: `ADB="adb -s SERIAL" bash ban_x.sh`
* **Package(s)**: overridable, so others on a different build can adapt:
      `P="${PKG:-com.default.pkg}"`      # single
      `PKGS="com.a com.b"`               # multiple
* **Best-effort helper** (never abort the whole run on one unsupported step):
      `shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }`
  Use `shr "..."` for every command. Only *printing* the skip is allowed to
  fail silently.
* **Not-installed guard** (skip cleanly, exit 0):
      `$ADB shell pm list packages 2>/dev/null | grep -q "package:$P" || { echo "  [skip] $P not installed"; exit 0; }`
* **Idempotent**: running it 2x, 10x must be safe and produce the same state.
* **Header banner** on every script: what it bans, the packages, the policy,
  portability notes, and a `Usage:` line (match the existing files).
* **Never assume root.** Everything must work for a plain `adb shell` (uid
  `shell`, 2000).

--------------------------------------------------------------------------
## 4. Ban levels (pick one)
| Level    | When                              | Extra steps beyond the soft ban |
|----------|-----------------------------------|---------------------------------|
| SOFT     | ex-social / time-sink (default)   | -                               |
| HARD     | adware / never wanted             | `pm disable-user --user 0 $P` (see applovin) |
| PUSH-OFF | keep the app, kill only its nags  | add `cmd appops set $P POST_NOTIFICATION ignore` |

Soft-ban building blocks (in order):
```
cmd appops set $P RUN_IN_BACKGROUND     deny
cmd appops set $P RUN_ANY_IN_BACKGROUND deny
cmd appops set $P WAKE_LOCK             deny
cmd appops set $P START_FOREGROUND      deny
cmd deviceidle whitelist -$P
am set-standby-bucket $P restricted
pm revoke $P android.permission.RECEIVE_BOOT_COMPLETED   # best-effort, may no-op
am force-stop $P
```

--------------------------------------------------------------------------
## 5. Verify (after running the ban)
```
ADB="adb -s SERIAL"
$ADB shell cmd appops get com.pkg.one RUN_IN_BACKGROUND   # expect: deny
$ADB shell cmd appops get com.pkg.one START_FOREGROUND    # expect: deny
$ADB shell am get-standby-bucket com.pkg.one              # expect: 45  (restricted)
$ADB shell ps -A -o ARGS | grep '[c]om.pkg.one'           # expect: no line = not running
```
Extra checks used during setup:
```
$ADB shell dumpsys jobscheduler | grep -A2 -i "$P"   # alarms/jobs cancelled?
$ADB shell dumpsys package $P | grep -m1 stopped=    # stopped=true after force-stop
```

--------------------------------------------------------------------------
## 6. Templates (copy-paste, then edit the marked lines)

### 6a. `<shortname>/ban_<shortname>.sh`
```bash
#!/usr/bin/env bash
# =============================================================
#  BAN: <App Name>
#  Packages: <com.pkg.one>  [/ <com.pkg.two>]
#  Policy  : runs ONLY when launched; no bg / fg-service / push.
#            Still launchable on tap.
#  Portable: Android 9+ ; every unsupported step is skipped.
#  Usage   : ./ban_<shortname>.sh
#            ADB="adb -s SERIAL" ./ban_<shortname>.sh
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.pkg.one}"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }

echo ">> banning $P"
if ! $ADB shell pm list packages 2>/dev/null | grep -q "package:$P"; then
  echo "  [skip] $P not installed on this phone"; exit 0
fi
for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
  shr "cmd appops set $P $op deny"
done
shr "cmd appops set $P POST_NOTIFICATION ignore"   # drop this line if you want pushes
shr "cmd deviceidle whitelist -$P"
shr "am set-standby-bucket $P restricted"
shr "pm revoke $P android.permission.RECEIVE_BOOT_COMPLETED"
shr "am force-stop $P"
echo ">> done. Tap to run; nothing runs until you do."
```

### 6b. `<shortname>/unban_<shortname>.sh`
```bash
#!/usr/bin/env bash
# UNBAN: <App Name> (restore default behavior). Best-effort, idempotent.
ADB="${ADB:-adb}"
P="${PKG:-com.pkg.one}"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }
echo ">> unbanning $P"
for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
  shr "cmd appops set $P $op allow"
done
shr "cmd appops set $P POST_NOTIFICATION allow"
shr "am set-standby-bucket $P active"
shr "cmd deviceidle whitelist +$P"
echo ">> done."
```

--------------------------------------------------------------------------
## 7. Optional: kill-on-exit watchdog ("nothing lingers after you exit")
`am force-stop` already kills the **whole package** (parent + all children).
To fire it automatically the moment the app leaves the foreground, use a
watchdog. Two flavours:

* **Host-side** (`watch_tiktok.sh`): needs the PC + adb cable. Simple, but
  only runs while you're tethered.
* **On-device** (`watch_tiktok_dev.sh`): pure `sh`, no adb, survives the adb
  session if started detached. Re-run after each reboot (not persistent).

On-device template:
```bash
#!/system/bin/sh
# Watchdog: force-stop $P the instant it leaves the foreground. Re-arm post-reboot.
P="com.pkg.one"                      # EDIT
seen=0
while true; do
  # NOTE: some ROMs use mResumedActivity, this one uses topResumedActivity.
  fg=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)
  case "$fg" in
    *$P*) seen=1 ;;
    "")   : ;;                        # dump failed -> do nothing this tick
    *)    [ "$seen" = 1 ] && { echo "$(date '+%H:%M:%S') left fg -> force-stop $P"; am force-stop $P; seen=0; } ;;
  esac
  sleep 3
done
```
Start detached:
```bash
adb shell "setsid sh /data/local/tmp/com.banned_fuckers.apps/<shortname>/watch_<shortname>_dev.sh \
  >/data/local/tmp/<shortname>_watch.log 2>&1 </dev/null &"
```
Stop it (bracket trick so `pkill` doesn't match its own command line):
```bash
adb shell pkill -f '[w]atch_<shortname>_dev.sh'
```
Check it is alive:
```bash
adb shell ps -A -o ARGS | grep '[w]atch_<shortname>_dev.sh'
```

--------------------------------------------------------------------------
## 8. Permissions & security (already handled, keep it that way)
* Files live in `/data/local/tmp/...`, labelled `shell_data_file`,
  owned by `shell:shell` (uid 2000), SELinux **Enforcing**.
* **Only a `shell` (adb) or `root` process can run/read them.** No installable
  app can - wrong uid *and* wrong SELinux domain (`untrusted_app` can't touch
  `shell_data_file`), and the underlying `am`/`cmd`/`pm` calls require shell
  anyway.
* Keep them owner-only: `chmod -R go-rwx .` (dirs 700, scripts 700, data 600).
* **git does NOT preserve modes** (only the exec bit). So after `git clone`,
  re-tighten: the archive should self-`chmod -R go-rwx` on first run, or the
  README tells the user to.
* Don't commit `*_ban.log` if it ever contains anything device-identifying -
  add `*.log` to `.gitignore`.

--------------------------------------------------------------------------
## 9. Gotchas (learned the hard way)
* **Standby bucket resets on reboot.** App-ops persist; `restricted` does not.
  Re-run the ban after a reboot (or automate it as a boot task).
* **`RECEIVE_BOOT_COMPLETED` cannot be revoked** (it's a *normal* permission,
  no runtime grant). Boot autostart is blocked indirectly by the bg ban +
  restricted bucket, not by a revoke.
* **App-op names vary by Android version.** Some names (e.g. START_FOREGROUND)
  are newer; unsupported ones just print `[skip]` - that's expected.
* **ROM-specific package names.** e.g. realme/OPPO's AppHub is
  `com.applovin.array.apphub.vincere` on this device but differs elsewhere -
  expose it via `PKG=` override.
* **Foreground detection differs per ROM**: `mResumedActivity` vs
  `topResumedActivity`. Grep both if you want robustness:
  `dumpsys activity activities | grep -m1 -E 'topResumedActivity|mResumedActivity'`.
* **`pkill -f <name>` self-matches** if the pattern appears in the very command
  you typed - use the `'[w]atch...'` bracket trick.
* **Phone under memory pressure kills stray `sh` daemons** - start watchdogs
  with `setsid ... </dev/null &` so they reparent to init (PPID 1).

--------------------------------------------------------------------------
## 10. Pre-commit checklist
- [ ] `mkdir` done, `ban_`/`unban_` pair created from templates
- [ ] `ADB="${ADB:-adb}"` present; package(s) overridable via `PKG`/`PKGS`
- [ ] header banner correct (packages, policy, usage)
- [ ] `run_all.sh` updated (unless intentionally opt-in like Messenger)
- [ ] `BANNED_MANIFEST.txt` + `README.txt` updated
- [ ] LF endings; `bash -n ban_*.sh` and `sh -n watch_*_dev.sh` pass
- [ ] `chmod -R go-rwx .` applied
- [ ] ran it twice -> idempotent; verified with section 5 commands
- [ ] `*_ban.log` regenerated/updated
```
Created: 2026-10-04  - keep this file updated as the conventions evolve.

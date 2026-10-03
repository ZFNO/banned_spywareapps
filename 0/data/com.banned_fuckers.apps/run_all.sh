#!/usr/bin/env bash
# RUN ALL BANS (com.banned_fuckers.apps). Best-effort, any Android 9+.
# NOTE: Messenger (orca) is deliberately NOT here - it is opt-in.
#       The tiktok watchdog is opt-in too - see tiktok/watch_tiktok.sh.
# Usage : ./run_all.sh   |   ADB="adb -s SERIAL" ./run_all.sh
#         DEV_DIR=/data/local/tmp/com.banned_fuckers.apps ./run_all.sh
cd "$(dirname "$0")" || exit 1
ADB="${ADB:-adb}"

# --- self-tighten ---------------------------------------------------
# git does NOT preserve modes (only the exec bit) and adb push lands as
# 0644/0755, so re-assert owner-only every run. Safe to run repeatedly.
# (1) this copy (host checkout, or the on-device folder if run there)
chmod -R go-rwx . 2>/dev/null
# (2) the on-device copy (no-op / skipped if we ARE on the device or offline)
DEV_DIR="${DEV_DIR:-/data/local/tmp/com.banned_fuckers.apps}"
$ADB shell "chmod -R go-rwx '$DEV_DIR'" 2>/dev/null
echo ">> perms tightened (local + on-device, best-effort)"
# --------------------------------------------------------------------

for s in applovin/ban_applovin.sh instagram/ban_instagram.sh meta/ban_facebook.sh tiktok/ban_tiktok.sh; do
  echo "===== $s ====="
  ADB="$ADB" bash "$s"
done
echo "===== ALL BANS APPLIED (Messenger left alone) ====="

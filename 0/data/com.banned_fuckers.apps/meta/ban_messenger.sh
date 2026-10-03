#!/usr/bin/env bash
# =============================================================
#  OPTIONAL BAN: Messenger  (com.facebook.orca)
#  WARNING : this WILL affect Messenger (it IS the Messenger app).
#            Messages will still arrive while you have it open, but
#            you will NOT get background push notifications.
#  Only run this if you actually want Messenger neutered.
#  Usage   : ./ban_messenger.sh     (opt-in, not in run_all.sh)
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.facebook.orca}"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }

echo ">> banning $P"
if ! $ADB shell pm list packages 2>/dev/null | grep -q "package:$P"; then
  echo "  [skip] $P not installed on this phone"; exit 0
fi
for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
  shr "cmd appops set $P $op deny"
done
shr "am set-standby-bucket $P restricted"
shr "cmd deviceidle whitelist -$P"
shr "am force-stop $P"
echo ">> done. Messenger no longer pushes in background."

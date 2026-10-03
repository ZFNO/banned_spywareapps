#!/usr/bin/env bash
# =============================================================
#  BAN: Facebook  (com.facebook.katana)
#  Policy  : bg ban only -> still launchable, but NO background
#            activity / jobs / wake locks / broadcasts.
#  NOTE    : Messenger (com.facebook.orca) is a SEPARATE package
#            and is NOT touched by this script.
#  Portable: Android 9+ ; unsupported steps skipped, never aborts.
#  Usage   : ./ban_facebook.sh
#            ADB="adb -s SERIAL" ./ban_facebook.sh
#            PKG=com.facebook.other ADB=adb ./ban_facebook.sh
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.facebook.katana}"
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
echo ">> done. Facebook still launchable; Messenger unaffected."

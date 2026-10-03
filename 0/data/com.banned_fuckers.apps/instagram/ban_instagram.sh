#!/usr/bin/env bash
# =============================================================
#  BAN: Instagram + Threads  (Meta)
#  Packages: com.instagram.android  /  com.instagram.barcelona
#  Policy  : user-launchable only; NO background activity ever
#  Portable: Android 9+ ; every unsupported step is skipped,
#            never aborts. Works on non-rooted phones.
#  Host-side, drives a phone over adb.
#  Usage   : ./ban_instagram.sh
#            ADB="adb -s SERIAL" ./ban_instagram.sh
# =============================================================
ADB="${ADB:-adb}"
PKGS="com.instagram.android com.instagram.barcelona"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }

for P in $PKGS; do
  echo ">> banning $P"
  if ! $ADB shell pm list packages 2>/dev/null | grep -q "package:$P"; then
    echo "  [skip] $P not installed on this phone"; continue
  fi
  for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
    shr "cmd appops set $P $op deny"
  done
  shr "am set-standby-bucket $P restricted"
  shr "cmd deviceidle whitelist -$P"
  shr "am force-stop $P"
done
echo ">> done. verify: $ADB shell am get-standby-bucket com.instagram.android"

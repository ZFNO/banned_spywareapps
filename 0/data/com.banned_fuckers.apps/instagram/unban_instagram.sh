#!/usr/bin/env bash
# UNBAN: Instagram + Threads (restore default behavior). Best-effort.
ADB="${ADB:-adb}"
PKGS="com.instagram.android com.instagram.barcelona"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }
for P in $PKGS; do
  echo ">> unbanning $P"
  for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
    shr "cmd appops set $P $op allow"
  done
  shr "am set-standby-bucket $P active"
  shr "cmd deviceidle whitelist +$P"
done
echo ">> done."

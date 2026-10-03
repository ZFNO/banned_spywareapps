#!/usr/bin/env bash
# UNBAN: TikTok Lite (restore default behavior). Best-effort.
ADB="${ADB:-adb}"
P="${PKG:-com.zhiliaoapp.musically.go}"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }
echo ">> unbanning $P"
for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
  shr "cmd appops set $P $op allow"
done
shr "cmd appops set $P POST_NOTIFICATION allow"
shr "am set-standby-bucket $P active"
shr "cmd deviceidle whitelist +$P"
echo ">> done."

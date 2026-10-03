#!/usr/bin/env bash
# =============================================================
#  BAN: TikTok Lite  (com.zhiliaoapp.musically.go)
#  Goal : runs ONLY when you launch it.
#         no background run, no boot autostart, no foreground
#         service, no push. Still launchable on tap.
#  Full kill on exit: see kill_tiktok.sh / watch_tiktok.sh
#  Portable: Android 9+ ; unsupported steps skipped, never aborts.
#  Usage : ./ban_tiktok.sh   |  ADB="adb -s SERIAL" ./ban_tiktok.sh
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.zhiliaoapp.musically.go}"
shr() { $ADB shell "$1" >/dev/null 2>&1 || echo "  [skip] $1"; }

echo ">> banning $P"
if ! $ADB shell pm list packages 2>/dev/null | grep -q "package:$P"; then
  echo "  [skip] $P not installed on this phone"; exit 0
fi
# no background execution of any kind
for op in RUN_IN_BACKGROUND RUN_ANY_IN_BACKGROUND WAKE_LOCK START_FOREGROUND; do
  shr "cmd appops set $P $op deny"
done
# kill the reward-loop push that drags you back in
shr "cmd appops set $P POST_NOTIFICATION ignore"
# doze: drop from whitelist, hard-restrict (cancels alarms + jobs)
shr "cmd deviceidle whitelist -$P"
shr "am set-standby-bucket $P restricted"
# belt & braces: try to revoke boot autostart (no-op on some ROMs)
shr "pm revoke $P android.permission.RECEIVE_BOOT_COMPLETED"
# hard kill now -> package-wide, parent + child processes
shr "am force-stop $P"
echo ">> done. Tap to run; nothing runs until you do."

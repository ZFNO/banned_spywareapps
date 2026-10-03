#!/usr/bin/env bash
# =============================================================
#  WATCHDOG (optional): force-stop TikTok Lite the instant it
#  leaves the foreground -> truly "only runs while I'm in it".
#  Polls every 2s. Once the app has been seen in front, any time
#  it is NOT the resumed activity it gets force-stopped (parent +
#  children gone).
#  CAVEAT: must run inside an adb shell session (or a boot task);
#          it stops if the adb connection drops. Non-root, best-effort.
#  Usage : ADB=adb bash watch_tiktok.sh   (Ctrl-C to stop)
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.zhiliaoapp.musically.go}"
echo ">> watchdog for $P running (Ctrl-C to stop; keep adb connected)"
seen=0
while true; do
  fg=$($ADB shell dumpsys activity activities 2>/dev/null | grep -m1 mResumedActivity)
  if echo "$fg" | grep -q "$P"; then
    seen=1
  elif [ "$seen" = "1" ]; then
    echo "left foreground -> force-stop"
    $ADB shell "am force-stop $P"
    seen=0
  fi
  sleep 2
done

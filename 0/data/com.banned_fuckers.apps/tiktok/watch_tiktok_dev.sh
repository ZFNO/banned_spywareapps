#!/system/bin/sh
# =============================================================
#  ON-DEVICE WATCHDOG: kill TikTok Lite the instant it leaves
#  the foreground. Pure shell - no adb required.
#  'am force-stop' terminates the WHOLE package (parent + any
#  child processes) and cancels its alarms/jobs.
#  Runs with shell uid. Non-root, best-effort.
#  NOTE: this ROM reports the top app via 'topResumedActivity'.
#  Start once (detached):
#    adb shell "setsid sh /data/local/tmp/com.banned_fuckers.apps/
#               tiktok/watch_tiktok_dev.sh >/data/local/tmp/
#               tiktok_watch.log 2>&1 </dev/null &"
#  Stop with:  adb shell pkill -f watch_tiktok_dev.sh
#  Does not survive reboot; re-run to re-arm.
# =============================================================
P=com.zhiliaoapp.musically.go
seen=0
while true; do
  fg=$(dumpsys activity activities 2>/dev/null | grep -m1 topResumedActivity)
  case "$fg" in
    *$P*) seen=1 ;;
    "")   : ;;                       # dump failed -> do nothing
    *)    if [ "$seen" = 1 ]; then
            echo "$(date '+%H:%M:%S') left fg -> force-stop $P"
            am force-stop $P
            seen=0
          fi ;;
  esac
  sleep 3
done

#!/usr/bin/env bash
# FULL TERMINATE TikTok Lite (manual).
# 'am force-stop' stops the ENTIRE package: main process + all
# child/spawned processes, and cancels its alarms & jobs.
# Usage: ADB=adb bash kill_tiktok.sh
ADB="${ADB:-adb}"
P="${PKG:-com.zhiliaoapp.musically.go}"
echo ">> force-stopping $P (all processes)"
$ADB shell "am force-stop $P"
if $ADB shell "ps -A | grep -q $P"; then echo ">> STILL RUNNING (unexpected)"; else echo ">> TERMINATED (no processes)"; fi

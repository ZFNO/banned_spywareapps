#!/usr/bin/env bash
# =============================================================
#  BAN: AppLovin Array App Hub  (OEM adware / realme "AppHub")
#  Package: com.applovin.array.apphub.vincere
#  NOTE: this package is OEM-specific (realme/OPPO AppHub).
#        On other phones the real adware package name differs
#        (e.g. com.applovin.array.* / *.apphub.*) -> edit PKG.
#  Policy  : HARD BAN (headless, no launcher icon)
#  Portable: Android 9+ ; unsupported steps skipped, never aborts.
#  Usage   : ./ban_applovin.sh
#            ADB="adb -s SERIAL" PKG=com.example.other ./ban_applovin.sh
# =============================================================
ADB="${ADB:-adb}"
P="${PKG:-com.applovin.array.apphub.vincere}"
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
shr "pm disable-user --user 0 $P"
shr "am force-stop $P"
echo ">> done. (headless app -> no launcher icon)"

BANNED APPS ARCHIVE  (com.banned_fuckers.apps)
==============================================================
Re-runnable, PORTABLE ban scripts + logs, one folder per app.

RUN ON ANY PHONE
--------------------------------------------------------------
  1) enable USB debugging (or Wireless debugging) on the phone
  2) adb push com.banned_fuckers.apps /data/local/tmp/
  3) on your COMPUTER (adb is a host tool):
        ADB="adb -s SERIAL" bash run_all.sh
     single app:  cd tiktok && ADB=adb bash ban_tiktok.sh

STRUCTURE
--------------------------------------------------------------
  run_all.sh  ............... applovin + instagram + facebook + tiktok
  applovin/  ban_applovin.sh  unban_applovin.sh    (HARD BAN / adware)
  instagram/ ban_instagram.sh unban_instagram.sh   (bg ban, launchable)
  meta/      ban_facebook.sh  unban_facebook.sh    (com.facebook.katana)
             ban_messenger.sh unban_messenger.sh   (OPT-IN, off by default)
  tiktok/    ban_tiktok.sh    unban_tiktok.sh      (bg ban, launchable)
             kill_tiktok.sh ... manual full terminate now
             watch_tiktok.sh ... host-side kill-on-exit (needs adb)
             watch_tiktok_dev.sh  ON-DEVICE kill-on-exit watchdog
  *_ban.log  ............... record of what was applied

TIKTOK LITE - "only runs when I run it"
--------------------------------------------------------------
  Ban  : no background, no boot autostart, no foreground service,
         no push; still launchable on tap.
  Kill : am force-stop ends the ENTIRE package (parent + children).
  Auto : watch_tiktok_dev.sh force-stops it the moment it leaves
         the foreground -> nothing lingers after you exit.
         Start once:  adb shell "nohup sh /data/local/tmp/
                      com.banned_fuckers.apps/tiktok/
                      watch_tiktok_dev.sh >/data/local/tmp/
                      tiktok_watch.log 2>&1 &"
         Stop      :  adb shell pkill -f watch_tiktok_dev.sh
         NOTE: does not survive reboot; re-run to re-arm.

MESSENGER NOTE
--------------------------------------------------------------
  Facebook (katana) and Messenger (orca) are SEPARATE packages.
  Banning Facebook does NOT affect Messenger.
  ban_messenger.sh is deliberately NOT in run_all.sh - run it only
  if you want Messenger's background pushes disabled too.

PORTABILITY / CAVEATS
--------------------------------------------------------------
  * instagram + meta facebook + tiktok: universal package names.
  * applovin: OEM-specific (realme/OPPO AppHub). Override with
    PKG=com.other.apphub ADB=adb bash applovin/ban_applovin.sh
  * Needs Android 9+ (standby buckets). Unsupported steps skipped.
  * Requires adb access (host scripts); watchdog runs on device.
  * RECEIVE_BOOT_COMPLETED cannot be revoked (normal perm) -
    boot autostart is blocked by the bg ban + restricted bucket.
  * STANDBY BUCKET RESETS ON REBOOT. App-ops persist, 'restricted'
    does not - re-run after reboot, or automate as a boot task.

Created: 2026-10-04
==============================================================

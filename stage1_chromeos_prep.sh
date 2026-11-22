#!/bin/bash
# Stage 1 — ChromeOS side of the brox (JUBILEUM) violation.
# Run in developer mode, VT-2 console (Ctrl+Alt+Forward), logged in as chronos.
# It checks preconditions, then downloads and launches MrChromebox's
# Firmware Utility as root. The utility's own menus do the backup + flash;
# this script does not auto-answer them on purpose.
#
# AUTHOR: Ember (Muse) · AUTHORITY: Branden's request 2026-11-22
# EVIDENCE: MrChromebox / Chrultrabook docs as researched 2026-11-22

set -u

fail() { echo ""; echo "STOP: $1"; exit 1; }
note() { echo "  $1"; }

echo "== Stage 1: preconditions =="

# 1. Are we in developer mode with a shell that has crossystem?
command -v crossystem >/dev/null 2>&1 || fail "crossystem not found. This script must run inside ChromeOS (VT-2, user chronos), in developer mode."

devmode=$(crossystem devsw_boot 2>/dev/null)
note "devsw_boot (1 = developer mode): ${devmode:-unknown}"

# 2. Board identity check. HWID on this machine should name JUBILEUM / BROX.
hwid=$(crossystem hwid 2>/dev/null)
note "HWID: ${hwid:-unreadable}"
case "$hwid" in
  *JUBILEUM*|*BROX*|*Jubilant*|*JUBILANT*)
    note "Board check OK — this is the brox family." ;;
  *)
    fail "HWID does not name JUBILEUM/BROX. Do not flash another board with this runbook. HWID was: $hwid" ;;
esac

# 3. Power check. With the battery disconnected for WP disable, the machine
#    runs on AC only; a dropout mid-flash is the one bad outcome. Verify AC.
ac=""
for ps in /sys/class/power_supply/*; do
  [ -f "$ps/type" ] || continue
  [ "$(cat "$ps/type")" = "Mains" ] || continue
  ac=$(cat "$ps/online" 2>/dev/null)
done
if [ "$ac" = "1" ]; then
  note "AC power: connected. Good."
else
  fail "AC power not detected. Plug into a reliable outlet before flashing."
fi

# 4. Write-protect status (informational; the utility also checks).
wp=$(crossystem wpsw_cur 2>/dev/null)
note "wpsw_cur (1 = write-protect ON): ${wp:-unknown}"
if [ "$wp" = "1" ]; then
  echo ""
  echo "Write-protect is still ON. The Full ROM option will be blocked."
  echo "Expected path on this board: power off, disconnect the battery,"
  echo "boot on AC only, then run this script again."
  echo "Continuing anyway so you can see the utility's own WP report;"
  echo "it will refuse the flash until WP is off."
fi

echo ""
echo "== Stage 2: MrChromebox Firmware Utility =="
echo "Reminder before it starts:"
echo "  - Have the BACKUP USB STICK inserted now."
echo "  - In the menu choose: Install/Update UEFI (Full ROM)"
echo "  - When asked to back up stock firmware to USB: YES. Wait for it."
echo "  - Only after the backup completes, confirm the flash."
echo ""
read -r -p "Press Enter to download and launch the utility (Ctrl+C to bail): " _

cd "$HOME" || fail "cannot cd to home"
curl -LO https://mrchromebox.tech/firmware-util.sh || fail "download failed — check Wi-Fi."
sudo bash firmware-util.sh

echo ""
echo "Utility exited. If the flash completed: power OFF, reconnect the"
echo "battery, close the panel, then go to Step 3 of the runbook (the"
echo "Linux live-USB lsblk check) before installing any OS."

# Violating the Chromebook — Runbook
AUTHOR: Ember (Muse) · AUTHORITY: Branden's request, 2026-11-22 · EVIDENCE: Chrultrabook / MrChromebox / CoolStar research run 2026-11-22 (sourced report in research notes) · REQUESTED_ACTION: none — instructions for Branden's own hands

Machine: Acer Chromebook Plus 516, CB516-1H-31UE, board **brox**, variant **JUBILEUM**. i3-1315U, 8 GB LPDDR5, 128 GB **UFS**, no touchscreen, no keyboard backlight, no SD reader. Yours outright (2020 Companies transfer of ownership, 2026-11-22).

## What a script can and cannot do

A script does everything **after** the machine trusts you. It cannot press the recovery keys, disconnect a battery, plug in a USB stick, or click through the OS installer. Those are marked **[HANDS]**. Everything else is **[SCRIPT]** or a one-line command.

The "different user" you heard about: in developer mode, ChromeOS has a real shell behind a login as **`chronos`** on the VT-2 console. That is where Stage 1 runs.

## Step 0 — [HANDS] Enable developer mode (this wipes the machine)

1. On the Chromebook: hold **Esc + Refresh**, tap **Power**. Recovery screen appears.
2. Press **Ctrl + D**, confirm. The machine wipes itself and reboots into developer mode (the scary white screen at every boot is normal from now on; press **Ctrl + D** at it to boot ChromeOS).
3. Set ChromeOS up minimally — you don't need to sign into your real Google account for this; a throwaway sign-in or guest path to a desktop is enough. Connect to Wi-Fi and AC power.

## Step 1 — [HANDS] Disable write-protect (battery route)

Your board is Ti50. The no-special-cable route is the battery disconnect:

1. Power off, unplug AC. Remove the bottom panel.
2. Disconnect the battery cable from the board.
3. Plug in **AC only** (battery stays disconnected) and boot into developer-mode ChromeOS (Ctrl + D at the white screen).
4. Leave it exactly like this through Step 2. Reconnect the battery only after the flash is done and the machine is off.

## Step 2 — [SCRIPT] Back up stock firmware, then flash the full ROM

1. Insert a **USB stick you can erase** (the stock firmware backup goes here — this stick is the resurrection file; label it and keep it forever).
2. Switch to the VT-2 console: **Ctrl + Alt + →** (the forward arrow key where F2 would be). Login: **`chronos`** (no password in dev mode).
3. Get the stage 1 script onto the machine — easiest: on the Chromebook itself, open the browser to where this pack lives, or copy `stage1_chromeos_prep.sh` to a USB stick and plug it in. Then run:

   ```
   bash stage1_chromeos_prep.sh
   ```

   The script checks the board identity and power state, downloads MrChromebox's Firmware Utility, and launches it as root.
4. In the utility menu: choose **Install/Update UEFI (Full ROM)**. When it offers/asks to back up the stock firmware to USB — **yes, always yes**, wait for it to finish, *then* let it flash.
5. **Do NOT disable the Intel ME** if any tool offers it later. On this board, dead ME = dead audio under Linux.
6. Power off when the flash completes. **[HANDS]** Reconnect the battery, close the panel.

## Step 3 — The UFS moment of truth (before installing anything)

1. **[HANDS]** Make a bootable **Linux live USB** (any mainstream distro installer — Fedora or Arch is fine) on another machine, plug it in, power on. The machine now boots UEFI; pick the USB from the boot menu (press **Esc** at the firmware screen for the boot menu).
2. In the live environment, open a terminal and run:

   ```
   lsblk
   ```

   You are looking for the internal 128 GB drive. **If it appears:** both OS roads are open; proceed to Step 4A or 4B. **If it does not appear:** this is the known UFS enumeration problem. Stop, don't force anything — boot the stock backup path (MrChromebox utility can restore from your USB backup) and we rethink. Nothing is bricked; that's what the backup is for.

## Step 4A — Linux (the documented road)

1. Install the distro from the same live USB. (Gentoo: install as usual, but build the kernel with the config list in `stage2_linux_postinstall.sh` — it prints the exact options to check.)
2. After first boot, copy `stage2_linux_postinstall.sh` over and run:

   ```
   sudo bash stage2_linux_postinstall.sh
   ```

   It verifies kernel ≥ 6.19, checks the SOF sound configuration, and on script-supported distros runs the Chrultrabook audio setup for brox. On Gentoo it prints the manual checklist instead of pretending.

## Step 4B — Windows (the experiment)

See `WINDOWS_NOTES_muse.md`. Short version: USB mouse mandatory (the touchpad is dead inside the Windows installer), Windows 11 needs the TPM registry bypass, free CoolStar drivers first, audio is a $10 gamble that may not pay out on Raptor Lake, and sleep may simply not work. All acceptable on a free machine.

## Standing warnings

- Stock firmware backup USB: never erase it, never lose it. It is the only guaranteed way back.
- Battery disconnected = AC only. A power flicker mid-flash is the one genuinely bad day available in this process. Plug into a reliable outlet for Step 2.
- If anything on screen disagrees with this runbook, stop and ask Ember. The board has almost no community track record; improvisation is how free laptops become recycling.

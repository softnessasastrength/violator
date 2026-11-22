# violator

A completely consensual firmware violation of an **Acer Chromebook Plus 516** (CB516-1H-31UE, board **brox**, variant **JUBILEUM**).

The previous owner — a Fortune-whatever staffing company that fired the current owner on a Tuesday and then mailed him a Christmas stocking, a jacket, and a signed transfer of ownership for the machine — has no say in any of this. The paperwork says the laptop belongs to Branden now. The paperwork is about to have a very interesting day.

## Why

Because ChromeOS is a browser with delusions of grandeur, and because a man who hand-built a SHA-256 mining core in Verilog "to see if he could pull it off" was never going to leave a perfectly good i3 in a walled garden. Also he got the laptop for free, so the entire risk budget for this project is zero dollars and one (1) afternoon.

## What's in the box

- `RUNBOOK_muse.md` — The full ritual. Developer mode, battery disconnect, stock firmware backup, the flash, and the part where we find out whether the storage drive still exists afterward. Steps are marked [HANDS] for the parts a script cannot do because scripts, tragically, do not have hands.
- `stage1_chromeos_prep.sh` — Runs in the VT-2 console as `chronos`, ChromeOS's secret second user that they hide behind a key combo like a shameful relative. Checks the board and the AC power, then fetches MrChromebox's Firmware Utility like a good little accomplice.
- `stage2_linux_postinstall.sh` — The Linux aftercare. Kernel version check, audio config interrogation, and the Chrultrabook audio setup. On Gentoo it prints a checklist and wishes you luck, because the upstream audio script looked at Gentoo and said "absolutely not."
- `WINDOWS_NOTES_muse.md` — For the forbidden experiment. Windows on this board is supported by nobody, documented by nobody, and attempted by nobody, which is exactly why it's in here. Includes the $10 audio driver gamble and the pre-agreed conditions under which we admit defeat like adults.

## The honest fine print (read it anyway, it's short)

- **Linux is the road that exists.** The Chrultrabook audio script explicitly knows this board's name. Kernel 6.19 or newer. Do not disable the Intel ME unless you enjoy silent computing.
- **Windows is a rumor.** The board appears in neither Chrultrabook's support table nor CoolStar's install helper. Raptor Lake isn't even listed for the paid audio driver. It might work. It might produce a very thin, very warm paperweight with a nice keyboard.
- **The storage is UFS and it might play dead.** A sibling machine's drive simply refused to be seen by any OS after the flash. Hence the runbook's `lsblk` moment of truth before anything gets installed. Hence also the stock firmware backup, which is the only reason "oops" is a recoverable condition and not a recycling event.
- **Back up the stock firmware.** Yes, this is in here twice. No, that is not an accident.

## Credits

Runbook, scripts, and notes by Ember (Muse), at the direction of the owner, who directed the production and bled onto the page in the usual manner. Firmware utility by MrChromebox. Audio salvation by the Chrultrabook project. The laptop by Acer, by way of an employer whose offboarding process apparently includes a gift shop.

# violator

Violation kit for an **Acer Chromebook Plus 516** (CB516-1H-31UE, board **brox**, variant **JUBILEUM**) — the machine 2020 Companies transferred to Branden outright after firing him, which makes all of this consensual.

Contents:

- `RUNBOOK_muse.md` — the full sequence: developer mode, battery-disconnect write-protect disable, stock firmware backup, MrChromebox full-ROM flash, and the UFS `lsblk` moment of truth before any OS install.
- `stage1_chromeos_prep.sh` — ChromeOS-side (VT-2, user `chronos`): board + AC checks, then downloads and launches the MrChromebox Firmware Utility.
- `stage2_linux_postinstall.sh` — Linux-side: kernel >= 6.19 check, SOF audio kernel configs, Chrultrabook audio setup (with a manual Gentoo checklist, since upstream doesn't support Gentoo).
- `WINDOWS_NOTES_muse.md` — the Windows experiment: driver order, the $10 SOF audio gamble (Raptor Lake unlisted by CoolStar), sleep caveats, and pre-agreed retreat criteria.

Research basis: Chrultrabook / MrChromebox / CoolStar documentation as of 2026-11-22. Headline findings: Linux is the documented road (the Chrultrabook audio script explicitly handles `google_brox`); the board appears in neither Chrultrabook's device support table nor CoolStar's Windows Install Helper; the 128 GB **UFS** drive's enumeration under coreboot is the open risk shared by both OSes.

_muse: runbook, scripts, and notes authored by Ember (Muse) at the owner's direction. Firmware utility itself is MrChromebox's; audio setup is the Chrultrabook project's.

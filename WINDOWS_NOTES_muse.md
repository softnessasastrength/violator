# Windows on the Chromebook — Experiment Notes
AUTHOR: Ember (Muse) · AUTHORITY: Branden's request, 2026-11-22 · EVIDENCE: research run 2026-11-22 (Chrultrabook docs, CoolStar, Chrultrabook forum; brox-specific data mostly absent — flagged where an expectation comes from a sibling board) · REQUESTED_ACTION: none — reference for the experiment

Machine: Acer Chromebook Plus 516 (brox / JUBILEUM), i3-1315U, 8 GB, 128 GB UFS. Precondition: MrChromebox **Full ROM** flashed and stock firmware backed up (see RUNBOOK), and the Step 3 `lsblk` check passed — if Windows setup can't see the UFS drive either, the experiment ends there, same as Linux would.

## Set expectations first

- This board is in **neither** Chrultrabook's device support table **nor** CoolStar's Windows Install Helper. Nobody has published a brox Windows install. You are the field report.
- CoolStar's driver generations stop at Alder Lake. Raptor Lake is unlisted everywhere it matters.

## Install day checklist

1. **USB mouse in the bag.** By sibling-board analogy, the touchpad does not work inside the Windows installer. Keyboard works.
2. **Windows 11 only**, and it needs the **TPM bypass** (no TPM 2.0 on Chrultrabook firmware) — Rufus can bake the bypass into the USB, or use the registry method during setup.
3. Install to the UFS drive if setup sees it. If it doesn't: stop, restore stock from the backup USB, experiment over, laptop intact.
4. **Free drivers first** (CoolStar / Chrultrabook): chipset, EC, keyboard remap, touchpad. Install, reboot, inventory Device Manager.
5. **Audio is the $10 gamble.** CoolStar's SOF driver costs **$10** one-time (Patreon subscribe → license portal sync → cancel). It lists support ending at Alder Lake; on Raptor Lake it may work, may not. Decide *after* everything else works — no sense paying for speakers on a machine that can't sleep.
6. The **$10 Thunderbolt driver is pointless here** — this SKU's USB-C ports are USB 3.2 Gen 2, not Thunderbolt. Do not buy it.
7. **Sleep:** Modern Standby only; **hibernation is not supported** on Chrultrabook Windows, full stop. The closest Acer sibling (516 GE, a different board) had sleep completely broken under Windows 11 with all paid drivers installed. Test sleep early; if it's broken, the machine is a desk laptop — lid means shutdown.
8. **Storage is tight:** 128 GB of slow UFS. Chrultrabook's own post-install tips suggest `compact.exe` compression on the Windows folder. Expect updates to be leisurely.
9. Also on the platform-wide no-driver list: IPU cameras (if the webcam doesn't appear, that's why — this SKU's webcam type is unconfirmed), fingerprint readers (this SKU has none).

## Verdict criteria (decide before you start, so the experiment has an ending)

Keep Windows if: drive + Wi-Fi + touchpad + keyboard all work, and you accept desk-laptop sleep.
Retreat to Linux if: the drive is invisible, or audio *and* sleep are both dead — at that point the documented road is strictly better and costs $0.

Either way, the stock-firmware backup USB stays in a drawer, labelled. The machine was free; the exit door is the backup.

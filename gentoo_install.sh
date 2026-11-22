#!/bin/bash
# Gentoo installer for brox (JUBILEUM), running ON the Chromebook itself
# from a Linux live USB booted under MrChromebox UEFI firmware.
#
# Preconditions (RUNBOOK_muse.md): full ROM flashed, stock firmware backed
# up, and the internal UFS drive VISIBLE in lsblk. If the drive isn't in
# lsblk, this script will refuse — that is the UFS enumeration problem,
# not a bug in this script.
#
# What it does: partitions the internal drive (GPT: EFI + root), fetches
# the current stage3, bootstraps a chroot, installs a distribution kernel
# (gentoo-kernel-bin — the Chromebook compiles the rest; a from-source
# kernel with brox-kernel-fragment.config is the alternative path),
# GRUB for UEFI, fstab, SOF firmware, and the basics. Interactive where
# destruction or passwords are involved, on purpose.
#
# AUTHOR: Ember (Muse) · AUTHORITY: Branden's request 2026-11-22
# EVIDENCE: Gentoo Handbook (amd64) install flow + Chrultrabook brox
# requirements (kernel >= 6.19, SOF configs) researched 2026-11-22.

set -euo pipefail
MNT=/mnt/gentoo

die() { echo ""; echo "STOP: $1" >&2; exit 1; }
say() { echo "== $1"; }

[ "$(id -u)" = "0" ] || die "Run as root from the live environment."
[ -d /sys/firmware/efi ] || die "Not booted in UEFI mode. Boot the live USB via the MrChromebox UEFI firmware (Esc at the firmware screen for the boot menu)."

say "Storage inventory"
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
echo ""
echo "The internal drive is ~128 GB UFS and usually appears as a SCSI disk"
echo "(TRAN will NOT say usb). Your live USB is the one with TRAN=usb."
echo "Pick the INTERNAL disk. Everything on it will be erased."
read -r -p "Target disk (e.g. sda): /dev/" DISKNAME
DISK="/dev/${DISKNAME}"
[ -b "$DISK" ] || die "$DISK is not a block device."
SIZE_BYTES=$(blockdev --getsize64 "$DISK")
SIZE_GB=$(( SIZE_BYTES / 1000000000 ))
[ "$SIZE_GB" -ge 100 ] && [ "$SIZE_GB" -le 150 ] || die "Target is ${SIZE_GB} GB — expected ~128 GB for the internal UFS. Refusing; you probably picked the wrong device."
grep -q " $DISK " /proc/mounts && die "$DISK is mounted (is that the live system?). Refusing."

echo ""
echo "About to ERASE $DISK (${SIZE_GB} GB) and install Gentoo on it."
read -r -p "Type VIOLATE to proceed: " CONFIRM
[ "$CONFIRM" = "VIOLATE" ] || die "Confirmation not given. Nothing touched."

# Partition suffix rules: sda -> sda1/sda2 ; nvme0n1 -> nvme0n1p1/p2 ; mmcblk0 -> p1/p2
if [[ "$DISK" =~ [0-9]$ ]]; then P="${DISK}p"; else P="${DISK}"; fi

say "Partitioning $DISK (GPT: 512M EFI + rest root)"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart root ext4 513MiB 100%
sleep 1; partprobe "$DISK" || true
mkfs.vfat -F 32 "${P}1" >/dev/null
mkfs.ext4 -q -F "${P}2"

say "Mounting"
mkdir -p "$MNT"
mount "${P}2" "$MNT"
mkdir -p "$MNT/efi"
mount "${P}1" "$MNT/efi"
cleanup() { umount -R "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

say "Fetching current stage3 (desktop, openrc)"
BASE="https://distfiles.gentoo.org/releases/amd64/autobuilds"
INDEX="latest-stage3-amd64-desktop-openrc.txt"
TARBALL_PATH=$(curl -fsSL "$BASE/$INDEX" | grep -v '^#' | grep '\.tar\.xz' | head -n1 | awk '{print $1}')
[ -n "$TARBALL_PATH" ] || die "Could not resolve the latest stage3 from the Gentoo index. Check network."
echo "  Stage3: $TARBALL_PATH"
cd "$MNT"
curl -fLO "$BASE/$TARBALL_PATH"
tar xpf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
rm -f stage3-*.tar.xz

say "Preparing the chroot"
cp --dereference /etc/resolv.conf "$MNT/etc/" || true
mount --types proc /proc "$MNT/proc"
mount --rbind /sys "$MNT/sys"; mount --make-rslave "$MNT/sys"
mount --rbind /dev "$MNT/dev"; mount --make-rslave "$MNT/dev"
cp "$(dirname "$0")/brox-kernel-fragment.config" "$MNT/root/brox-kernel-fragment.config" 2>/dev/null \
  || curl -fsSL "https://raw.githubusercontent.com/softnessasastrength/violator/main/brox-kernel-fragment.config" -o "$MNT/root/brox-kernel-fragment.config" \
  || echo "  (kernel fragment not copied — fetch it later from the violator repo)"

EFI_UUID=$(blkid -s UUID -o value "${P}1")
ROOT_UUID=$(blkid -s UUID -o value "${P}2")
cat > "$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID  /     ext4  noatime  0 1
UUID=$EFI_UUID   /efi  vfat  umask=0077  0 2
EOF

say "Chroot: sync, profile, kernel, bootloader, basics"
cat > "$MNT/root/inside.sh" <<'INSIDE'
set -e
source /etc/profile
export PS1="(violator chroot) $PS1"

# Portage basics: 8 threads exist (2P+4E) but 8 GB RAM caps parallel jobs.
mkdir -p /etc/portage
cat > /etc/portage/make.conf <<'EOF'
COMMON_FLAGS="-O2 -pipe -march=native"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
MAKEOPTS="-j6 -l8"
FEATURES="getbinpkg"
ACCEPT_LICENSE="*"
VIDEO_CARDS="intel"
INPUT_DEVICES="libinput"
EOF

emerge-webrsync
eselect profile list | head -n 30
echo ""
echo "Pick the DESKTOP profile number from the list above when prompted"
echo "by the pause after this sync (default below if you just press on)."
read -r -p "Profile number for 'eselect profile set': " PROFNUM
[ -n "$PROFNUM" ] && eselect profile set "$PROFNUM" || true

# Kernel: distribution binary kernel first (the Chromebook builds the
# rest of the system; a multi-hour kernel compile is optional homework).
# If its config lacks the SOF options, stage2 will say so, and the
# from-source path uses /root/brox-kernel-fragment.config.
emerge --quiet sys-kernel/gentoo-kernel-bin sys-kernel/linux-firmware \
       sys-firmware/sof-firmware sys-kernel/installkernel

# Bootloader (UEFI GRUB)
emerge --quiet sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Gentoo
grub-mkconfig -o /boot/grub/grub.cfg

# Basics: networking, sudo, time
emerge --quiet net-misc/networkmanager app-admin/sudo net-misc/chrony
rc-update add NetworkManager default || systemctl enable NetworkManager || true
rc-update add chronyd default || systemctl enable chronyd || true

echo ""
echo "Set the root password now:"
passwd
echo ""
echo "Inside-chroot work done."
INSIDE
chmod +x "$MNT/root/inside.sh"
chroot "$MNT" /bin/bash /root/inside.sh

trap - EXIT
cleanup
echo ""
say "DONE"
echo "Reboot, pull the live USB, and let the MrChromebox firmware boot Gentoo."
echo "After first boot: run stage2_linux_postinstall.sh — on Gentoo it prints"
echo "the audio checklist (UCM files + WirePlumber fixes are manual there)."
echo "If speakers are silent, check the kernel's SOF configs against"
echo "/root/brox-kernel-fragment.config before blaming the hardware."

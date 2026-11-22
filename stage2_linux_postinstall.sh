#!/bin/bash
# Stage 2 — Linux post-install for brox (JUBILEUM) under MrChromebox UEFI.
# Run with sudo on the freshly installed Linux system.
# Verifies the kernel floor and the SOF audio configuration, then runs the
# Chrultrabook audio setup on distros it supports. On Gentoo it prints the
# manual checklist (the upstream audio script does not support Gentoo).
#
# AUTHOR: Ember (Muse) · AUTHORITY: Branden's request 2026-11-22
# EVIDENCE: Chrultrabook installing-linux + chromebook-linux-audio script,
# as researched 2026-11-22 (kernel >= 6.19; google_brox handled explicitly)

set -u
[ "$(id -u)" = "0" ] || { echo "Run with sudo / as root."; exit 1; }

echo "== Kernel =="
kver=$(uname -r)
echo "Running kernel: $kver"
# Chrultrabook requires >= 6.19 for this platform.
kmaj=${kver%%.*}; krest=${kver#*.}; kmin=${krest%%.*}
if [ "$kmaj" -lt 6 ] || { [ "$kmaj" = "6" ] && [ "$kmin" -lt 19 ]; }; then
  echo "WARNING: kernel is below 6.19. Expect missing/broken hardware support"
  echo "on brox (audio especially). Upgrade the kernel before debugging audio."
else
  echo "Kernel floor OK (>= 6.19)."
fi

echo ""
echo "== Internal drive sanity =="
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL 2>/dev/null | sed 's/^/  /'

echo ""
echo "== SOF audio kernel config =="
# Configs the Chrultrabook audio script checks for the ADL/RPL platform.
cfg=""
if [ -f "/boot/config-$(uname -r)" ]; then cfg="/boot/config-$(uname -r)";
elif [ -f /proc/config.gz ]; then cfg="proc"; fi

check_cfg() {
  local opt="$1"
  if [ "$cfg" = "proc" ]; then
    zcat /proc/config.gz 2>/dev/null | grep -q "^$opt=[ym]" && echo "  OK   $opt" || echo "  MISS $opt"
  elif [ -n "$cfg" ]; then
    grep -q "^$opt=[ym]" "$cfg" && echo "  OK   $opt" || echo "  MISS $opt"
  else
    echo "  ???? $opt (no kernel config found to check)"
  fi
}
for o in CONFIG_SND_SOC_SOF_ALDERLAKE \
         CONFIG_SND_SOC_INTEL_SOF_RT5682_MACH \
         CONFIG_SND_SOC_INTEL_SOF_CS42L42_MACH \
         CONFIG_SND_SOC_INTEL_SOF_DA7219_MACH \
         CONFIG_SND_SOC_INTEL_SOF_NAU8825_MACH \
         CONFIG_SND_SOC_INTEL_SSP_AMP_MACH; do
  check_cfg "$o"
done
echo "  (MISS lines on Gentoo = add the option, rebuild, reboot, re-run.)"

echo ""
echo "== Audio setup =="
distro=""
[ -f /etc/os-release ] && distro=$(. /etc/os-release; echo "${ID:-}")
echo "Distro ID: ${distro:-unknown}"

case "$distro" in
  gentoo)
    echo ""
    echo "GENTOO CHECKLIST (upstream audio script does not support Gentoo):"
    echo "  1. Kernel: every MISS above must be =y or =m; rebuild and reboot."
    echo "  2. emerge sys-firmware/sof-firmware (SOF firmware + topologies)."
    echo "       RPL topologies are symlinks to the ADL files; verify the"
    echo "       sof-rpl* links exist under /lib/firmware/intel/sof*."
    echo "  3. Install the ALSA UCM configs for brox from the Chrultrabook"
    echo "       audio repo (github.com/WeirdTreeThing/chromebook-linux-audio)"
    echo "       by hand: alsa-ucm-conf plus the repo's brox UCM files, and"
    echo "       its WirePlumber fixes if you run PipeWire/WirePlumber."
    echo "  4. Confirm Intel ME was NOT disabled in firmware (dead ME ="
    echo "       dead audio on this platform)."
    echo "  5. Reboot, then test:  speaker-test -c2  and check 'wpctl status'."
    ;;
  arch|fedora|opensuse*|pop|ubuntu|debian|linuxmint|endeavouros|manjaro)
    echo "Supported-distro path: fetching the Chrultrabook audio setup."
    tmp=$(mktemp -d)
    if git clone --depth 1 https://github.com/WeirdTreeThing/chromebook-linux-audio "$tmp/audio"; then
      ( cd "$tmp/audio" && ./setup-audio )
      echo "Audio setup finished. Reboot, then test speakers + headphone jack."
    else
      echo "Clone failed (network?). Re-run this script when online."
    fi
    rm -rf "$tmp"
    ;;
  *)
    echo "Unknown distro '$distro'. The upstream script supports Arch,"
    echo "Fedora, openSUSE Tumbleweed, Pop, Ubuntu/Debian family. For"
    echo "anything else, follow the Gentoo checklist above as the manual"
    echo "equivalent (kernel configs + sof-firmware + UCM + WirePlumber)."
    ;;
esac

echo ""
echo "== Known-issue note =="
echo "USB-C: broken USB-C is documented on TGL/ADL Chrultrabook machines"
echo "with an initramfs/module-order fix; applicability to brox is not"
echo "stated upstream. If a USB-C port misbehaves, check the Chrultrabook"
echo "known-issues page before assuming hardware damage."
echo ""
echo "Done."

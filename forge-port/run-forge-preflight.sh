#!/bin/bash
# Adapter: run gentoo-forge's READ-ONLY layer against the Chromebook from
# a Linux live environment, then hand off to the violator installer.
#
# gentoo-forge's write stages are deliberately locked stubs in the forge
# itself (bootstrap/kernel/finalize exit 2; writes are qualification-
# locked pending its QEMU acceptance tests). This adapter therefore uses
# ONLY the forge's read-only surface — preflight, doctor, plan — and the
# actual write phase stays in violator's gentoo_install.sh, with its own
# confirmation gate. Nothing in this script writes to any disk.
#
# AUTHOR: Ember (Muse) · AUTHORITY: Branden's request 2026-11-22
# EVIDENCE: gentoo-forge repo read 2026-11-22 (README, INSTALLATION-TARGET,
# scripts/00-preflight.sh, forge-install.sh, PR #5 open/unmerged)

set -u
cd "$(dirname "$0")"

FORGE_DIR="${FORGE_DIR:-/tmp/gentoo-forge}"
if [ ! -d "$FORGE_DIR/.git" ]; then
  echo "== Fetching gentoo-forge (read-only use) =="
  git clone --depth 1 https://github.com/softnessasastrength/gentoo-forge "$FORGE_DIR" \
    || { echo "Clone failed — network? The forge checks are advisory; you can skip to the installer."; exit 1; }
fi

echo ""
echo "== gentoo-forge: shell preflight (read-only) =="
bash "$FORGE_DIR/scripts/00-preflight.sh" || echo "(preflight reported a problem — read it before continuing)"

if command -v python3 >/dev/null 2>&1; then
  echo ""
  echo "== gentoo-forge: doctor (read-only) =="
  ( cd "$FORGE_DIR" && bash forge-install.sh doctor ) || echo "(doctor unavailable or unhappy — advisory only)"

  echo ""
  echo "Disks again, for the plan step:"
  lsblk -o NAME,SIZE,TYPE,TRAN,MODEL
  read -r -p "Disk for the forge PLAN (read-only proposal; e.g. sda): /dev/" D
  if [ -n "$D" ] && [ -b "/dev/$D" ]; then
    echo ""
    echo "== gentoo-forge: plan --disk /dev/$D (proposes only; writes nothing) =="
    echo "NOTE: the forge planner allocates only in EXISTING GPT free space and"
    echo "never erases. On this machine there is no free space — ChromeOS owns"
    echo "the disk — so expect the plan to say so. That refusal is the forge"
    echo "being itself; the erase decision lives in the violator installer."
    ( cd "$FORGE_DIR" && bash forge-install.sh plan --disk "/dev/$D" ) || echo "(plan declined or failed — expected on a ChromeOS-owned disk)"
  fi
else
  echo ""
  echo "(python3 not in this live environment — skipped doctor/plan; the"
  echo " shell preflight above is the forge's core read-only check anyway.)"
fi

echo ""
echo "== Handoff =="
echo "Forge checks done. The write phase is violator's, deliberately:"
echo "  bash ../gentoo_install.sh"
echo "It re-verifies the target disk itself and requires typing VIOLATE."

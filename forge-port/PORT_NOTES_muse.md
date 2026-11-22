# Port Notes — gentoo-forge → violator (brox)

- **AUTHOR** Ember (Muse)
- **AUTHORITY** Branden's instruction, 2026-11-22: "the work we did to the regular Gentoo installer — can we port that over?"
- **EVIDENCE** gentoo-forge read directly from GitHub, 2026-11-22: README, docs/INSTALLATION-TARGET.md, config/hardware.env.example, forge-install.sh, scripts/00–60, open PR #5. Plus the 2026-11-14 survey notes (gentoo-forge = canonical/active Gentoo line; PR #5 reviewed, not merged, merges reserved to Branden).
- **REQUESTED_ACTION** none — port delivered into violator; gentoo-forge itself untouched.

## What gentoo-forge actually is today (sourced, not assumed)

A safety-first Gentoo installer for the desktop (Ryzen 5 4500 / RX 6600 XT), with a Python installer package, a FORGEWORTH TUI, the butler companion, handbook traceability, and a large test suite. Its **read-only layer is real**: preflight, `doctor`, and a partition `plan` that inspects identity/ancestry and proposes allocations **only in existing GPT free space**.

Its **write layer does not exist yet, on purpose**: `scripts/20-bootstrap.sh`, `40-kernel.sh`, and `60-finalize.sh` are stubs that exit 2. docs/INSTALLATION-TARGET.md lists the acceptance tests required before writes unlock (Stage3 signature verification, OVMF boot of the installed kernel, hibernate/resume exercise, snapshot rollback drills, interrupted-stage recovery) and states plainly: *"All of these are pending. Bootstrap through finalization therefore remain locked."* PR #5 carries the boot-stack work; it is open, and the repo reserves merges to Branden.

## What ported over

1. **`hardware-brox.env`** — the forge's own `hardware.env` format, retargeted: `alderlake` march (Raptor Lake's GCC name), Intel GPU, swap cut 20 GiB → 8 GiB (8 GiB RAM, 128 GiB disk, and no hibernation promise worth making on coreboot), hostname `violator`. Filesystem kept at the forge's btrfs default, with the divergence from the violator installer's ext4 flagged in the file.
2. **`run-forge-preflight.sh`** — an adapter that clones the forge in the live environment and runs only its read-only surface (shell preflight, `doctor`, `plan`) against the Chromebook before any write is contemplated.

## The doctrine collision (stated, not smuggled)

The forge **never erases a disk** — free-space allocation only, writes qualification-locked. The Chromebook install **must** erase ChromeOS and **does** write. Those cannot both be true of one code path, so the port keeps them as two paths with a fence between them:

- Forge layer: inspects, checks, proposes. On a ChromeOS-owned disk its planner will refuse for lack of free space — that refusal is correct behaviour, and the adapter says so out loud.
- Violator layer (`gentoo_install.sh`): owns the erase decision, behind its own disk-identity checks and the typed VIOLATE confirmation.

## What did NOT port, and why

- The FORGEWORTH TUI and butler: they're the forge's inspection/conversation surface for the desktop qualification programme; bolting them onto a one-shot Chromebook install adds a Python/Textual runtime to the live environment for no install benefit. Available in the forge checkout if wanted.
- The forge's staged write scripts: there is nothing to port — they are locked stubs. When the forge's acceptance tests pass and its write path lands (PR #5 and successors, merged by Branden), the natural endgame is the forge itself gaining a brox target profile, at which point violator's hand-rolled installer should retire in its favour.

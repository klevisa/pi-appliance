# Installer Requirements

Status: draft v1 scope · Owner: this repository · Canonical concept page: `../project_planning_notes/Raspberry Pi Personal Server Appliance.md`

## 1. Purpose

The installer converts a blank or foreign storage device into a bootable appliance installation. It is the `install` branch of the SD-first boot state machine:

```text
Bootstrap (SD, always boots first)
    ├─ rescue requested          → rescue environment
    ├─ valid appliance marker    → hand off to appliance (NVMe)
    └─ no valid marker           → installer (this document)
```

The installer runs from the SD environment, acts only on the selected target device, writes the appliance marker, and reboots into the appliance. The SD card is permanent bootstrap media and is never removed as part of installation.

## 2. Scope

**In scope for v1:**

- Raspberry Pi 5 test bed with one NVMe target.
- Repeatable erase → install → configure → validate → reboot cycle driven by the administrator over SSH.

**Deferred (see §8):** owner onboarding UX, application catalog, management service, remote-access setup, A/B updates, automated rollback.

## 3. Definitions

| Term | Meaning |
|---|---|
| Bootstrap | The always-booted SD environment; runs mode selection. |
| Target | The storage device the installer will erase and populate (v1: NVMe). |
| Marker | `/etc/pi-appliance/release` on the installed root filesystem; its presence and validity make the bootstrap select `appliance` mode. |
| Operator | The authenticated administrator driving installation (v1: `klevis` over SSH). |

## 4. Functional requirements

- **FR-1 Mode entry.** The installer runs only when `appliancectl select-mode` returns `install`. It must not run when `appliance` or `rescue` is selected.
- **FR-2 Storage discovery.** Enumerate candidate target devices (v1: NVMe; design must extend to USB storage). For each: model, capacity, existing partition layout. Discovery is strictly read-only.
- **FR-3 Target selection.** The operator explicitly selects the target. A device that is unrecognized or not in the supported set is displayed and requires confirmation; it is never selected implicitly.
- **FR-4 Erase confirmation.** Destructive action requires an explicit, operator-confirmed step that names the exact device (model + capacity + device node). Without confirmation the installer performs no writes. This is testable: an unconfirmed run must leave the target byte-identical.
- **FR-5 Partitioning.** Apply a deterministic partition layout to the target. v1 layout: firmware/boot partition + root filesystem. The layout must be defined in one place in the repository so later revisions (e.g. a separate data partition) are a single change.
- **FR-6 OS installation.** Populate the target root filesystem with a supported Raspberry Pi OS base. The image source must be declared (bundled artifact or downloaded URL) and checksum-verified before use. A checksum mismatch aborts installation before any target write.
- **FR-7 System configuration.** Configure on the installed system: hostname, administrator user, key-only SSH (public key material only; password authentication disabled), DHCP networking. The configured key is supplied by the operator at install time; the installer never embeds a fixed key of its own.
- **FR-8 Marker.** Write the appliance release identity to the marker file. The value must match a version known to the repository (not an arbitrary string).
- **FR-9 Validation.** Before declaring success, verify on the target: partition table, filesystems mountable, boot files present, marker present and valid, SSH configuration effective. Any failed check means the installer reports failure and does not signal readiness.
- **FR-10 Completion and handoff.** On success, report completion and reboot. The next boot must select `appliance` mode. The SD card remains installed.
- **FR-11 Repeatability.** Running the installer against an already-installed or partially installed target must succeed (erase-then-install is the defined recovery path). Two consecutive full runs must both succeed.
- **FR-12 SD isolation.** The installer must never write to the boot media it is running from. A test must assert this boundary.
- **FR-13 Distinct host identity.** The installed appliance generates and keeps its own SSH host keys. The installer must not copy the bootstrap environment's host keys, and documentation must state how the operator trusts the new identity (separate known-hosts file until a stable device identity exists).

## 5. Safety requirements

- **SR-1** No erase, partition, or format without FR-4 confirmation. Applies equally when the target looks empty.
- **SR-2** No private keys, PINs, tokens, or credentials in installer code, configuration, logs, or the target image. Only public key material crosses this boundary.
- **SR-3** The target device is re-identified immediately before the destructive step (device nodes can shift between discovery and execution); a mismatch aborts.
- **SR-4** All privileged operations are explicit, logged, and attributable to a repository-committed code path. No undocumented imperative state.
- **SR-5** Installation logs are free of secret material by construction (nothing secret is ever provided to the installer).

## 6. Non-functional requirements

- **NFR-1 Testability without hardware.** Installer logic (selection, confirmation, validation, marker logic) must run against fixture mount points in automated tests; only the thin device layer touches real hardware.
- **NFR-2 Offline capability.** With a bundled, checksummed base image, installation completes without internet access. If downloading instead, network loss produces a clear failure before any target write.
- **NFR-3 Progress and bounded runtime.** Long steps report progress; the full install completes in a bounded, stated time budget on the test bed.
- **NFR-4 Reproducibility.** An installation is reproducible from the repository: same inputs (image, configuration, release) → same result. No state is created outside the documented path.

## 7. Non-goals for v1

- Application installation (Immich, etc.) and the app catalog.
- Appliance management service, Docker/runtime decisions.
- Remote-access configuration (tunnels, VPN, DNS).
- First-owner onboarding experience and physical-presence enrollment UX.
- A/B slot updates, failed-boot counters, automatic rollback.
- Support for devices beyond the Pi 5 + NVMe test bed.

## 8. Future requirements (post-v1, from the canonical concept page)

- First-owner enrollment during install: establish the administrator with physical presence; explore YubiKey enrollment modes; define recovery and key replacement.
- Storage-layout options, including a separate data partition that survives reinstall.
- Failure-policy integration with the bootstrap: failed-boot counter, automatic rescue after repeated failures.
- Signed release artifacts consumed instead of repository checkouts (per repository AGENTS.md, production prefers pinned checksummed artifacts over a moving branch).
- Documented hardware/storage compatibility range.

## 9. Acceptance criteria (v1 complete when)

1. On the Pi 5 test bed, a single operator flow erases the NVMe, installs, and reboots; the bootstrap then selects `appliance` mode.
2. The installed appliance is reachable over SSH with the operator's FIDO2/YubiKey key, password authentication disabled.
3. The marker contains a repository-known release version, and validation (FR-9) passed before the reboot.
4. Two consecutive installations against the same target both succeed (FR-11).
5. Automated tests cover FR-1, FR-3, FR-4, FR-9, FR-11, and FR-12 against fixture mounts and pass in CI-style local runs (`tests/run.sh`).
6. `git diff --check` is clean and no secret material appears anywhere in the repository (SR-2).

## 10. Open questions

1. **Image source mechanism:** download the official Raspberry Pi OS image at install time, bundle a pinned image in the release, or `dd`-clone the running SD rootfs. Decision affects FR-6 and NFR-2.
2. **Data separation:** when to introduce a persistent data partition and what it must survive.
3. **Validation depth:** whether "bootable" is proven by structural checks only (FR-9) or by an actual boot attempt with a failure counter before install success is declared.
4. **Appliance naming:** hostname strategy for the installed appliance vs. the bootstrap environment, and its effect on mDNS/DNS and known-hosts handling.
5. **Operator channel for the product:** v1 assumes SSH-driven operation; the product experience (local console, browser onboarding) is deferred with §8.

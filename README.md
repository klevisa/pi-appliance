# Pi Appliance

A Raspberry Pi 5 appliance that always boots from an SD-card bootstrap, then either starts an installed NVMe appliance, enters first-time installation, or runs rescue mode.

## Current milestone

Build a reproducible development SD card with:

- Raspberry Pi OS Lite 64-bit
- Ethernet DHCP
- key-only SSH for the development administrator
- a stable bootstrap/recovery environment
- repository-driven updates rather than frequent SD-card reflashing

The SD card is persistent appliance bootstrap media. The NVMe is the disposable installation target during development.

## Repository layout

- `bootstrap/` — SD-first boot selection and early startup
- `installer/` — fresh NVMe installation
- `recovery/` — diagnostics and repair
- `appliance/` — software installed onto NVMe
- `image/` — reproducible image inputs
- `scripts/` — development and card-staging commands
- `tests/` — automated behavior checks
- `docs/` — architecture and runbooks
- `release/` — versioned release manifests and artifacts

## Security boundary

Private keys and credentials never enter this repository or an image. Development images receive only an explicitly selected SSH public key at staging time.

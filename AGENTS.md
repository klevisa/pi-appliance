# Repository instructions

This repository owns the Raspberry Pi personal-server appliance implementation. Keep architecture, image-building, installation, recovery, tests, and release procedures reproducible here.

Canonical cross-project product requirements live in:

`../project_planning_notes/Raspberry Pi Personal Server Appliance.md`

Rules:

- Use tests before implementation for executable behavior.
- Never commit private keys, passwords, tokens, generated user-specific cloud-init files, or disk images.
- Treat the SD card as persistent bootstrap/recovery media and NVMe as the appliance target.
- Require explicit confirmation before erasing storage.
- Prefer pinned, checksummed release artifacts over executing a moving Git branch in production.

#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

"$repo_root/scripts/install-development-bootstrap.sh" --root "$work/root"

[[ -x "$work/root/usr/local/sbin/appliancectl" ]]
[[ -f "$work/root/etc/systemd/system/pi-appliance-bootstrap.service" ]]
[[ -d "$work/root/var/lib/pi-appliance" ]]
grep -Fq 'ExecStart=/usr/local/sbin/pi-appliance-boot-check' \
  "$work/root/etc/systemd/system/pi-appliance-bootstrap.service"
grep -Fq 'systemctl enable --now pi-appliance-bootstrap.service' \
  "$repo_root/scripts/install-development-bootstrap.sh"

printf 'development-bootstrap install test passed\n'

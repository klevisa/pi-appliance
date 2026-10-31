#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root=/

if [[ ${1:-} == "--root" ]]; then
  root=${2:-}
  [[ -n "$root" ]] || { echo 'missing --root value' >&2; exit 64; }
elif [[ $# -ne 0 ]]; then
  echo "usage: $0 [--root DIR]" >&2
  exit 64
fi

install -d "$root/usr/local/sbin" "$root/etc/systemd/system" "$root/var/lib/pi-appliance"
install -m 0755 "$repo_root/bootstrap/appliancectl" "$root/usr/local/sbin/appliancectl"
install -m 0755 "$repo_root/bootstrap/pi-appliance-boot-check" "$root/usr/local/sbin/pi-appliance-boot-check"
install -m 0644 "$repo_root/bootstrap/pi-appliance-bootstrap.service" \
  "$root/etc/systemd/system/pi-appliance-bootstrap.service"

if [[ "$root" == / ]]; then
  systemctl daemon-reload
  systemctl enable pi-appliance-bootstrap.service
fi

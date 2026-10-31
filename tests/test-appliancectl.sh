#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/sd" "$work/nvme"

actual=$("$repo_root/bootstrap/appliancectl" select-mode \
  --state-dir "$work/sd" \
  --nvme-root "$work/nvme")

[[ "$actual" == "install" ]] || {
  echo "expected install, got: $actual" >&2
  exit 1
}

printf 'fresh-device mode test passed\n'

mkdir -p "$work/nvme/etc/pi-appliance"
printf '0.1.0\n' > "$work/nvme/etc/pi-appliance/release"
actual=$("$repo_root/bootstrap/appliancectl" select-mode \
  --state-dir "$work/sd" \
  --nvme-root "$work/nvme")

[[ "$actual" == "appliance" ]] || {
  echo "expected appliance, got: $actual" >&2
  exit 1
}

printf 'installed-device mode test passed\n'

touch "$work/sd/force-rescue"
actual=$("$repo_root/bootstrap/appliancectl" select-mode \
  --state-dir "$work/sd" \
  --nvme-root "$work/nvme")

[[ "$actual" == "rescue" ]] || {
  echo "expected rescue, got: $actual" >&2
  exit 1
}

printf 'manual-rescue mode test passed\n'

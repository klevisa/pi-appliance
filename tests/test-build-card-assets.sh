#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/key.pub" <<'KEY'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestOnlyKey appliance-test
KEY

"$repo_root/scripts/build-card-assets.sh" "$work/key.pub" "$work/output"

[[ -f "$work/output/user-data" ]] || { echo 'missing user-data' >&2; exit 1; }
[[ -f "$work/output/network-config" ]] || { echo 'missing network-config' >&2; exit 1; }
[[ -f "$work/output/meta-data" ]] || { echo 'missing meta-data' >&2; exit 1; }
[[ -f "$work/output/ssh" ]] || { echo 'missing ssh marker' >&2; exit 1; }
[[ ! -s "$work/output/ssh" ]] || { echo 'ssh marker is not empty' >&2; exit 1; }
[[ -f "$work/output/pi-appliance-source.tar.gz" ]] || { echo 'missing source bundle' >&2; exit 1; }
grep -Fq 'appliance-test' "$work/output/user-data"
grep -Fq 'dhcp4: true' "$work/output/network-config"
grep -Fxq 'instance_id: pi-appliance-bootstrap-v2' "$work/output/meta-data"
tar -tzf "$work/output/pi-appliance-source.tar.gz" | grep -Fxq 'pi-appliance/bootstrap/appliancectl'
if tar -tzf "$work/output/pi-appliance-source.tar.gz" | grep -Fq '/.git/'; then
  echo 'source bundle contains .git metadata' >&2
  exit 1
fi

printf 'card asset build test passed\n'

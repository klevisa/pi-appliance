#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cat > "$work/key.pub" <<'KEY'
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tITestOnlyKey appliance-test
KEY

"$repo_root/scripts/render-user-data.sh" \
  "$repo_root/image/user-data.yaml.in" \
  "$work/key.pub" \
  "$work/user-data"

grep -Fxq 'hostname: pilab-bootstrap' "$work/user-data"
grep -Fxq 'ssh_pwauth: false' "$work/user-data"
grep -Fxq '  - openssh-server' "$work/user-data"
grep -Fq 'https://github.com/klevisa/pi-appliance.git' "$work/user-data"
grep -Fq 'git -C /opt/pi-appliance fetch origin main' "$work/user-data"
grep -Fq 'sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tITestOnlyKey appliance-test' "$work/user-data"
if grep -Fq '__SSH_PUBLIC_KEY__' "$work/user-data"; then
  echo 'placeholder remained in rendered user-data' >&2
  exit 1
fi

printf 'render-user-data test passed\n'

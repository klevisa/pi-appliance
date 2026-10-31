#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 PUBLIC_KEY OUTPUT_DIR" >&2
  exit 64
fi

public_key=$1
output_dir=$2
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_parent="$(dirname "$repo_root")"
repo_name="$(basename "$repo_root")"

mkdir -p "$output_dir"
"$repo_root/scripts/render-user-data.sh" \
  "$repo_root/image/user-data.yaml.in" \
  "$public_key" \
  "$output_dir/user-data"
cp "$repo_root/image/network-config" "$output_dir/network-config"
cp "$repo_root/image/meta-data" "$output_dir/meta-data"
: > "$output_dir/ssh"

COPYFILE_DISABLE=1 tar -czf "$output_dir/pi-appliance-source.tar.gz" \
  --exclude="$repo_name/.git" \
  --exclude="$repo_name/image/generated" \
  --exclude="$repo_name/release/generated" \
  --exclude='*/.DS_Store' \
  -C "$repo_parent" "$repo_name"

shasum -a 256 \
  "$output_dir/user-data" \
  "$output_dir/network-config" \
  "$output_dir/meta-data" \
  "$output_dir/ssh" \
  "$output_dir/pi-appliance-source.tar.gz" \
  > "$output_dir/SHA256SUMS"

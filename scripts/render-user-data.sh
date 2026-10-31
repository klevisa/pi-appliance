#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: $0 TEMPLATE PUBLIC_KEY OUTPUT" >&2
  exit 64
fi

template=$1
public_key_file=$2
output=$3

[[ -f "$template" ]] || { echo "template not found: $template" >&2; exit 66; }
[[ -f "$public_key_file" ]] || { echo "public key not found: $public_key_file" >&2; exit 66; }

if grep -q 'PRIVATE KEY' "$public_key_file"; then
  echo "refusing a private key file" >&2
  exit 65
fi

public_key=$(tr -d '\r\n' < "$public_key_file")
case "$public_key" in
  ssh-*|sk-ssh-*) ;;
  *) echo "file does not contain an OpenSSH public key" >&2; exit 65 ;;
esac

python3 - "$template" "$output" "$public_key" <<'PY'
from pathlib import Path
import sys

template_path, output_path, public_key = sys.argv[1:]
text = Path(template_path).read_text()
placeholder = "__SSH_PUBLIC_KEY__"
if text.count(placeholder) != 1:
    raise SystemExit("template must contain exactly one SSH public-key placeholder")
Path(output_path).write_text(text.replace(placeholder, public_key))
PY
chmod 600 "$output"

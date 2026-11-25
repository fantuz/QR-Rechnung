#!/bin/bash
set -e
script_dir="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
exec python3 -X utf8 "$script_dir/postfinance_qrbill.py" "$@"\n
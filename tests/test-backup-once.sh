#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
dir="$(mktemp -d)"
trap 'rm -rf "$dir"' EXIT

cat > "$dir/idrive-ok" <<'SH'
#!/usr/bin/env bash
[[ "$1" == "--backup" && "$2" == "--silent" ]]
SH
chmod +x "$dir/idrive-ok"
IDRIVE_BIN="$dir/idrive-ok" IDRIVE_LOCK_FILE="$dir/lock" \
  bash scripts/fhad-backup-once.sh > "$dir/stdout"
grep -q 'No files will be deleted' "$dir/stdout"

cat > "$dir/idrive-fail" <<'SH'
#!/usr/bin/env bash
exit 8
SH
chmod +x "$dir/idrive-fail"
if IDRIVE_BIN="$dir/idrive-fail" IDRIVE_LOCK_FILE="$dir/lock" \
     bash scripts/fhad-backup-once.sh > "$dir/stderr" 2>&1; then
  echo "ERROR: failed backup should return non-zero" >&2
  exit 1
fi
grep -q 'No files will be deleted' "$dir/stderr"
echo "PASS: success/failure paths never delete local files"

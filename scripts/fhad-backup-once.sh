#!/usr/bin/env bash
set -Eeuo pipefail

idrive_bin="${IDRIVE_BIN:-/opt/IDriveForLinux/bin/idrive}"
lock_file="${IDRIVE_LOCK_FILE:-/run/fhad-idrive-backup.lock}"
exec 9>"$lock_file"
if ! flock -n 9; then
  echo "[FHAD] Previous backup CLI invocation still running; skipping trigger."
  exit 0
fi

echo "[FHAD] $(date -u +%Y-%m-%dT%H:%M:%SZ) Starting IDrive backup CLI."
if "$idrive_bin" --backup --silent; then
  echo "[FHAD] $(date -u +%Y-%m-%dT%H:%M:%SZ) CLI returned zero."
  echo "[FHAD] A zero exit code is NOT proof every file reached the cloud. No files will be deleted."
else
  status=$?
  echo "[FHAD] Backup CLI failed with exit code $status. No files will be deleted." >&2
  exit "$status"
fi

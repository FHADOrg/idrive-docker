#!/usr/bin/env bash
set -Eeuo pipefail
enabled="${IDRIVE_SCHEDULER_ENABLED:-false}"
interval="${IDRIVE_BACKUP_INTERVAL_SECONDS:-300}"

if [[ "$enabled" != "true" ]]; then
  echo "[FHAD] Scheduler disabled; enable only after a manual backup and restore test."
  exec sleep infinity
fi

if [[ ! "$interval" =~ ^[0-9]+$ ]] || (( interval < 60 )); then
  echo "[FHAD] Invalid IDRIVE_BACKUP_INTERVAL_SECONDS: $interval (minimum 60)" >&2
  exit 2
fi

echo "[FHAD] Scheduler active: backup trigger every ${interval}s; local deletion is NOT implemented."
# Initial delay lets administrators complete first-time IDrive login and source selection.
sleep "$interval"
while true; do
  started="$(date +%s)"
  if ! /usr/local/bin/fhad-backup-once; then
    echo "[FHAD] Backup command failed. Originals remain untouched." >&2
  fi
  elapsed="$(( $(date +%s) - started ))"
  if (( elapsed < interval )); then
    sleep "$(( interval - elapsed ))"
  else
    # A long-running backup delays the next trigger; never start another in parallel.
    sleep 1
  fi
done

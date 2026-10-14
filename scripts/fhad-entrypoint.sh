#!/usr/bin/env bash
set -Eeuo pipefail

# The upstream /start.sh starts the IDrive cron/agent.
# FHAD's scheduler is a separate process in the SAME container/profile.
daemon_pid=""
scheduler_pid=""
shutdown() {
  trap - EXIT TERM INT
  [[ -z "$scheduler_pid" ]] || kill "$scheduler_pid" 2>/dev/null || true
  [[ -z "$daemon_pid" ]] || kill "$daemon_pid" 2>/dev/null || true
  [[ -z "$scheduler_pid" ]] || wait "$scheduler_pid" 2>/dev/null || true
  [[ -z "$daemon_pid" ]] || wait "$daemon_pid" 2>/dev/null || true
}
trap shutdown EXIT TERM INT

/start.sh &
daemon_pid="$!"
/usr/local/bin/fhad-scheduler &
scheduler_pid="$!"

# Recreate container if either the IDrive agent or the scheduler exits.
wait -n "$daemon_pid" "$scheduler_pid"

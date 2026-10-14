# ADR-0001 — IDrive Online Backup, scheduler and fail-closed cleanup

- Status: Accepted for MVP scheduling; file deletion NOT approved.
- Date: 2026-10-14
- Source: user-confirmed IDrive Online Backup account with 10 TB; upstream snorre-k/idrive-docker.

## Decision
1. Use IDrive **Online Backup**, not IDrive e2/S3 or rclone.
2. Keep the upstream client version **3.8.0** pinned pending compatibility validation (upstream issue #26).
3. Run a single FHAD-derived container on a pinned Swarm node, with named-volume IDrive state and read-only source mounts.
4. Run an internal 300-second trigger that calls the official `idrive --backup --silent` CLI.
5. Scheduler is OFF by default until account setup, backup, logs and restore have been tested.
6. DO NOT delete local files in MVP. A CLI exit status, global 'Success', or one completed job is not proof of per-file storage.
7. Disable IDrive Archive Cleanup and Periodic Cleanup. The cloud must retain uploaded files after source deletion.
8. Preserve all material decisions, deployment and tests in this repository in the same change.

## Constraints and risks
- The IDrive client may return from its CLI while a remote job is still active. The shell lock only prevents **overlapping CLI invocations**. Verify the client job lifecycle before enabling a five-minute production schedule.
- IDrive reports success in some cases while permission-denied files exist: all deletion must be gated by file-level proof.
- Docker's local named volume is node-local. The service must remain on the same node or use suitable shared persistent storage.
- Docker image building is separate from `docker stack deploy`. GHCR package access may need configuration.
- The inherited upstream build/publish workflows must not attempt to publish to the upstream author's registries.

## Deferred decision (requires implementation and test)
Choose a defensible file-by-file remote verification method, include file fingerprinting and restore checks, and only then consider opt-in cleanup. See [cleanup spec](../specs/safe-source-deletion.md).

## References
- https://github.com/snorre-k/idrive-docker/issues/26
- https://www.idrive.com/linux-scripts
- https://www.idrive.com/faq_linux

# FHAD IDrive Docker

FHAD customization of [snorre-k/idrive-docker](https://github.com/snorre-k/idrive-docker) for **IDrive Online Backup** (not IDrive e2/S3), running in **Docker Swarm**.

**Current scope (0.1.0):** a 300-second configurable backup CLI trigger, disabled by default; persistent IDrive profile; read-only local source; basic CI smoke tests. **No automatic local file deletion.**

> **SAFETY:** The IDrive global backup success/CLI exit code cannot be used as per-file upload proof. Source deletion is **not implemented or authorized**. Never enable IDrive Archive Cleanup/Periodic Cleanup if remote copies must be retained after local removal.

## Start here
- [Swarm deployment and first login](docs/deployment-swarm.md)
- [ADR-0001 architecture and decisions](docs/adr/0001-idrive-online-first-and-fail-closed.md)
- [Safe source deletion spec — deferred](docs/specs/safe-source-deletion.md)
- [Upstream project](https://github.com/snorre-k/idrive-docker) and [upstream client version issue #26](https://github.com/snorre-k/idrive-docker/issues/26)

## Release arrangement
- `Dockerfile.fhad` derives from the upstream **3.8.0** image to avoid the current 3.9+ compatibility warning.
- GitHub workflow `FHAD IDrive image` builds on PRs and publishes `ghcr.io/fhadorg/idrive-docker:0.1.0` on main.
- `deploy/swarm/stack.yml` deploys one replica pinned to a storage node.
- The FHAD scheduler invokes the official `idrive --backup --silent` command every 300 seconds after activation; invocations cannot overlap, but background IDrive job behavior must be validated in staging.
- An IDrive state named volume preserves login/configuration. Source is mapped `:ro`.
- Original upstream Dockerfile and compose examples remain in the fork for reference but should not be used for FHAD Swarm deployment.

## Operator safety checklist
1. Publish/test FHAD image; confirm compatibility of pinned client.
2. Deploy with scheduler disabled, log in interactively and configure `/source`.
3. Disable native schedules, Archive Cleanup and Periodic Cleanup.
4. Perform a manual backup and test restoration, checking file hashes and logs.
5. Verify asynchronous job behavior, then enable the scheduler.
6. Never delete local files before a future, independently validated per-file cleanup design.

All meaningful decisions and system changes must be recorded in versioned repository documentation in the same change cycle. This repository is the source of truth.

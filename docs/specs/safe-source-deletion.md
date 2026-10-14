# Safe source deletion — specification (NOT implemented)

## Goal
Move-like behavior with IDrive Online Backup: every 5 minutes upload eligible stable files; delete only originals proven recoverable from IDrive.

## Non-negotiable invariants
- Local source mounted `:ro` in the IDrive container. An independent, narrowly-scoped cleanup agent would be required later.
- No file deletion on backup CLI return code, job success, log summary, file-count coincidence or inferred cloud availability alone.
- Per-file proof of a remote object/version and a successful restore/integrity check is required, using a documented, testable IDrive interface. If IDrive provides no reliable per-file verification interface, DO NOT automate deletion.
- Verify size and cryptographic digest (SHA-256) against a restored copy before deletion, or an equivalent independently verified integrity protocol.
- Before any deletion, re-stat and hash the current local file, matching the immutable manifest fingerprint and ensuring it is not still being written.
- Preserve relative paths, account backup-location identity and recovery metadata in a durable manifest.
- Atomic state transitions: discovered -> stable -> backup_requested -> remote_verified -> eligible_for_cleanup -> cleaned.
- Fail closed on timeouts, permission errors, unreadable logs, changed files, ambiguity, and storage quota errors.
- Prevent Archive Cleanup and Periodic Cleanup from purging cloud-only files.
- Manual operator switch is required to enable deletions after integration and restore testing.
- Record audit entries (file, digest, remote verification, deletion time, job id) without credentials.

## Acceptance scenarios
1. A stable small text file can be uploaded, independently restored, SHA-256 compared, and (only with opt-in) deleted.
2. A file modified during backup remains local.
3. An upload with permission denied, network loss, interrupted backup, or remote mismatch remains local.
4. Two overlapping scheduler triggers never delete a file.
5. Cloud-only files remain available after source deletion and subsequent backup runs.
6. Local source cleanup does not affect other mounted directories.

**Implementation status:** NOT STARTED. No delete/remove/prune code exists in this release.

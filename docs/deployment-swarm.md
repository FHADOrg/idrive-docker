# FHAD IDrive Online Backup — deployment runbook (MVP, no deletion)

## Prerequisites
- A working IDrive Online Backup account (10 TB plan), no credentials in Git.
- An amd64 Docker Swarm node with access to the backup directory.
- GHCR image `ghcr.io/fhadorg/idrive-docker:0.1.0` successfully published and readable by Swarm nodes.
- If the GHCR package is private, authenticate registry nodes/use a registry auth deployment.
- Validate client compatibility: upstream issue #26 recommends the 3.8.0 version; perform backup AND restore before production.

## 1. Bind service to the storage node
On a Swarm manager (substitute the real node name):
```bash
docker node update --label-add idrive-backup=true <storage-node>
```
On that storage node create the intended source directory:
```bash
sudo mkdir -p /srv/fhad/idrive/source
```
Edit the bind mount in `deploy/swarm/stack.yml` to the **real** absolute source path before deploying. The source is read-only inside the container. Keep the single replica on the same node because the IDrive state volume uses a local driver.

## 2. Deploy with scheduler OFF
```bash
docker stack deploy -c deploy/swarm/stack.yml fhad_idrive
docker service ps fhad_idrive_idrive
```

## 3. Setup account and select source
On the node running the container:
```bash
CID="$(docker ps -q --filter label=com.docker.swarm.service.name=fhad_idrive_idrive)"
test -n "$CID"
docker exec -it "$CID" ./idrive --account-setting
```
In the IDrive backup set, select `/source` (or `/source/1`) as the source. Disable ALL native backup schedules if FHAD scheduler is going to be used. Disable both Archive Cleanup and Periodic Cleanup. These are separate IDrive-side settings.

## 4. Manual validation, no deletion
```bash
docker exec -it "$CID" ./idrive --backup
docker exec -it "$CID" ./idrive --job-status
docker exec -it "$CID" ./idrive --logs
```
Inspect the logs for skipped, denied or failed files. Independently RESTORE known test files and compare their hashes with the originals; ensure the restore path is outside the source directory. Do not infer full success from a global job result. Confirm whether `--backup --silent` remains running until completion and whether `--job-status` indicates background jobs.

## 5. Enable 300-second scheduler only after validation
Edit `deploy/swarm/stack.yml`:
```yaml
IDRIVE_SCHEDULER_ENABLED: "true"
IDRIVE_BACKUP_INTERVAL_SECONDS: "300"
```
Redeploy:
```bash
docker stack deploy -c deploy/swarm/stack.yml fhad_idrive
docker service logs -f fhad_idrive_idrive
```
The FHAD scheduler starts after a 300s initial delay and allows one active CLI invocation at a time. If the IDrive backend launches an asynchronous job, additional job-status handling may be necessary before the scheduler should be left on in production.

## 6. Rollback
Set `IDRIVE_SCHEDULER_ENABLED: "false"` and redeploy. This stops future FHAD backup triggers without erasing the IDrive state volume. This MVP cannot delete any local files.

## Security/operational notes
- Never commit usernames, passwords or exported IDrive sessions.
- Keep credentials in IDrive's persistent configuration volume; restrict host access.
- The tag `:0.1.0` is FHAD's wrapper release, not the upstream IDrive client version.
- No auto-update to the upstream `:latest` tag. Pin and test updates.
- Native cleanup can remove data **from the cloud**; it is not the local cleanup feature requested.

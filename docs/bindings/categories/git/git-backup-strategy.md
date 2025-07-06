---
id: git-backup-strategy
last_modified: '2025-06-24'
version: '0.1.0'
derived_from: git-reliability-engineering
enforced_by: 'backup automation, replication strategies, disaster recovery drills, monitoring systems'
---

# Binding: Implement Comprehensive Git Backup Strategies

Treat Git repositories as critical data requiring multiple backup strategies, geographic distribution, and regular recovery testing. Design backup systems that can handle repository corruption, server failure, and even complete infrastructure loss.

## Rationale

Git's distributed nature provides inherent redundancy, but relying on developer laptops as backup strategy is like assuming RAID replaces backups—dangerous misconception leading to data loss.

Professional Git backup strategies must account for multiple failure modes: repository corruption, malicious force pushes, infrastructure failures, ransomware. Each requires different approaches: point-in-time snapshots, geographic replication, immutable storage.

## Rule Definition

Comprehensive Git backup strategies must include:

- **Multi-Layer Backup Architecture**: Implement backups at repository, server, and infrastructure levels with different retention policies.

- **Geographic Distribution**: Maintain repository copies across multiple geographic regions to survive regional failures.

- **Point-in-Time Recovery**: Enable restoration to any point in history, not just the current state, to recover from logical corruption.

- **Automated Verification**: Regularly test backup integrity and practice recovery procedures to ensure backups actually work.

- **Immutable Backup Storage**: Protect against ransomware and malicious actors by using write-once storage for critical backups.

**Backup Requirements**:
- Continuous replication to secondary servers
- Daily snapshots with 30-day retention
- Weekly archives with 1-year retention
- Geographic distribution across 3+ regions
- Automated backup verification
- Documented recovery procedures
- Regular disaster recovery drills

**Recovery Objectives**:
- RPO (Recovery Point Objective): < 1 hour
- RTO (Recovery Time Objective): < 4 hours
- Corruption detection time: < 30 minutes

## Practical Implementation

1. **Continuous Replication**:
   ```bash
   #!/bin/bash
   # Post-receive hook: replicate to multiple regions
   git push --mirror git@backup-us.company.com:${PWD##*/} &
   git push --mirror git@backup-eu.company.com:${PWD##*/} &
   git push --mirror git@backup-asia.company.com:${PWD##*/} &
   wait
   echo "$(date): Replicated ${PWD##*/}" >> /var/log/git-replication.log
   ```

2. **Point-in-Time Snapshots**:
   ```yaml
   apiVersion: batch/v1
   kind: CronJob
   metadata: {name: git-snapshot-backup}
   spec:
     schedule: "0 */6 * * *"  # Every 6 hours
     jobTemplate:
       spec:
         template:
           spec:
             containers:
             - name: backup
               image: git-backup:latest
               command: ["/bin/bash", "-c", "|
                 SNAPSHOT=git-$(date +%Y%m%d-%H%M%S)
                 aws ec2 create-snapshot --volume-id vol-xxx --description \"$SNAPSHOT\"
                 for repo in /git/*; do git clone --mirror $repo /backup/$SNAPSHOT/$(basename $repo); done
                 aws s3 sync /backup/$SNAPSHOT/ s3://git-backups/$SNAPSHOT/ --storage-class GLACIER"]
   ```

3. **Backup Verification**:
   ```python
   import subprocess, tempfile, logging

   def verify_backup(backup_location, repo_name):
       with tempfile.TemporaryDirectory() as tmpdir:
           try:
               subprocess.run(['git', 'clone', '--mirror', f'{backup_location}/{repo_name}', f'{tmpdir}/{repo_name}'], check=True)
               subprocess.run(['git', '-C', f'{tmpdir}/{repo_name}', 'fsck', '--full'], check=True)
               subprocess.run(['git', '-C', f'{tmpdir}/{repo_name}', 'rev-list', '--all', '--objects'], check=True, capture_output=True)
               logging.info(f"✓ Backup verified: {repo_name}")
               return True
           except subprocess.CalledProcessError as e:
               logging.error(f"✗ Backup corrupted: {repo_name}")
               alert_oncall(f"Git backup corruption: {repo_name}")
               return False
   ```

4. **Disaster Recovery**:
   ```bash
   #!/bin/bash
   # disaster-recovery.sh
   set -euo pipefail
   RECOVERY_SOURCE=${1:-"s3://git-backups/latest"}
   RECOVERY_TARGET=${2:-"/git"}

   echo "Starting recovery from ${RECOVERY_SOURCE}"
   aws s3 sync ${RECOVERY_SOURCE}/ ${RECOVERY_TARGET}/ --delete

   # Verify all repositories
   for repo in ${RECOVERY_TARGET}/*.git; do
       git -C "${repo}" fsck --full --strict || echo "ERROR: ${repo} corrupted"
   done

   chown -R git:git ${RECOVERY_TARGET}
   systemctl restart git-daemon gitlab
   echo "Recovery complete"
   ```

5. **Monitor Backup Health**:
   ```yaml
   groups:
   - name: git_backup_alerts
     rules:
     - alert: GitBackupFailed
       expr: git_backup_last_success_timestamp < time() - 7200
       annotations: {summary: "Git backup failed (>2h)"}
     - alert: GitBackupStorageFull
       expr: git_backup_storage_used_percent > 90
       annotations: {summary: "Backup storage {{ $value }}% full"}
     - alert: GitBackupVerificationFailed
       expr: git_backup_verification_failures > 0
       annotations: {summary: "Backup verification failed: {{ $value }} repos"}
   ```

## Examples

```bash
# ❌ BAD: Relying on developer clones, no verification
# ✅ GOOD: Multi-region replication + verification
git remote add backup-us git@backup-us.company.com:repo.git
git remote add backup-eu git@backup-eu.company.com:repo.git

# Automated snapshots and archives
0 * * * * /usr/local/bin/git-snapshot-backup.sh
0 2 * * 0 /usr/local/bin/git-archive-to-glacier.sh
```

```yaml
# ❌ BAD: No verification, hope backups work
# ✅ GOOD: Verified multi-tier backup strategy
backups:
  destinations:
    - {type: mirror, location: git@backup1.company.com, verify: true}
    - {type: snapshot, location: s3://git-backups, verify: true, retention: 30d}
    - {type: archive, location: glacier://git-archives, verify: weekly, retention: 365d}
  verification: {integrity_check: true, test_restore: weekly, alert_on_failure: true}
```

## Related Bindings

- [git-monitoring-metrics.md](git-monitoring-metrics.md): Monitor backup success rates and verification results
- [automated-rollback-procedures.md](automated-rollback-procedures.md): Point-in-time recovery enables restoration from corruption
- [distributed-team-workflows.md](distributed-team-workflows.md): Geographic backup distribution for global teams
- [comprehensive-security-automation.md](../../core/comprehensive-security-automation.md): Immutable backups protect against ransomware
- [git-hooks-automation.md](../../core/git-hooks-automation.md): Post-receive hooks trigger backup operations

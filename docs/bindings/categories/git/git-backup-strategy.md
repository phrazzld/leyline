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

This binding implements our Git reliability engineering tenet by applying data durability principles to version control. While Git's distributed nature provides some inherent redundancy, relying on developer laptops as your backup strategy is like assuming RAID replaces backups—it's a dangerous misconception that leads to data loss when systemic failures occur.

Professional backup strategies for Git must account for multiple failure modes: repository corruption that propagates through clones, malicious force pushes that rewrite history, infrastructure failures that take down Git servers, and even ransomware that encrypts repositories. Each failure mode requires different backup approaches, from point-in-time snapshots to geographic replication.

Think of Git backups like database backups—you need multiple strategies at different layers. Just as production databases use continuous replication, point-in-time recovery, and offsite backups, Git infrastructure needs similar protections. The distributed nature of Git is a feature that enhances these strategies, not a replacement for them. When properly implemented, Git backups ensure that no single failure—whether human error, hardware failure, or security breach—can destroy your organization's development history.

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

1. **Implement Continuous Replication**: Set up real-time replication to secondary Git servers:
   ```bash
   # Primary server post-receive hook
   #!/bin/bash
   # /path/to/repo.git/hooks/post-receive

   # Replicate to multiple geographic locations
   git push --mirror git@backup-us-east.company.com:${PWD##*/} &
   git push --mirror git@backup-eu-west.company.com:${PWD##*/} &
   git push --mirror git@backup-ap-south.company.com:${PWD##*/} &

   # Wait for all replications to complete
   wait

   # Log replication status
   echo "$(date): Replicated ${PWD##*/} to all backup locations" >> /var/log/git-replication.log
   ```

2. **Create Point-in-Time Snapshots**: Implement filesystem or storage-level snapshots:
   ```yaml
   # Kubernetes CronJob for Git snapshot backups
   apiVersion: batch/v1
   kind: CronJob
   metadata:
     name: git-snapshot-backup
   spec:
     schedule: "0 */6 * * *"  # Every 6 hours
     jobTemplate:
       spec:
         template:
           spec:
             containers:
             - name: backup
               image: git-backup:latest
               command:
               - /bin/bash
               - -c
               - |
                 # Create point-in-time snapshot
                 SNAPSHOT_NAME="git-$(date +%Y%m%d-%H%M%S)"

                 # Snapshot at storage level
                 aws ec2 create-snapshot \
                   --volume-id vol-1234567890abcdef0 \
                   --description "Git repos snapshot ${SNAPSHOT_NAME}"

                 # Also create logical backup
                 for repo in /git/*; do
                   git clone --mirror $repo /backup/${SNAPSHOT_NAME}/$(basename $repo)
                 done

                 # Upload to immutable storage
                 aws s3 sync /backup/${SNAPSHOT_NAME}/ \
                   s3://git-backups/${SNAPSHOT_NAME}/ \
                   --storage-class GLACIER
   ```

3. **Automate Backup Verification**: Regularly test backup integrity:
   ```python
   # Automated backup verification script
   import subprocess
   import tempfile
   import logging
   from datetime import datetime

   def verify_backup(backup_location, repo_name):
       with tempfile.TemporaryDirectory() as tmpdir:
           try:
               # Clone from backup
               subprocess.run([
                   'git', 'clone', '--mirror',
                   f'{backup_location}/{repo_name}',
                   f'{tmpdir}/{repo_name}'
               ], check=True)

               # Verify repository integrity
               subprocess.run([
                   'git', '-C', f'{tmpdir}/{repo_name}',
                   'fsck', '--full', '--strict'
               ], check=True)

               # Verify we can read all objects
               subprocess.run([
                   'git', '-C', f'{tmpdir}/{repo_name}',
                   'rev-list', '--all', '--objects'
               ], check=True, capture_output=True)

               logging.info(f"✓ Backup verified: {repo_name}")
               return True

           except subprocess.CalledProcessError as e:
               logging.error(f"✗ Backup corrupted: {repo_name} - {e}")
               alert_oncall(f"Git backup corruption detected: {repo_name}")
               return False
   ```

4. **Implement Disaster Recovery Procedures**: Document and automate recovery:
   ```bash
   #!/bin/bash
   # disaster-recovery.sh - Restore Git infrastructure from backups

   set -euo pipefail

   RECOVERY_SOURCE=${1:-"s3://git-backups/latest"}
   RECOVERY_TARGET=${2:-"/git"}

   echo "Starting Git disaster recovery from ${RECOVERY_SOURCE}"

   # Step 1: Restore from immutable backup
   aws s3 sync ${RECOVERY_SOURCE}/ ${RECOVERY_TARGET}/ --delete

   # Step 2: Verify all repositories
   for repo in ${RECOVERY_TARGET}/*.git; do
       echo "Verifying ${repo}..."
       git -C "${repo}" fsck --full --strict || {
           echo "ERROR: ${repo} is corrupted, trying older backup..."
           # Fallback to previous backup
       }
   done

   # Step 3: Update repository permissions
   chown -R git:git ${RECOVERY_TARGET}
   find ${RECOVERY_TARGET} -type d -exec chmod 755 {} \;
   find ${RECOVERY_TARGET} -type f -exec chmod 644 {} \;

   # Step 4: Restart Git services
   systemctl restart git-daemon
   systemctl restart gitlab

   echo "Recovery complete. Please verify service functionality."
   ```

5. **Monitor Backup Health**: Track backup metrics and alert on issues:
   ```yaml
   # Prometheus alerts for Git backup health
   groups:
   - name: git_backup_alerts
     rules:
     - alert: GitBackupFailed
       expr: git_backup_last_success_timestamp < time() - 7200
       for: 10m
       annotations:
         summary: "Git backup has not succeeded in 2 hours"

     - alert: GitBackupStorageFull
       expr: git_backup_storage_used_percent > 90
       for: 5m
       annotations:
         summary: "Git backup storage is {{ $value }}% full"

     - alert: GitBackupVerificationFailed
       expr: git_backup_verification_failures > 0
       for: 1m
       annotations:
         summary: "Git backup verification failed for {{ $value }} repositories"
   ```

## Examples

```bash
# ❌ BAD: Relying on developer clones as backups
# "Don't worry, everyone has a clone of the repo"
# No centralized backup strategy
# No point-in-time recovery
# No verification of backup integrity
# No geographic distribution

# ✅ GOOD: Comprehensive backup strategy
# Continuous replication to 3 geographic regions
git remote add backup-us git@backup-us.company.com:repo.git
git remote add backup-eu git@backup-eu.company.com:repo.git
git remote add backup-asia git@backup-asia.company.com:repo.git

# Automated hourly snapshots
0 * * * * /usr/local/bin/git-snapshot-backup.sh

# Weekly immutable archives
0 2 * * 0 /usr/local/bin/git-archive-to-glacier.sh
```

```yaml
# ❌ BAD: No backup verification
backups:
  schedule: nightly
  destination: /backups
  # Hope the backups work when needed

# ✅ GOOD: Verified backup strategy
backups:
  schedule: hourly
  destinations:
    - type: mirror
      location: git@backup1.company.com
      verify: true
    - type: snapshot
      location: s3://git-backups
      verify: true
      retention: 30d
    - type: archive
      location: glacier://git-archives
      verify: weekly
      retention: 365d

  verification:
    - integrity_check: true
    - test_restore: weekly
    - alert_on_failure: true
```

```bash
# ❌ BAD: Manual, untested recovery
# "If we need to restore, we'll figure it out"
# No documented procedures
# No practice drills
# Unknown recovery time

# ✅ GOOD: Automated, tested recovery
# Documented disaster recovery runbook
cat > DR_RUNBOOK.md << EOF
1. Run: ./disaster-recovery.sh s3://git-backups/latest
2. Verify: ./verify-all-repos.sh
3. Update DNS: git.company.com -> new-git-server
4. Notify teams: ./send-recovery-notification.sh
EOF

# Monthly DR drills
0 0 1 * * /usr/local/bin/dr-drill.sh --notify-team
```

## Related Bindings

- [git-monitoring-metrics.md](git-monitoring-metrics.md): Backup health metrics are critical components of Git observability. Monitor backup success rates, storage usage, and verification results as key reliability indicators.

- [automated-rollback-procedures.md](automated-rollback-procedures.md): Git backups enable rollback capabilities beyond simple reverts. Point-in-time recovery allows restoration from corruption or malicious changes that affect entire repositories.

- [distributed-team-workflows.md](distributed-team-workflows.md): Distributed teams benefit from geographic backup distribution, ensuring low-latency access to repository copies regardless of primary server location.

- [comprehensive-security-automation.md](../../core/comprehensive-security-automation.md): Immutable backups protect against ransomware and insider threats. Security automation should include backup integrity monitoring and access controls.

- [git-hooks-automation.md](../../core/git-hooks-automation.md): Post-receive hooks can trigger backup operations, ensuring every change is immediately replicated to backup locations without manual intervention.
